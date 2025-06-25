import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fungsi upload file ke Supabase Storage dan update DB
  Future<Map<String, dynamic>> registerUser({
    required String id,
    required String username,
    required String email,
    required String passwordHash,
    String? profilePhoto,
    String themePreference = 'light',
  }) async {
    try {
      final response =
          await _supabase
              .from('users')
              .insert({
                'id': id,
                'username': username,
                'email': email,
                'profile_photo': profilePhoto,
                'theme_preference': themePreference,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select()
              .eq('username', username)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error getting user by username: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? username,
    String? email,
    String? profilePhoto,
    String? themePreference,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (profilePhoto != null) updateData['profile_photo'] = profilePhoto;
      if (themePreference != null)
        updateData['theme_preference'] = themePreference;

      final response =
          await _supabase
              .from('users')
              .update(updateData)
              .eq('id', userId)
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  Future<String> uploadProfilePhoto(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileName =
          'profile_$userId.${extension(filePath).replaceFirst('.', '')}';

      await _supabase.storage.from('profiles').upload('photos/$fileName', file);

      final publicUrl = _supabase.storage
          .from('profiles')
          .getPublicUrl('photos/$fileName');

      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading profile photo: $e');
    }
  }
}
