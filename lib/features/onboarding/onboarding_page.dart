import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/services/user_service.dart';

/// Onboarding Page — 3-step profile completion flow.
///
/// Step 1: Unique username selection (Firestore availability check)
/// Step 2: Profile photo (optional) + short bio
/// Step 3: Interests selection (multi-select chips)
///
/// On completion, [UserService.completeOnboarding] sets
/// `onboardingCompleted=true` and [AppRouter] auto-navigates to [HomePage].
/// No manual navigation needed.
class OnboardingPage extends StatefulWidget {
  final String uid;

  const OnboardingPage({super.key, required this.uid});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _userService = UserService();
  final _pageController = PageController();

  // Step 1 state
  final _usernameController = TextEditingController();
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;

  // Step 2 state
  final _bioController = TextEditingController();
  File? _selectedImage;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;

  // Step 3 state
  final Set<String> _selectedInterests = {};

  // Global state
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Username helpers ─────────────────────────────────────────────────────────

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < AppConstants.usernameMinLength) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
      });
      return;
    }

    if (!AppUser_isValidUsername(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = AppConstants.validationUsernameFormat;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final available = await _userService.isUsernameAvailable(username.toLowerCase());
      if (!mounted) return;
      setState(() {
        _isUsernameAvailable = available;
        _usernameError = available ? null : AppConstants.errorUsernameTaken;
      });
    } finally {
      if (mounted) setState(() => _isCheckingUsername = false);
    }
  }

  bool AppUser_isValidUsername(String username) {
    if (username.length < AppConstants.usernameMinLength ||
        username.length > AppConstants.usernameMaxLength) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  bool get _isStep1Valid =>
      _usernameController.text.trim().length >= AppConstants.usernameMinLength &&
      _isUsernameAvailable == true &&
      !_isCheckingUsername;

  // ── Photo helpers ─────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _isUploadingPhoto = true;
      });

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${widget.uid}/profile_photo.jpg');

      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _uploadedPhotoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf yüklenemedi: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Completion ────────────────────────────────────────────────────────────────

  Future<void> _completeOnboarding() async {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.validationInterestsRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('[OnboardingPage] _completeOnboarding: Starting onboarding completion');
      debugPrint('[OnboardingPage] uid=${widget.uid}, username=${_usernameController.text.trim().toLowerCase()}');
      
      await _userService.completeOnboarding(
        uid: widget.uid,
        username: _usernameController.text.trim().toLowerCase(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        photoUrl: _uploadedPhotoUrl,
        interests: _selectedInterests.toList(),
      );

      debugPrint('[OnboardingPage] _completeOnboarding: SUCCESS - awaited completeOnboarding');
      debugPrint('[OnboardingPage] AppRouter will auto-navigate to HomePage via stream update');
      
      // AppRouter will detect onboardingCompleted=true and navigate to HomePage
      // No manual navigation needed here!
    } catch (e) {
      if (!mounted) return;
      debugPrint('[OnboardingPage] _completeOnboarding: ERROR - $e');
      setState(() => _isLoading = false);
      if (!mounted) return; // Double-check before showing SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil tamamlanamadı: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    // Note: _isLoading is NOT cleared on success because AppRouter will
    // navigate away — keeping the spinner prevents flicker
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Username(),
                  _buildStep2Profile(),
                  _buildStep3Interests(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textPrimary,
            )
          else
            const SizedBox(width: 48),
          const Expanded(
            child: Text(
              'Profilini Tamamla',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(AppConstants.onboardingTotalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Username ──────────────────────────────────────────────────────────

  Widget _buildStep1Username() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Kullanıcı Adın',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sana ulaşabilmek için benzersiz bir kullanıcı adı seç.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              // Debounced availability check
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted &&
                    _usernameController.text == value &&
                    value.trim().isNotEmpty) {
                  _checkUsernameAvailability(value.trim());
                }
              });
              setState(() {
                _isUsernameAvailable = null;
                _usernameError = null;
              });
            },
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              hintText: 'ahmetyilmaz',
              prefixText: '@',
              prefixIcon: const Icon(Icons.alternate_email),
              suffixIcon: _buildUsernameSuffix(),
              errorText: _usernameError,
              helperText: _isUsernameAvailable == true
                  ? 'Bu kullanıcı adı uygun!'
                  : 'Harf, rakam ve alt çizgi (_) kullanabilirsin',
              helperStyle: TextStyle(
                color: _isUsernameAvailable == true
                    ? AppColors.success
                    : AppColors.textLight,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isStep1Valid ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Devam Et',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUsernameSuffix() {
    if (_isCheckingUsername) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_isUsernameAvailable == true) {
      return const Icon(Icons.check_circle, color: AppColors.success);
    }
    if (_isUsernameAvailable == false) {
      return const Icon(Icons.cancel, color: AppColors.error);
    }
    return const SizedBox.shrink();
  }

  // ── Step 2: Profile Photo + Bio ───────────────────────────────────────────────

  Widget _buildStep2Profile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Profil Fotoğrafın',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kendini tanıt! Fotoğraf ve bio eklemek isteğe bağlı.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Profile Photo
          Center(
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.divider,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 32,
                            color: AppColors.textLight,
                          )
                        : null,
                  ),
                  if (_isUploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                  if (_uploadedPhotoUrl != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.textWhite,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Text(
                _selectedImage == null
                    ? 'Fotoğraf Seç (İsteğe Bağlı)'
                    : 'Fotoğrafı Değiştir',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bio
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            maxLength: AppConstants.bioMaxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Hakkında (İsteğe Bağlı)',
              hintText: 'Kendini kısaca anlat...',
              alignLabelWithHint: true,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploadingPhoto ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Devam Et',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Step 3: Interests ─────────────────────────────────────────────────────────

  Widget _buildStep3Interests() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'İlgi Alanların',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'En az ${AppConstants.interestsMinCount}, en fazla ${AppConstants.interestsMaxCount} ilgi alanı seç.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                final atMax = _selectedInterests.length >=
                    AppConstants.interestsMaxCount;
                final disabled = !isSelected && atMax;

                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedInterests.remove(interest);
                            } else {
                              _selectedInterests.add(interest);
                            }
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : disabled
                              ? AppColors.divider.withOpacity(0.5)
                              : AppColors.divider,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textWhite
                            : disabled
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Selection counter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${_selectedInterests.length}/${AppConstants.interestsMaxCount} seçildi',
              style: TextStyle(
                fontSize: 13,
                color: _selectedInterests.length >=
                        AppConstants.interestsMinCount
                    ? AppColors.success
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading ||
                      _selectedInterests.length <
                          AppConstants.interestsMinCount)
                  ? null
                  : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textWhite,
                      ),
                    )
                  : const Text(
                      'Profili Tamamla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
