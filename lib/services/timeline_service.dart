import 'package:supabase_flutter/supabase_flutter.dart';

class TimelineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all timeline data in one efficient call
  Future<Map<String, dynamic>> getTimelineData(String userPlantId) async {
    try {
      // PERBAIKAN: Ganti 'plants' menjadi 'plant_types' sesuai schema
      final response =
          await _supabase
              .from('user_plants')
              .select('''
            *,
            plant_types!inner(
              name,
              growing_days
            )
          ''')
              .eq('id', userPlantId)
              .single();

      // Get daily progress data in parallel
      final progressFuture = _supabase
          .from('daily_progress')
          .select('*')
          .eq('user_plant_id', userPlantId)
          .order('progress_date');

      final progressData = await progressFuture;

      return {'userPlant': response, 'dailyProgress': progressData};
    } catch (e) {
      print('Error in getTimelineData: $e');
      rethrow;
    }
  }

  // Get user plants summary for dropdown (minimal data)
  Future<List<Map<String, dynamic>>> getUserPlantsForTimeline(
    String userId,
  ) async {
    try {
      // PERBAIKAN: Ganti 'plants' menjadi 'plant_types' sesuai schema
      final response = await _supabase
          .from('user_plants')
          .select('''
            id,
            plant_name,
            start_date,
            status,
            expected_harvest_date,
            actual_harvest_date,
            plant_types!inner(name)
          ''')
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user plants for timeline: $e');
      return [];
    }
  }

  // Get most recent active plant
  Future<String?> getMostRecentActivePlant(String userId) async {
    try {
      final response =
          await _supabase
              .from('user_plants')
              .select('id')
              .eq('user_id', userId)
              .eq('status', 'planting')
              .order('start_date', ascending: false)
              .limit(1)
              .maybeSingle();

      return response?['id'];
    } catch (e) {
      print('Error getting most recent active plant: $e');
      return null;
    }
  }

  // Calculate timeline metrics efficiently
  Map<String, dynamic> calculateTimelineMetrics(
    Map<String, dynamic> userPlant,
    List<Map<String, dynamic>> dailyProgress,
  ) {
    try {
      final startDate = DateTime.parse(userPlant['start_date']);
      final status = userPlant['status'] ?? 'planting';

      // PERBAIKAN: Sesuaikan dengan struktur plant_types
      int totalDays = 30; // default
      if (userPlant['expected_harvest_date'] != null) {
        final harvestDate = DateTime.parse(userPlant['expected_harvest_date']);
        totalDays = harvestDate.difference(startDate).inDays + 1;
      } else if (userPlant['plant_types'] != null &&
          userPlant['plant_types']['growing_days'] != null) {
        totalDays = userPlant['plant_types']['growing_days'];
      }

      // Calculate current day
      final today = DateTime.now();
      int currentDay = today.difference(startDate).inDays + 1;

      // Adjust for completed plants
      if (status != 'planting' && currentDay > totalDays) {
        currentDay = totalDays;
      }

      // Create progress map for quick access
      final Map<int, Map<String, dynamic>> progressMap = {};
      for (var progress in dailyProgress) {
        try {
          final progressDate = DateTime.parse(progress['progress_date']);
          final dayNumber = progressDate.difference(startDate).inDays + 1;
          progressMap[dayNumber] = progress;
        } catch (e) {
          print('Error parsing progress date: $e');
          continue;
        }
      }

      return {
        'startDate': startDate,
        'currentDay': currentDay,
        'totalDays': totalDays,
        'status': status,
        'progressMap': progressMap,
        // PERBAIKAN: Sesuaikan dengan struktur plant_types
        'plantName': userPlant['plant_types']?['name'] ?? 'Tanaman',
        'expectedHarvestDate': userPlant['expected_harvest_date'],
      };
    } catch (e) {
      print('Error calculating timeline metrics: $e');
      // Return safe defaults
      return {
        'startDate': DateTime.now(),
        'currentDay': 1,
        'totalDays': 30,
        'status': 'planting',
        'progressMap': <int, Map<String, dynamic>>{},
        'plantName': 'Tanaman',
        'expectedHarvestDate': null,
      };
    }
  }

  // Get current user ID safely
  Future<String?> getCurrentUserId() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      return currentUser?.id;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }
}
