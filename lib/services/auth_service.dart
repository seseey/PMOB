import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up user
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Error in signUp: $e');
      rethrow;
    }
  }

  // Sign in user
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Error in signIn: $e');
      rethrow;
    }
  }

  // Create user profile in database
  Future<void> createUserProfile({
    required String userId,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.from('users').insert({
        'id': userId,
        'username': username,
        'email': email,
        'password_hash': password, // Sesuaikan dengan nama kolom di database
        'theme_preference': 'light',
        'profile_photo': null,
        // created_at dan updated_at akan otomatis terisi karena DEFAULT CURRENT_TIMESTAMP
      });

      print('User profile created successfully for: $username');
    } catch (e) {
      print('Error in createUserProfile: $e');
      rethrow;
    }
  }

  // Check if username already exists
  Future<bool> isUsernameExists(String username) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('username')
              .eq('username', username)
              .maybeSingle(); // Gunakan maybeSingle() untuk menghindari error jika tidak ada data

      return response != null;
    } catch (e) {
      print('Error checking username: $e');
      return false; // Return false jika ada error, biar bisa lanjut proses
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update username
  Future<void> updateUsername(String userId, String newUsername) async {
    try {
      await _supabase
          .from('users')
          .update({
            'username': newUsername,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('Username updated successfully');
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    }
  }

  // Update profile photo
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    try {
      await _supabase
          .from('users')
          .update({
            'profile_photo': photoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('Profile photo updated successfully');
    } catch (e) {
      print('Error updating profile photo: $e');
      rethrow;
    }
  }

  // Update theme preference
  Future<void> updateThemePreference(String userId, String theme) async {
    try {
      await _supabase
          .from('users')
          .update({
            'theme_preference': theme,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('Theme preference updated successfully');
    } catch (e) {
      print('Error updating theme preference: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
