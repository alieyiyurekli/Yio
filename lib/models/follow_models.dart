import 'package:cloud_firestore/cloud_firestore.dart';

/// Follow status enum
/// Represents the current follow relationship between two users
enum FollowStatus {
  /// Not following this user
  notFollowing,
  
  /// Currently following this user
  following,
  
  /// Follow request is pending (for private accounts)
  pending,
  
  /// Follow request has been sent
  requested,
}

extension FollowStatusExtension on FollowStatus {
  String get label {
    switch (this) {
      case FollowStatus.notFollowing:
        return 'Takip Et';
      case FollowStatus.following:
        return 'Takip Ediliyor';
      case FollowStatus.pending:
        return 'İstek Gönderildi';
      case FollowStatus.requested:
        return 'İstek Bekleniyor';
    }
  }

  bool get isFollowing => this == FollowStatus.following;
  bool get isPending => this == FollowStatus.pending || this == FollowStatus.requested;
  bool get canFollow => this == FollowStatus.notFollowing;
}

/// Follow request model
/// Represents a follow request for private accounts
class FollowRequest {
  final String requestId;
  final String requesterId;
  final String requesterName;
  final String? requesterPhotoUrl;
  final DateTime requestedAt;
  final FollowRequestStatus status;

  FollowRequest({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhotoUrl,
    required this.requestedAt,
    required this.status,
  });

  factory FollowRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowRequest(
      requestId: doc.id,
      requesterId: data['requesterId'] as String,
      requesterName: data['requesterName'] as String,
      requesterPhotoUrl: data['requesterPhotoUrl'] as String?,
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      status: FollowRequestStatus.values.firstWhere(
        (e) => e.toString() == 'FollowRequestStatus.${data['status']}',
        orElse: () => FollowRequestStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhotoUrl': requesterPhotoUrl,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.toString().split('.').last,
    };
  }

  FollowRequest copyWith({
    String? requestId,
    String? requesterId,
    String? requesterName,
    String? requesterPhotoUrl,
    DateTime? requestedAt,
    FollowRequestStatus? status,
  }) {
    return FollowRequest(
      requestId: requestId ?? this.requestId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhotoUrl: requesterPhotoUrl ?? this.requesterPhotoUrl,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
    );
  }
}

/// Follow request status enum
enum FollowRequestStatus {
  pending,
  accepted,
  rejected,
}

extension FollowRequestStatusExtension on FollowRequestStatus {
  String get label {
    switch (this) {
      case FollowRequestStatus.pending:
        return 'Bekliyor';
      case FollowRequestStatus.accepted:
        return 'Kabul Edildi';
      case FollowRequestStatus.rejected:
        return 'Reddedildi';
    }
  }
}
