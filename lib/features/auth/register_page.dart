import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';

/// Terms of Service Modal
class _TermsOfServiceModal extends StatelessWidget {
  const _TermsOfServiceModal();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Kullanım Koşulları',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '1. Kabul Edilen Koşullar\n'
                  'Bu uygulamayı kullanarak aşağıdaki koşulları kabul etmiş sayılırsınız:\n\n'
                  '2. Kullanıcı Sorumlulukları\n'
                  '- Kullanıcı adınızın ve şifrenizin güvenliğinden siz sorumlusunuz.\n'
                  '- Başka kullanıcıların hesaplarına izinsiz erişemezsiniz.\n'
                  '- Uygulamayı yasa dışı amaçlarla kullanamazsınız.\n\n'
                  '3. İçerik Hakları\n'
                  '- Paylaştığınız tariflerin size ait olduğunu garanti edersiniz.\n'
                  '- Telif hakkı içeren içerikleri izinsiz paylaşamazsınız.\n\n'
                  '4. Gizlilik\n'
                  '- Kişisel verileriniz Gizlilik Politikası\'na uygun olarak işlenir.\n'
                  '- Verileriniz üçüncü şahıslarla paylaşılmaz.\n\n'
                  '5. Hesap İptali\n'
                  '- Hesabınızı istediğiniz zaman silebilirsiniz.\n'
                  '- Silinen hesaplar geri yüklenemez.\n\n'
                  '6. Değişiklikler\n'
                  '- Bu koşullar değiştirilebilir. Değişiklikler uygulama içinde bildirilir.\n\n'
                  'Son güncelleme: Mart 2026',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified Registration + Onboarding Page
///
/// 4-step complete user registration & profile setup:
/// Step 1: Email + Şifre + İsim (Firebase Auth)
/// Step 2: Kullanıcı Adı (Firestore uniqueness check)
/// Step 3: Profil Fotoğrafı + Bio (Firebase Storage + Firestore)
/// Step 4: İlgi Alanları (Firestore)
///
/// On completion, onboardingCompleted=true and AppRouter auto-navigates to HomePage.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _userService = UserService();
  final _pageController = PageController();

  // Step 1: Auth
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  // Step 2: Username
  final _usernameController = TextEditingController();
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;

  // Step 3: Profile
  final _bioController = TextEditingController();
  File? _selectedImage;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;

  // Step 4: Interests
  final Set<String> _selectedInterests = {};

  // Global
  int _currentStep = 0;
  bool _isLoading = false;
  String? _userId; // Set after Firebase Auth succeeds

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Step 1: Auth Validation ──────────────────────────────────────────────

  bool get _isStep1Valid {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _passwordController.text == _confirmPasswordController.text &&
        _acceptedTerms;
  }

  void _proceedToStep2() {
    if (!_isStep1Valid) return;
    
    // Just navigate to step 2 - no Firebase Auth yet
    // Auth will be done in the final step
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 1);
  }

  // ── Step 2: Username Validation ──────────────────────────────────────────

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < AppConstants.usernameMinLength) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
      });
      return;
    }

    if (!_isValidUsername(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = AppConstants.validationUsernameFormat;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final available =
          await _userService.isUsernameAvailable(username.toLowerCase());
      if (!mounted) return;
      setState(() {
        _isUsernameAvailable = available;
        _usernameError = available ? null : AppConstants.errorUsernameTaken;
      });
    } finally {
      if (mounted) setState(() => _isCheckingUsername = false);
    }
  }

  bool _isValidUsername(String username) {
    if (username.length < AppConstants.usernameMinLength ||
        username.length > AppConstants.usernameMaxLength) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  bool get _isStep2Valid =>
      _usernameController.text.trim().length >= AppConstants.usernameMinLength &&
      _isUsernameAvailable == true &&
      !_isCheckingUsername;

  Future<void> _proceedToStep3() async {
    if (!_isStep2Valid) return;
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 2);
  }

  // ── Step 3: Profile Photo Upload ─────────────────────────────────────────

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

      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$_userId/profile_photo.jpg');

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

  Future<void> _proceedToStep4() async {
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 3);
  }

  // ── Step 4: Complete Registration ────────────────────────────────────────

  Future<void> _completeRegistration() async {
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
      // Step 1: Register in Firebase Auth
      final credential = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (credential.user == null) {
        throw Exception(AppConstants.errorRegisterFailed);
      }

      _userId = credential.user!.uid;

      // Step 2: Create initial Firestore document with onboardingCompleted=false
      await _userService.createUserDocument(
        uid: _userId!,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
      );

      // Step 3: Complete onboarding (sets onboardingCompleted=true)
      await _userService.completeOnboarding(
        uid: _userId!,
        username: _usernameController.text.trim().toLowerCase(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        photoUrl: _uploadedPhotoUrl,
        interests: _selectedInterests.toList(),
      );

      debugPrint('[RegisterPage] Registration complete, onboardingCompleted=true');
      // AppRouter will detect onboardingCompleted=true and navigate to HomePage
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt tamamlanamadı: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            _buildProgressBar(),

            // Header
            _buildHeader(),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Auth(),
                  _buildStep2Username(),
                  _buildStep3Profile(),
                  _buildStep4Interests(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
              'Kayıt Ol',
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

  Widget _buildStep1Auth() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Hesap Oluştur',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tarifleri paylaş, keşfet ve pişir!',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Name
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                hintText: 'Ahmet Yılmaz',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppConstants.validationNameRequired;
                }
                if (value.trim().length < 2) {
                  return AppConstants.validationNameTooShort;
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.validationEmailRequired;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return AppConstants.validationEmailInvalid;
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Şifre',
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.validationPasswordRequired;
                }
                if (value.length < 6) {
                  return AppConstants.validationPasswordTooShort;
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Şifre Tekrar',
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre tekrarı gerekli';
                }
                if (value != _passwordController.text) {
                  return AppConstants.validationPasswordMismatch;
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Terms
            Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) =>
                      setState(() => _acceptedTerms = value ?? false),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _acceptedTerms = !_acceptedTerms),
                    child: Text.rich(
                      TextSpan(
                        text: 'Kullanım ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Koşullarını',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      const _TermsOfServiceModal(),
                                );
                              },
                          ),
                          const TextSpan(text: ' kabul ediyorum'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_isStep1Valid ? null : _proceedToStep2,
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
      ),
    );
  }

  Widget _buildStep2Username() {
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
            onChanged: (value) {
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
              onPressed: _isStep2Valid ? _proceedToStep3 : null,
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

  Widget _buildStep3Profile() {
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
              onPressed: _isUploadingPhoto ? null : _proceedToStep4,
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

  Widget _buildStep4Interests() {
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
          Text(
            'En az ${AppConstants.interestsMinCount}, en fazla ${AppConstants.interestsMaxCount} ilgi alanı seç.',
            style: const TextStyle(
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
                              ? AppColors.divider.withValues(alpha: 0.5)
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
                  : _completeRegistration,
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
                      'Kayıt Ol',
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
