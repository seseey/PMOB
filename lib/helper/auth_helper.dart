import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthHelper {
  static const String _userIdKey = 'current_user_id';
  static const String _userNameKey = 'current_user_name';
  static final SupabaseClient _supabase = Supabase.instance.client;

  // **GET CURRENT USER ID dari Supabase Auth**
  static Future<String?> getCurrentUserId() async {
    try {
      // Method 1: Dari Supabase Auth
      final user = _supabase.auth.currentUser;
      if (user != null) {
        debugPrint('Current user ID from Supabase auth: ${user.id}');
        return user.id;
      }

      // Method 2: Dari SharedPreferences sebagai fallback
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      debugPrint('Current user ID from storage: $userId');
      return userId;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // **GET CURRENT USER EMAIL dari Supabase**
  static Future<String?> getCurrentUserEmail() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return user.email;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user email: $e');
      return null;
    }
  }

  // **SET CURRENT USER ID (saat login manual)**
  static Future<void> setCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      debugPrint('User ID saved: $userId');
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  // **GET CURRENT USER NAME**
  static Future<String?> getCurrentUserName() async {
    try {
      // Method 1: Dari Supabase user metadata
      final user = _supabase.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final name =
            user.userMetadata!['name'] ?? user.userMetadata!['full_name'];
        if (name != null) return name;
      }

      // Method 2: Dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      debugPrint('Error getting current user name: $e');
      return null;
    }
  }

  // **SET CURRENT USER NAME**
  static Future<void> setCurrentUserName(String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, userName);
    } catch (e) {
      debugPrint('Error saving user name: $e');
    }
  }

  // **CLEAR USER DATA (saat logout)**
  static Future<void> clearUserData() async {
    try {
      // Logout dari Supabase
      await _supabase.auth.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      debugPrint('User data cleared');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  // **CHECK IF USER IS LOGGED IN**
  static Future<bool> isUserLoggedIn() async {
    try {
      // Check Supabase auth first
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return true;
      }

      // Fallback to SharedPreferences
      final userId = await getCurrentUserId();
      return userId != null && userId.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // **GET CURRENT USER INFO**
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return {
          'id': user.id,
          'email': user.email,
          'created_at': user.createdAt,
          'metadata': user.userMetadata,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user info: $e');
      return null;
    }
  }
}
