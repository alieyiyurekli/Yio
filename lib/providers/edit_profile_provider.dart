import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../core/models/app_user.dart';
import '../core/services/user_service.dart';
import '../services/firebase_profile_image_service.dart';

/// Edit Profile Provider
///
/// Manages profile editing state with optimistic updates and Firestore sync.
/// Features:
/// - Real-time profile editing with change detection
/// - Debounced username uniqueness check
/// - Image upload with compression
/// - Optimistic UI updates
/// - Save only when changes detected
class EditProfileProvider extends ChangeNotifier {
  final UserService _userService;
  final FirebaseProfileImageService _imageService;

  // Mutable edit state
  late AppUser _originalUser;
  late AppUser _editingUser;

  // UI state
  final bool _isLoading = false;
  bool _isSaving = false;
  bool _isCheckingUsername = false;
  bool _usernameAvailable = true;
  String? _errorMessage;
  String? _successMessage;

  // Image state
  File? _selectedImageFile;
  String? _imageUploadProgress;
  bool _isUploadingImage = false;

  // Debounce state for username check
  Future<void>? _debounceCheckUsername;

  // Getters
  AppUser get originalUser => _originalUser;
  AppUser get editingUser => _editingUser;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isCheckingUsername => _isCheckingUsername;
  bool get usernameAvailable => _usernameAvailable;
  bool get isUploadingImage => _isUploadingImage;
  String? get imageUploadProgress => _imageUploadProgress;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  File? get selectedImageFile => _selectedImageFile;

  /// Has changes been made to the profile
  bool get hasChanges =>
      _editingUser.name != _originalUser.name ||
      _editingUser.username != _originalUser.username ||
      _editingUser.bio != _originalUser.bio ||
      _editingUser.interests != _originalUser.interests ||
      _selectedImageFile != null;

  /// Is save button enabled
  bool get canSave =>
      hasChanges &&
      !_isSaving &&
      _usernameAvailable &&
      !_isCheckingUsername &&
      _editingUser.name.isNotEmpty;

  EditProfileProvider({
    required UserService userService,
    required FirebaseProfileImageService imageService,
  })  : _userService = userService,
        _imageService = imageService;

  /// Initialize with user data
  void initializeWithUser(AppUser user) {
    _originalUser = user;
    _editingUser = user.copyWith();
    _selectedImageFile = null;
    _errorMessage = null;
    _successMessage = null;
    _usernameAvailable = true;
    notifyListeners();
  }

  /// Update user name
  void updateName(String value) {
    if (_editingUser.name != value) {
      _editingUser = _editingUser.copyWith(name: value);
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Update user bio
  void updateBio(String value) {
    if (_editingUser.bio != value) {
      _editingUser = _editingUser.copyWith(bio: value);
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Update username with debounced uniqueness check
  void updateUsername(String value) {
    if (_editingUser.username != value) {
      _editingUser = _editingUser.copyWith(username: value);
      _errorMessage = null;

      // Reset availability if field is empty
      if (value.isEmpty) {
        _usernameAvailable = true;
        notifyListeners();
        return;
      }

      // Debounced username check
      _debounceUsernameCheck(value);
      notifyListeners();
    }
  }

  /// Debounced username uniqueness check
  void _debounceUsernameCheck(String username) {
    // Cancel previous debounce
    _debounceCheckUsername = null;

    // Start new debounce
    _debounceCheckUsername = Future.delayed(
      const Duration(milliseconds: 500),
      () => _checkUsernameAvailability(username),
    );
  }

  /// Check if username is available
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username == _originalUser.username) {
      _usernameAvailable = true;
      _isCheckingUsername = false;
      notifyListeners();
      return;
    }

    _isCheckingUsername = true;
    notifyListeners();

    try {
      // Check username format first
      if (!AppUser.isValidUsername(username)) {
        _usernameAvailable = false;
        _errorMessage = 'Kullanıcı adı yalnızca harf, sayı ve alt çizgi içerebilir';
        _isCheckingUsername = false;
        notifyListeners();
        return;
      }

      // Check availability in Firestore
      final available = await _userService.isUsernameAvailable(username);
      _usernameAvailable = available;
      _errorMessage = available ? null : 'Bu kullanıcı adı zaten kullanılıyor';
    } catch (e) {
      debugPrint('[EditProfileProvider] Username check error: $e');
      _errorMessage = 'Kullanıcı adı kontrolü başarısız oldu';
      _usernameAvailable = false;
    } finally {
      _isCheckingUsername = false;
      notifyListeners();
    }
  }

  /// Toggle interest selection
  void toggleInterest(String interest) {
    final interests = List<String>.from(_editingUser.interests);
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    _editingUser = _editingUser.copyWith(interests: interests);
    _errorMessage = null;
    notifyListeners();
  }

  /// Select image from camera or gallery
  Future<void> selectImage({required ImageSource source}) async {
    try {
      _errorMessage = null;
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      _selectedImageFile = File(image.path);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Resim seçme hatası: $e';
      notifyListeners();
    }
  }

  /// Remove selected image
  void removeSelectedImage() {
    _selectedImageFile = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Save profile changes to Firestore
  Future<bool> saveProfile() async {
    if (!canSave) return false;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Upload image if selected
      String? photoUrl = _editingUser.photoUrl;
      if (_selectedImageFile != null) {
        _isUploadingImage = true;
        notifyListeners();

        try {
          // Compress image
          final compressedFile = await _compressImage(_selectedImageFile!);

          // Upload to Firebase Storage
          photoUrl = await _imageService.uploadProfileImage(
            compressedFile,
            userId: _editingUser.uid,
          );
        } catch (e) {
          throw Exception('Resim yükleme hatası: $e');
        } finally {
          _isUploadingImage = false;
        }
      }

      // Prepare updates
      await _userService.updateUserProfile(
        _editingUser.uid,
        name: _editingUser.name,
        username: _editingUser.username,
        bio: _editingUser.bio,
        interests: _editingUser.interests,
        photoUrl: photoUrl,
      );

      // Update local state
      final updatedUser = _editingUser.copyWith(photoUrl: photoUrl);
      _originalUser = updatedUser;
      _editingUser = updatedUser.copyWith();
      _selectedImageFile = null;
      _successMessage = 'Profil başarıyla güncellendi';

      return true;
    } catch (e) {
      debugPrint('[EditProfileProvider] Save profile error: $e');
      _errorMessage = 'Hata: ${e.toString()}';
      return false;
    } finally {
      _isSaving = false;
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Compress image using flutter_image_compress
  Future<File> _compressImage(File file) async {
    try {
      final targetPath = '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 512,
        minHeight: 512,
        rotate: 0,
      );

      if (result == null) {
        return file; // Return original if compression fails
      }

      return File(result.path);
    } catch (e) {
      debugPrint('[EditProfileProvider] Compress error: $e');
      return file;
    }
  }

  /// Discard changes and revert to original
  void discardChanges() {
    _editingUser = _originalUser.copyWith();
    _selectedImageFile = null;
    _errorMessage = null;
    _successMessage = null;
    _usernameAvailable = true;
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceCheckUsername = null;
    super.dispose();
  }
}
