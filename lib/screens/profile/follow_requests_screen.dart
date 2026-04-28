import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../models/follow_models.dart';
import '../../providers/follow_request_provider.dart';
import 'package:go_router/go_router.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowRequestProvider>().loadAllRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<UserModel?> _getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkIconActive : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Takip İstekleri',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
          tabs: const [
            Tab(text: 'Beklemede'),
            Tab(text: 'Geçmiş'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRequests(isDark),
          _buildPastRequests(isDark),
        ],
      ),
    );
  }

  Widget _buildPendingRequests(bool isDark) {
    return Consumer<FollowRequestProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = provider.pendingRequests;

        if (requests.isEmpty) {
          return _buildEmptyState(
            isDark: isDark,
            message: 'Bekleyen istek yok',
            icon: Icons.mail_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPendingRequests(),
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FutureBuilder<UserModel?>(
                future: _getUserById(request.requesterId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final user = userSnapshot.data!;
                  return _buildRequestItem(
                    request: request,
                    user: user,
                    isDark: isDark,
                    isPending: true,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPastRequests(bool isDark) {
    return Consumer<FollowRequestProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pastRequests = [
          ...provider.acceptedRequests,
          ...provider.rejectedRequests,
        ];

        if (pastRequests.isEmpty) {
          return _buildEmptyState(
            isDark: isDark,
            message: 'İşlem geçmişi boş',
            icon: Icons.history,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAllRequests(),
          child: ListView.builder(
            itemCount: pastRequests.length,
            itemBuilder: (context, index) {
              final request = pastRequests[index];
              return FutureBuilder<UserModel?>(
                future: _getUserById(request.requesterId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final user = userSnapshot.data!;
                  return _buildRequestItem(
                    request: request,
                    user: user,
                    isDark: isDark,
                    isPending: false,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestItem({
    required FollowRequest request,
    required UserModel user,
    required bool isDark,
    required bool isPending,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: ClipOval(
              child: user.photoUrl != null
                  ? Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Kullanıcı',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '@${user.email.split('@')[0]}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          if (isPending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  onPressed: () =>
                      context.read<FollowRequestProvider>().acceptRequest(
                            request.requestId,
                          ),
                  label: 'Kabul Et',
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.lightTextInverse,
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildActionButton(
                  onPressed: () =>
                      context.read<FollowRequestProvider>().rejectRequest(
                            request.requestId,
                          ),
                  label: 'Reddet',
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  textColor: AppColors.primary,
                  isDark: isDark,
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: request.status == FollowRequestStatus.accepted
                    ? AppColors.success
                    : AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                request.status == FollowRequestStatus.accepted
                    ? 'Kabul Edildi'
                    : 'Reddedildi',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.lightTextInverse,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required bool isDark,
  }) {
    return SizedBox(
      width: 70,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: AppColors.primary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark
                ? AppColors.darkIconInactive
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Icon(
        Icons.person,
        color: isDark ? AppColors.darkIconInactive : AppColors.lightTextTertiary,
      ),
    );
  }
}
