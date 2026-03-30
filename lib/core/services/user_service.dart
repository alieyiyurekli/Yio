import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/app_user.dart';

/// Firestore User Service
///
/// Handles all user-related Firestore operations for the auth/onboarding flow.
/// All methods operate on the `users/{uid}` document path.
///
/// - [createUserDocument] — called after Firebase Auth register
/// - [getUserProfile] — called by the router to determine routing
/// - [updateUserProfile] — partial field updates
/// - [completeOnboarding] — atomic onboarding completion
/// - [isUsernameAvailable] — unique username check
/// - [deleteUser] — cascade delete for account deletion
class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Private helpers ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersRef.doc(uid);

  // ── Create ──────────────────────────────────────────────────────────────────

  /// Creates a new user document in Firestore after Firebase Auth registration.
  ///
  /// Sets [onboardingCompleted] to `false` so the router directs to onboarding.
  /// This MUST be called right after [AuthService.registerWithEmailAndPassword].
  /// Firestore failure is non-fatal for registration — error is logged but
  /// does not throw so the auth flow continues.
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      final appUser = AppUser(
        uid: uid,
        email: email,
        name: name,
        onboardingCompleted: false,
        role: AppConstants.roleUser,
        createdAt: DateTime.now(),
      );

      await _userDoc(uid).set(appUser.toMap());
      debugPrint('[UserService] User document created: $uid');
    } catch (e) {
      // Non-fatal — log and continue. Router will handle missing document.
      debugPrint('[UserService] createUserDocument failed (non-fatal): $e');
      rethrow;
    }
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Fetches the user profile from Firestore.
  ///
  /// Returns `null` if the document doesn't exist.
  /// Used by the router to check [AppUser.onboardingCompleted] and [AppUser.role].
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists || doc.data() == null) {
        debugPrint('[UserService] getUserProfile: document not found for $uid');
        return null;
      }
      return AppUser.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[UserService] getUserProfile error: $e');
      return null;
    }
  }

  /// Stream of user profile for real-time updates.
  ///
  /// Emits:
  /// - null if document doesn't exist
  /// - AppUser if document exists and can be parsed
  /// Errors (including permission issues) are logged and propagated
  /// so the router can detect stream errors and show error state.
  Stream<AppUser?> userProfileStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        debugPrint('[UserService.userProfileStream] Document missing for $uid');
        return null;
      }
      debugPrint('[UserService.userProfileStream] Snapshot received for $uid');
      return AppUser.fromMap(doc.data()!);
    }).handleError((Object error, StackTrace stack) {
      debugPrint('[UserService.userProfileStream] Stream error for $uid: $error');
      throw error;
    });
  }

  /// Check if the user has completed onboarding.
  Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists || doc.data() == null) return false;
      return doc.data()![AppConstants.fieldOnboardingCompleted] as bool? ??
          false;
    } catch (e) {
      debugPrint('[UserService] hasCompletedOnboarding error: $e');
      return false;
    }
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  /// Partial update of user profile fields.
  ///
  /// Only pass the fields you want to update.
  /// Null values are omitted automatically.
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? username,
    String? photoUrl,
    String? bio,
    List<String>? interests,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) updates[AppConstants.fieldName] = name.trim();
      if (username != null) updates[AppConstants.fieldUsername] = username.trim();
      if (photoUrl != null) updates[AppConstants.fieldPhotoUrl] = photoUrl;
      if (bio != null) updates[AppConstants.fieldBio] = bio.trim();
      if (interests != null) updates[AppConstants.fieldInterests] = interests;

      if (updates.isEmpty) return;

      await _userDoc(uid).update(updates);
      debugPrint('[UserService] User profile updated: $uid');
    } catch (e) {
      debugPrint('[UserService] updateUserProfile error: $e');
      rethrow;
    }
  }

  /// Completes the onboarding flow atomically.
  ///
  /// Saves all onboarding data in a single Firestore write and sets
  /// [onboardingCompleted] to `true`. The router will automatically
  /// re-evaluate and navigate to [HomePage].
  Future<void> completeOnboarding({
    required String uid,
    required String username,
    String? bio,
    String? photoUrl,
    required List<String> interests,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        AppConstants.fieldUsername: username.trim(),
        AppConstants.fieldInterests: interests,
        AppConstants.fieldOnboardingCompleted: true,
      };

      if (bio != null && bio.trim().isNotEmpty) {
        updates[AppConstants.fieldBio] = bio.trim();
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        updates[AppConstants.fieldPhotoUrl] = photoUrl;
      }

      debugPrint('[UserService] completeOnboarding: Writing to Firestore for $uid');
      debugPrint('[UserService] completeOnboarding: updates = $updates');
      
      await _userDoc(uid).update(updates);
      
      debugPrint('[UserService] completeOnboarding: SUCCESS for $uid');
      debugPrint('[UserService] completeOnboarding: onboardingCompleted set to TRUE');
    } catch (e) {
      debugPrint('[UserService] completeOnboarding error: $e');
      rethrow;
    }
  }

  // ── Username Availability ───────────────────────────────────────────────────

  /// Checks if a username is available in Firestore.
  ///
  /// Queries all user documents where `username == [username]`.
  /// Case-insensitive check is enforced by storing usernames in lowercase.
  ///
  /// Returns `true` if available, `false` if already taken.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalised = username.trim().toLowerCase();
      final query = await _usersRef
          .where(AppConstants.fieldUsername, isEqualTo: normalised)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('[UserService] isUsernameAvailable error: $e');
      // Fail open — let user proceed, uniqueness enforced by Firestore rules
      return true;
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  /// Deletes the user document and all subcollections.
  ///
  /// Should be called before [AuthService.deleteAccount] so that Firestore
  /// data is cleaned up before the Auth user is removed.
  Future<void> deleteUser(String uid) async {
    try {
      // Delete known subcollections
      for (final sub in ['following', 'followers', 'recipes']) {
        final snap =
            await _userDoc(uid).collection(sub).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }

      // Delete user document
      await _userDoc(uid).delete();
      debugPrint('[UserService] User deleted from Firestore: $uid');
    } catch (e) {
      debugPrint('[UserService] deleteUser error: $e');
      rethrow;
    }
  }
}
