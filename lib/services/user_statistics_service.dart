import 'package:supabase_flutter/supabase_flutter.dart';

class UserStatisticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user statistics
  Future<Map<String, dynamic>?> getUserStatistics(String userId) async {
    try {
      final response =
          await _supabase
              .from('user_statistics_view')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error getting user statistics: $e');
    }
  }

  /// Update favorite plant type
  Future<Map<String, dynamic>> updateFavoritePlantType({
    required String userId,
    required String favoritePlantTypeId,
  }) async {
    try {
      final response =
          await _supabase
              .from('user_statistics')
              .upsert({
                'user_id': userId,
                'favorite_plant_type_id': favoritePlantTypeId,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error updating favorite plant type: $e');
    }
  }
}
