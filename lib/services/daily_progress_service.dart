import 'package:supabase_flutter/supabase_flutter.dart';

class DailyProgressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Update daily progress
  Future<Map<String, dynamic>> updateDailyProgress({
    required String id,
    required String userPlantId,
    required DateTime progressDate,
    int totalTasks = 0,
    int completedTasks = 0,
    int totalAccuracyChecks = 0,
    int completedAccuracyChecks = 0,
    int overallCompletionPercentage = 0,
    String? notes,
    List<String>? photos,
  }) async {
    try {
      final response =
          await _supabase
              .from('daily_progress')
              .upsert({
                'id': id,
                'user_plant_id': userPlantId,
                'progress_date': progressDate.toIso8601String().split('T')[0],
                'total_tasks': totalTasks,
                'completed_tasks': completedTasks,
                'total_accuracy_checks': totalAccuracyChecks,
                'completed_accuracy_checks': completedAccuracyChecks,
                'overall_completion_percentage': overallCompletionPercentage,
                'notes': notes,
                'photos': photos != null ? photos.join(',') : null,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error updating daily progress: $e');
    }
  }

  /// Get daily progress for plant
  Future<List<Map<String, dynamic>>> getDailyProgressForPlant(
    String userPlantId,
  ) async {
    try {
      final response = await _supabase
          .from('daily_progress_view')
          .select()
          .eq('user_plant_id', userPlantId)
          .order('progress_date');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting daily progress: $e');
    }
  }
}
