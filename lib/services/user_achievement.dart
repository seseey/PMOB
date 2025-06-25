import 'package:supabase_flutter/supabase_flutter.dart';

class UserAchievementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add user achievement
  Future<Map<String, dynamic>> addUserAchievement({
    required String id,
    required String userId,
    required String achievementType,
    required String achievementName,
    String? achievementDescription,
    required DateTime achievedDate,
    String? badgeIcon,
  }) async {
    try {
      final response =
          await _supabase
              .from('user_achievements')
              .insert({
                'id': id,
                'user_id': userId,
                'achievement_type': achievementType,
                'achievement_name': achievementName,
                'achievement_description': achievementDescription,
                'achieved_date': achievedDate.toIso8601String().split('T')[0],
                'badge_icon': badgeIcon,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error adding user achievement: $e');
    }
  }

  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('achieved_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting user achievements: $e');
    }
  }

  /// Check and award achievements
  Future<List<Map<String, dynamic>>> checkAndAwardAchievements(
    String userId,
  ) async {
    try {
      List<Map<String, dynamic>> newAchievements = [];

      // Get user statistics
      final stats =
          await _supabase
              .from('user_statistics_view')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (stats == null) return newAchievements;

      // Get existing achievements to avoid duplicates
      final existingAchievements = await _supabase
          .from('user_achievements')
          .select('achievement_type')
          .eq('user_id', userId);

      final existingTypes =
          existingAchievements.map((a) => a['achievement_type']).toSet();

      // Check for first plant achievement
      if (stats['total_plants_grown'] >= 1 &&
          !existingTypes.contains('first_plant')) {
        final achievement = await addUserAchievement(
          id: 'ach_${userId}_first_plant',
          userId: userId,
          achievementType: 'first_plant',
          achievementName: 'Petani Pemula',
          achievementDescription: 'Menanam tanaman pertama',
          achievedDate: DateTime.now(),
          badgeIcon: 'first_plant.png',
        );
        newAchievements.add(achievement);
      }

      // Check for first harvest achievement
      if (stats['total_successful_harvests'] >= 1 &&
          !existingTypes.contains('first_harvest')) {
        final achievement = await addUserAchievement(
          id: 'ach_${userId}_first_harvest',
          userId: userId,
          achievementType: 'first_harvest',
          achievementName: 'Panen Pertama',
          achievementDescription: 'Berhasil memanen tanaman pertama',
          achievedDate: DateTime.now(),
          badgeIcon: 'first_harvest.png',
        );
        newAchievements.add(achievement);
      }

      // Check for master gardener achievement (5 successful harvests)
      if (stats['total_successful_harvests'] >= 5 &&
          !existingTypes.contains('master_gardener')) {
        final achievement = await addUserAchievement(
          id: 'ach_${userId}_master_gardener',
          userId: userId,
          achievementType: 'master_gardener',
          achievementName: 'Tukang Kebun Ahli',
          achievementDescription: 'Berhasil memanen 5 tanaman',
          achievedDate: DateTime.now(),
          badgeIcon: 'master_gardener.png',
        );
        newAchievements.add(achievement);
      }

      // Check for high success rate achievement (80% success rate with min 3 plants)
      if (stats['success_rate'] >= 80.0 &&
          stats['total_plants_grown'] >= 3 &&
          !existingTypes.contains('high_success_rate')) {
        final achievement = await addUserAchievement(
          id: 'ach_${userId}_high_success',
          userId: userId,
          achievementType: 'high_success_rate',
          achievementName: 'Petani Sukses',
          achievementDescription: 'Mencapai tingkat keberhasilan 80%',
          achievedDate: DateTime.now(),
          badgeIcon: 'high_success.png',
        );
        newAchievements.add(achievement);
      }

      return newAchievements;
    } catch (e) {
      throw Exception('Error checking achievements: $e');
    }
  }
}
