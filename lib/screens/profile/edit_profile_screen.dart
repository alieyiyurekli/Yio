import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/models/app_user.dart';
import '../../core/services/user_service.dart';
import '../../providers/edit_profile_provider.dart';
import '../../services/firebase_profile_image_service.dart';

/// Premium Edit Profile Screen
///
/// Features:
/// - Modern minimalist UI inspired by Instagram + Apple Settings
/// - Sections: Header, Avatar, Basic Info, Interests, Account Settings
/// - Firestore integration for data persistence
/// - Image upload to Firebase Storage with compression
/// - Real-time username uniqueness check (debounced)
/// - Optimistic UI updates
/// - Save only when changes detected
/// - Smooth animations and responsive design
class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  late final EditProfileProvider _provider;
  late final AnimationController _fabController;
  late final AnimationController _headerController;
  late final Animation<double> _fabAnimation;
  late final Animation<double> _headerAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupProvider();
    _setupAnimations();
    _setupScrollListener();
  }

  void _setupProvider() {
    _provider = EditProfileProvider(
      userService: context.read<UserService>(),
      imageService: FirebaseProfileImageService(),
    );
    _provider.initializeWithUser(widget.user);

    // Initialize controllers
    _nameController.text = widget.user.name;
    _usernameController.text = widget.user.username ?? '';
    _bioController.text = widget.user.bio ?? '';
  }

  void _setupAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    );

    _fabController.forward();
    _headerController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset > 50 && _fabController.status == AnimationStatus.completed) {
        _fabController.reverse();
      } else if (offset < 50 && _fabController.status == AnimationStatus.dismissed) {
        _fabController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildSaveButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F8F8),
      elevation: 0,
      leading: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _headerAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(_headerAnimation),
              child: child,
            ),
          );
        },
        child: IconButton(
          onPressed: () => _handleDiscard(),
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textPrimary,
        ),
      ),
      title: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _headerAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(_headerAnimation),
              child: child,
            ),
          );
        },
        child: const Text(
          'Profili Düzenle',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      actions: [
        Consumer<EditProfileProvider>(
          builder: (context, provider, child) {
            return TextButton(
              onPressed: provider.hasChanges ? () => _handleDiscard() : null,
              child: Text(
                'İptal',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: provider.hasChanges
                      ? AppColors.primary
                      : AppColors.textLight,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<EditProfileProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _AvatarSection(
                    user: provider.editingUser,
                    selectedImage: provider.selectedImageFile,
                    isUploading: provider.isUploadingImage,
                    onPickImage: (source) => provider.selectImage(source: source),
                    onRemoveImage: provider.removeSelectedImage,
                  ),
                  const SizedBox(height: 24),
                  _BasicInfoSection(
                    nameController: _nameController,
                    usernameController: _usernameController,
                    bioController: _bioController,
                    provider: provider,
                  ),
                  const SizedBox(height: 24),
                  _InterestsSection(
                    selectedInterests: provider.editingUser.interests,
                    onToggleInterest: provider.toggleInterest,
                  ),
                  const SizedBox(height: 24),
                  _AccountSettingsSection(user: provider.editingUser),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            if (provider.isSaving)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Kaydediliyor...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Consumer<EditProfileProvider>(
      builder: (context, provider, child) {
        return ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton.extended(
            label: Text(provider.isSaving ? 'Kaydediliyor...' : 'Kaydet'),
            icon: provider.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            onPressed: provider.canSave ? () => _handleSave(provider) : null,
            backgroundColor: provider.canSave ? AppColors.primary : AppColors.textLight,
            elevation: provider.canSave ? 8 : 0,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave(EditProfileProvider provider) async {
    final success = await provider.saveProfile();
    if (success && mounted) {
      Navigator.of(context).pop(provider.editingUser);
      _showSuccessSnackBar();
    }
  }

  Future<void> _handleDiscard() async {
    final provider = context.read<EditProfileProvider>();
    if (provider.hasChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Değişiklikleri iptal et?'),
          content: const Text('Yaptığınız değişiklikler kaydedilmeyecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('İptal Et'),
            ),
          ],
        ),
      );
      if (shouldDiscard == true) {
        if (mounted) Navigator.of(context).pop();
      }
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil başarıyla güncellendi'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Section
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final AppUser user;
  final File? selectedImage;
  final bool isUploading;
  final ValueChanged<ImageSource> onPickImage;
  final VoidCallback onRemoveImage;

  const _AvatarSection({
    required this.user,
    this.selectedImage,
    required this.isUploading,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = selectedImage ?? (user.photoUrl != null ? null : 'initials');

    return Column(
      children: [
        // Avatar
        GestureDetector(
          onTap: isUploading ? null : () => _showImageSourceSheet(context),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFFB088)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: displayImage is File
                      ? FileImage(displayImage)
                      : (displayImage is String && displayImage != 'initials'
                          ? NetworkImage(displayImage) as ImageProvider
                          : null),
                  child: displayImage == 'initials'
                      ? Text(
                          _getInitials(user.name),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                if (isUploading)
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                if (!isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Profil fotoğrafını değiştirmek için dokunun',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        if (selectedImage != null)
          TextButton.icon(
            onPressed: onRemoveImage,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Fotoğrafı kaldır'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
      ],
    );
  }

  Future<void> _showImageSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Fotoğraf Seç',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Basic Info Section
// ─────────────────────────────────────────────────────────────────────────────

class _BasicInfoSection extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController bioController;
  final EditProfileProvider provider;

  const _BasicInfoSection({
    required this.nameController,
    required this.usernameController,
    required this.bioController,
    required this.provider,
  });

  @override
  State<_BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<_BasicInfoSection> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onNameChanged);
    widget.usernameController.addListener(_onUsernameChanged);
    widget.bioController.addListener(_onBioChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onNameChanged);
    widget.usernameController.removeListener(_onUsernameChanged);
    widget.bioController.removeListener(_onBioChanged);
    super.dispose();
  }

  void _onNameChanged() {
    widget.provider.updateName(widget.nameController.text);
  }

  void _onUsernameChanged() {
    widget.provider.updateUsername(widget.usernameController.text);
  }

  void _onBioChanged() {
    widget.provider.updateBio(widget.bioController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Temel Bilgiler',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _NameField(controller: widget.nameController),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _UsernameField(
            controller: widget.usernameController,
            provider: widget.provider,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _BioField(controller: widget.bioController),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Ad Soyad',
          hintText: 'Adınızı girin',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          labelStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          hintStyle: TextStyle(fontSize: 16, color: AppColors.textLight),
        ),
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final EditProfileProvider provider;

  const _UsernameField({
    required this.controller,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.none,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          LengthLimitingTextInputFormatter(AppConstants.usernameMaxLength),
        ],
        decoration: InputDecoration(
          labelText: 'Kullanıcı Adı',
          hintText: '@kullaniciadi',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          labelStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          hintStyle: const TextStyle(fontSize: 16, color: AppColors.textLight),
          suffixIcon: _buildStatusIcon(),
        ),
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
    );
  }

  Widget? _buildStatusIcon() {
    if (controller.text.isEmpty) return null;

    return Consumer<EditProfileProvider>(
      builder: (context, provider, child) {
        if (provider.isCheckingUsername) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (!provider.usernameAvailable) {
          return const Icon(Icons.close, color: AppColors.error, size: 20);
        }

        if (controller.text.isNotEmpty) {
          return const Icon(Icons.check, color: AppColors.success, size: 20);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _BioField extends StatelessWidget {
  final TextEditingController controller;

  const _BioField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: 3,
        maxLength: AppConstants.bioMaxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Hakkında',
          hintText: 'Kendinizden bahsedin...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          labelStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          hintStyle: TextStyle(fontSize: 16, color: AppColors.textLight),
          counterStyle: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interests Section
// ─────────────────────────────────────────────────────────────────────────────

class _InterestsSection extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<String> onToggleInterest;

  const _InterestsSection({
    required this.selectedInterests,
    required this.onToggleInterest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'İlgi Alanları',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.availableInterests.map((interest) {
                final isSelected = selectedInterests.contains(interest);
                return _InterestChip(
                  label: interest,
                  isSelected: isSelected,
                  onTap: () => onToggleInterest(interest),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Settings Section
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSettingsSection extends StatelessWidget {
  final AppUser user;

  const _AccountSettingsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Hesap Bilgileri',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _SettingTile(
            icon: Icons.email_outlined,
            title: 'E-posta',
            value: user.email,
            valueColor: AppColors.textSecondary,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _SettingTile(
            icon: Icons.calendar_today_outlined,
            title: 'Katılma Tarihi',
            value: _formatDate(user.createdAt),
            valueColor: AppColors.textSecondary,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _SettingTile(
            icon: Icons.verified_outlined,
            title: 'Hesap Durumu',
            value: user.onboardingCompleted ? 'Aktif' : 'Onboarding Bekliyor',
            valueColor: user.onboardingCompleted ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
