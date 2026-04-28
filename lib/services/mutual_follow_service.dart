import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/follow_constants.dart';
import '../models/mutual_follow_model.dart';

/// Mutual Follow Service (Takipleşme Servisi)
/// İki kullanıcının birbirini takip ettiği durumu yönetir
class MutualFollowService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MutualFollowService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Mutual follow koleksiyonu yolu
  String get _mutualFollowsCollection => 'mutualFollows';

  /// İki kullanıcı ID'sinden doküman ID'si oluştur
  /// Her zaman küçükten büyüğe sıralı ID döndürür (benzersizlik için)
  String _getMutualFollowId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// İki kullanıcının birbirini takip edip etmediğini kontrol et
  Future<bool> isMutualFollow(String userId1, String userId2) async {
    try {
      final docId = _getMutualFollowId(userId1, userId2);
      final doc = await _firestore
          .collection(_mutualFollowsCollection)
          .doc(docId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final status = data['status'] as String? ?? 'inactive';
      return status == 'active';
    } catch (e) {
      return false;
    }
  }

  /// İki kullanıcının birbirini takip edip etmediğini stream olarak al
  Stream<bool> isMutualFollowStream(String userId1, String userId2) {
    final docId = _getMutualFollowId(userId1, userId2);
    return _firestore
        .collection(_mutualFollowsCollection)
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data()!;
      final status = data['status'] as String? ?? 'inactive';
      return status == 'active';
    });
  }

  /// Mutual follow ilişkisi oluştur veya güncelle
  /// İki kullanıcı birbirini takip ettiğinde çağrılır
  Future<bool> createMutualFollow(String userId1, String userId2) async {
    try {
      final docId = _getMutualFollowId(userId1, userId2);
      final now = Timestamp.now();

      // Önce mevcut durumu kontrol et
      final existingDoc = await _firestore
          .collection(_mutualFollowsCollection)
          .doc(docId)
          .get();

      if (existingDoc.exists) {
        // Zaten var, sadece güncelle
        await _firestore
            .collection(_mutualFollowsCollection)
            .doc(docId)
            .update({
          'status': 'active',
          'updatedAt': now,
        });
      } else {
        // Yeni oluştur
        await _firestore
            .collection(_mutualFollowsCollection)
            .doc(docId)
            .set({
          'userId1': userId1,
          'userId2': userId2,
          'createdAt': now,
          'updatedAt': now,
          'status': 'active',
        });
      }

      return true;
    } catch (e) {
      throw Exception('Takipleşme oluşturma başarısız: $e');
    }
  }

  /// Mutual follow ilişkisini kaldır
  /// İki kullanıcıdan biri diğerini takip etmeyi bıraktığında çağrılır
  Future<bool> removeMutualFollow(String userId1, String userId2) async {
    try {
      final docId = _getMutualFollowId(userId1, userId2);
      final now = Timestamp.now();

      // Durumu inactive yap (tamamen silmek yerine)
      await _firestore
          .collection(_mutualFollowsCollection)
          .doc(docId)
          .update({
        'status': 'inactive',
        'updatedAt': now,
      });

      return true;
    } catch (e) {
      throw Exception('Takipleşme kaldırma başarısız: $e');
    }
  }

  /// Mevcut kullanıcının mutual follow listesini al
  Future<List<MutualFollow>> getMutualFollows(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_mutualFollowsCollection)
          .where('status', isEqualTo: 'active')
          .where('userId1', isEqualTo: userId)
          .get();

      final snapshot2 = await _firestore
          .collection(_mutualFollowsCollection)
          .where('status', isEqualTo: 'active')
          .where('userId2', isEqualTo: userId)
          .get();

      final mutualFollows = <MutualFollow>[];
      
      for (final doc in snapshot.docs) {
        mutualFollows.add(MutualFollow.fromDocument(doc));
      }
      
      for (final doc in snapshot2.docs) {
        mutualFollows.add(MutualFollow.fromDocument(doc));
      }

      // Tarihe göre sırala (en yeni en üstte)
      mutualFollows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return mutualFollows;
    } catch (e) {
      throw Exception('Takipleşmeler yüklenemedi: $e');
    }
  }

  /// Mevcut kullanıcının mutual follow listesini stream olarak al
  Stream<List<MutualFollow>> mutualFollowsStream(String userId) {
    final stream1 = _firestore
        .collection(_mutualFollowsCollection)
        .where('status', isEqualTo: 'active')
        .where('userId1', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MutualFollow.fromDocument(doc)).toList());

    final stream2 = _firestore
        .collection(_mutualFollowsCollection)
        .where('status', isEqualTo: 'active')
        .where('userId2', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MutualFollow.fromDocument(doc)).toList());

    // İki stream'i birleştir
    return stream1.asyncMap((list1) async {
      final list2 = await stream2.first;
      final combined = [...list1, ...list2];
      combined.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return combined;
    });
  }

  /// Mutual follow sayısını al
  Future<int> getMutualFollowCount(String userId) async {
    try {
      final snapshot1 = await _firestore
          .collection(_mutualFollowsCollection)
          .where('status', isEqualTo: 'active')
          .where('userId1', isEqualTo: userId)
          .get();

      final snapshot2 = await _firestore
          .collection(_mutualFollowsCollection)
          .where('status', isEqualTo: 'active')
          .where('userId2', isEqualTo: userId)
          .get();

      return snapshot1.size + snapshot2.size;
    } catch (e) {
      return 0;
    }
  }

  /// Mutual follow sayısını stream olarak al
  Stream<int> mutualFollowCountStream(String userId) {
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      return await getMutualFollowCount(userId);
    }).asyncMap((future) => future);
  }

  /// Belirli bir kullanıcının mutual follow listesinden diğer kullanıcı ID'lerini al
  Future<List<String>> getMutualFollowUserIds(String userId) async {
    try {
      final mutualFollows = await getMutualFollows(userId);
      final userIds = <String>[];
      
      for (final mutualFollow in mutualFollows) {
        if (mutualFollow.userId1 == userId) {
          userIds.add(mutualFollow.userId2);
        } else {
          userIds.add(mutualFollow.userId1);
        }
      }
      
      return userIds;
    } catch (e) {
      return [];
    }
  }

  /// Mevcut kullanıcının bir kullanıcının mutual follow olup olmadığını kontrol et
  Future<bool> isCurrentUserMutualFollowWith(String targetUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;
    
    return await isMutualFollow(currentUserId, targetUserId);
  }

  /// Mevcut kullanıcının bir kullanıcının mutual follow olup olmadığını stream olarak al
  Stream<bool> isCurrentUserMutualFollowWithStream(String targetUserId) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return Stream.value(false);
    }
    
    return isMutualFollowStream(currentUserId, targetUserId);
  }

  /// Mutual follow ilişkisini tamamen sil (temizlik için)
  /// Sadece admin işlemlerinde kullanılmalı
  Future<bool> deleteMutualFollow(String userId1, String userId2) async {
    try {
      final docId = _getMutualFollowId(userId1, userId2);
      await _firestore
          .collection(_mutualFollowsCollection)
          .doc(docId)
          .delete();
      return true;
    } catch (e) {
      throw Exception('Takipleşme silme başarısız: $e');
    }
  }

  /// Tüm inactive mutual follow ilişkilerini temizle
  /// Periyodik temizlik için kullanılabilir
  Future<int> cleanupInactiveMutualFollows() async {
    try {
      final snapshot = await _firestore
          .collection(_mutualFollowsCollection)
          .where('status', isEqualTo: 'inactive')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return snapshot.size;
    } catch (e) {
      throw Exception('Temizlik başarısız: $e');
    }
  }
}
