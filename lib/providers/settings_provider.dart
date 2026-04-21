import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium Settings Provider
/// Manages notification settings, content preferences, and privacy settings
class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  
  // Notification Settings
  bool _likesNotifications = true;
  bool _commentsNotifications = true;
  bool _followersNotifications = true;
  
  // Content Preferences
  String _dietType = 'none'; // none, vegan, vegetarian, keto
  String _difficultyFilter = 'all'; // all, easy, medium, hard
  int _maxCookingTime = 120; // minutes
  
  // Privacy Settings
  bool _privateAccount = false;
  String _profileVisibility = 'everyone'; // everyone, followers, following
  bool _followRequestApproval = false;
  
  bool _isInitialized = false;

  // Getters
  bool get likesNotifications => _likesNotifications;
  bool get commentsNotifications => _commentsNotifications;
  bool get followersNotifications => _followersNotifications;
  
  String get dietType => _dietType;
  String get difficultyFilter => _difficultyFilter;
  int get maxCookingTime => _maxCookingTime;
  
  bool get privateAccount => _privateAccount;
  String get profileVisibility => _profileVisibility;
  bool get followRequestApproval => _followRequestApproval;
  
  bool get isInitialized => _isInitialized;

  /// Initialize settings from SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    // Load notification settings
    _likesNotifications = _prefs?.getBool('likes_notifications') ?? true;
    _commentsNotifications = _prefs?.getBool('comments_notifications') ?? true;
    _followersNotifications = _prefs?.getBool('followers_notifications') ?? true;
    
    // Load content preferences
    _dietType = _prefs?.getString('diet_type') ?? 'none';
    _difficultyFilter = _prefs?.getString('difficulty_filter') ?? 'all';
    _maxCookingTime = _prefs?.getInt('max_cooking_time') ?? 120;
    
    // Load privacy settings
    _privateAccount = _prefs?.getBool('private_account') ?? false;
    _profileVisibility = _prefs?.getString('profile_visibility') ?? 'everyone';
    _followRequestApproval = _prefs?.getBool('follow_request_approval') ?? false;
    
    _isInitialized = true;
    notifyListeners();
  }

  // Notification Settings Methods
  Future<void> setLikesNotifications(bool value) async {
    _likesNotifications = value;
    await _prefs?.setBool('likes_notifications', value);
    notifyListeners();
  }

  Future<void> setCommentsNotifications(bool value) async {
    _commentsNotifications = value;
    await _prefs?.setBool('comments_notifications', value);
    notifyListeners();
  }

  Future<void> setFollowersNotifications(bool value) async {
    _followersNotifications = value;
    await _prefs?.setBool('followers_notifications', value);
    notifyListeners();
  }

  // Content Preferences Methods
  Future<void> setDietType(String value) async {
    _dietType = value;
    await _prefs?.setString('diet_type', value);
    notifyListeners();
  }

  Future<void> setDifficultyFilter(String value) async {
    _difficultyFilter = value;
    await _prefs?.setString('difficulty_filter', value);
    notifyListeners();
  }

  Future<void> setMaxCookingTime(int value) async {
    _maxCookingTime = value;
    await _prefs?.setInt('max_cooking_time', value);
    notifyListeners();
  }

  // Privacy Settings Methods
  Future<void> setPrivateAccount(bool value) async {
    _privateAccount = value;
    await _prefs?.setBool('private_account', value);
    notifyListeners();
  }

  Future<void> setProfileVisibility(String value) async {
    _profileVisibility = value;
    await _prefs?.setString('profile_visibility', value);
    notifyListeners();
  }

  Future<void> setFollowRequestApproval(bool value) async {
    _followRequestApproval = value;
    await _prefs?.setBool('follow_request_approval', value);
    notifyListeners();
  }

  /// Clear all settings (for logout)
  Future<void> clear() async {
    await _prefs?.clear();
    
    _likesNotifications = true;
    _commentsNotifications = true;
    _followersNotifications = true;
    
    _dietType = 'none';
    _difficultyFilter = 'all';
    _maxCookingTime = 120;
    
    _privateAccount = false;
    _profileVisibility = 'everyone';
    _followRequestApproval = false;
    
    notifyListeners();
  }
}
