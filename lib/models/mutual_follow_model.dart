import 'package:cloud_firestore/cloud_firestore.dart';

/// Mutual Follow (Takipleşme) model
/// İki kullanıcının birbirini takip ettiği durumu temsil eder
class MutualFollow {
  /// Birinci kullanıcı ID'si
  final String userId1;

  /// İkinci kullanıcı ID'si
  final String userId2;

  /// Mutual follow ilişkisinin kurulduğu tarih
  final DateTime createdAt;

  /// Mutual follow'un son güncellendiği tarih
  final DateTime updatedAt;

  /// Takipleşme durumu: 'active' veya 'inactive'
  final String status;

  /// Bilateral follow olup olmadığını kontrol
  /// Her iki kullanıcı da birbirini takip etmeli
  bool get isActive => status == 'active';

  MutualFollow({
    required this.userId1,
    required this.userId2,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  /// Firestore dokümanından model oluştur
  factory MutualFollow.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MutualFollow(
      userId1: data['userId1'] as String? ?? '',
      userId2: data['userId2'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'active',
    );
  }

  /// Firestore'a yazılacak veri formatı
  Map<String, dynamic> toMap() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
    };
  }

  /// JSON'dan model oluştur
  factory MutualFollow.fromJson(Map<String, dynamic> json) {
    return MutualFollow(
      userId1: json['userId1'] as String? ?? '',
      userId2: json['userId2'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      status: json['status'] as String? ?? 'active',
    );
  }

  /// Model'i JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  @override
  String toString() {
    return 'MutualFollow('
        'userId1: $userId1, '
        'userId2: $userId2, '
        'createdAt: $createdAt, '
        'status: $status'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutualFollow &&
          runtimeType == other.runtimeType &&
          userId1 == other.userId1 &&
          userId2 == other.userId2 &&
          status == other.status;

  @override
  int get hashCode => userId1.hashCode ^ userId2.hashCode ^ status.hashCode;

  /// Kopyasını oluştur ve bazı alanları değiştir
  MutualFollow copyWith({
    String? userId1,
    String? userId2,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return MutualFollow(
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
