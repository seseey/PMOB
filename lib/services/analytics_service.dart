import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get monthly planting statistics
  Future<List<Map<String, dynamic>>> getMonthlyPlantingStats(
    String userId,
    int year,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_monthly_planting_stats',
        params: {'user_id_param': userId, 'year_param': year},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback query if RPC function doesn't exist
      final response = await _supabase
          .from('user_plants')
          .select('start_date, status')
          .eq('user_id', userId)
          .gte('start_date', '$year-01-01')
          .lte('start_date', '$year-12-31');

      // Group by month manually
      Map<int, Map<String, int>> monthlyStats = {};

      for (var plant in response) {
        final date = DateTime.parse(plant['start_date']);
        final month = date.month;

        monthlyStats[month] ??= {
          'total': 0,
          'harvested': 0,
          'failed': 0,
          'planting': 0,
        };

        monthlyStats[month]!['total'] = monthlyStats[month]!['total']! + 1;
        monthlyStats[month]![plant['status']] =
            (monthlyStats[month]![plant['status']] ?? 0) + 1;
      }

      return monthlyStats.entries
          .map((entry) => {'month': entry.key, ...entry.value})
          .toList();
    }
  }

  /// Get plant type popularity
  Future<List<Map<String, dynamic>>> getPlantTypePopularity(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('user_plants')
          .select('''
            plant_type_id,
            plant_types(name, image_url)
          ''')
          .eq('user_id', userId);

      // Group by plant type
      Map<String, Map<String, dynamic>> typeStats = {};

      for (var plant in response) {
        final typeId = plant['plant_type_id'];
        final typeName = plant['plant_types']['name'];
        final imageUrl = plant['plant_types']['image_url'];

        typeStats[typeId] ??= {
          'plant_type_id': typeId,
          'name': typeName,
          'image_url': imageUrl,
          'count': 0,
        };

        typeStats[typeId]!['count'] = typeStats[typeId]!['count'] + 1;
      }

      final result = typeStats.values.toList();
      result.sort((a, b) => b['count'].compareTo(a['count']));

      return result;
    } catch (e) {
      throw Exception('Error getting plant type popularity: $e');
    }
  }

  /// Get success rate by plant type
  Future<List<Map<String, dynamic>>> getSuccessRateByPlantType(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('user_plants')
          .select('''
            plant_type_id,
            status,
            plant_types(name, image_url)
          ''')
          .eq('user_id', userId)
          .neq('status', 'planting');

      // Group by plant type and calculate success rate
      Map<String, Map<String, dynamic>> typeStats = {};

      for (var plant in response) {
        final typeId = plant['plant_type_id'];
        final typeName = plant['plant_types']['name'];
        final imageUrl = plant['plant_types']['image_url'];
        final status = plant['status'];

        typeStats[typeId] ??= {
          'plant_type_id': typeId,
          'name': typeName,
          'image_url': imageUrl,
          'total': 0,
          'harvested': 0,
          'failed': 0,
          'success_rate': 0.0,
        };

        typeStats[typeId]!['total'] = typeStats[typeId]!['total'] + 1;
        typeStats[typeId]![status] = (typeStats[typeId]![status] ?? 0) + 1;
      }

      // Calculate success rates
      for (var stats in typeStats.values) {
        final total = stats['total'];
        final harvested = stats['harvested'];
        stats['success_rate'] = total > 0 ? (harvested / total) * 100 : 0.0;
      }

      final result = typeStats.values.toList();
      result.sort((a, b) => b['success_rate'].compareTo(a['success_rate']));

      return result;
    } catch (e) {
      throw Exception('Error getting success rate by plant type: $e');
    }
  }

  /// Get task completion rate
  Future<Map<String, dynamic>> getTaskCompletionRate(
    String userId, {
    int? days,
  }) async {
    try {
      var query = _supabase
          .from('daily_tasks_view')
          .select('is_completed')
          .eq('user_id', userId);

      if (days != null) {
        final startDate = DateTime.now().subtract(Duration(days: days));
        query = query.gte(
          'task_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      final response = await query;

      int total = response.length;
      int completed =
          response.where((task) => task['is_completed'] == true).length;
      double completionRate = total > 0 ? (completed / total) * 100 : 0.0;

      return {
        'total_tasks': total,
        'completed_tasks': completed,
        'completion_rate': completionRate,
      };
    } catch (e) {
      throw Exception('Error getting task completion rate: $e');
    }
  }
}
