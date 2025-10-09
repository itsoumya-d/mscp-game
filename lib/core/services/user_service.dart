import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for managing user identification across the application
class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  
  UserService._();

  static const String _userIdKey = 'current_user_id';
  static const String _defaultUserId = 'user_123';
  
  String? _cachedUserId;

  /// Gets the current user ID, creating one if it doesn't exist
  Future<String> getCurrentUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);
    
    if (userId == null || userId.isEmpty) {
      // Create a new user ID if none exists
      userId = _defaultUserId;
      await prefs.setString(_userIdKey, userId);
    }
    
    _cachedUserId = userId;
    return userId;
  }

  /// Sets a new user ID (for future auth integration)
  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    _cachedUserId = userId;
  }

  /// Clears the current user ID (for logout)
  Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    _cachedUserId = null;
  }

  /// Gets the cached user ID without async call (returns null if not loaded)
  String? getCachedUserId() {
    return _cachedUserId;
  }
}