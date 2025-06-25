import 'package:supabase_flutter/supabase_flutter.dart';

class SearchFilterService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Search plants by name or type
  Future<List<Map<String, dynamic>>> searchUserPlants({
    required String userId,
    String? searchQuery,
    String? status,
    String? plantTypeId,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _supabase
          .from('user_plants')
          .select('''
            *,
            plant_types(name, description, growing_days, image_url)
          ''')
          .eq('user_id', userId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'plant_name.ilike.%$searchQuery%,plant_types.name.ilike.%$searchQuery%',
        );
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (plantTypeId != null) {
        query = query.eq('plant_type_id', plantTypeId);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error searching plants: $e');
    }
  }

  /// Get plants by date range
  Future<List<Map<String, dynamic>>> getPlantsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('user_plants')
          .select('''
            *,
            plant_types(name, description, growing_days, image_url)
          ''')
          .eq('user_id', userId)
          .gte('start_date', startDate.toIso8601String().split('T')[0])
          .lte('start_date', endDate.toIso8601String().split('T')[0]);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('start_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting plants by date range: $e');
    }
  }

  /// Get upcoming harvests
  Future<List<Map<String, dynamic>>> getUpcomingHarvests({
    required String userId,
    int daysAhead = 7,
  }) async {
    try {
      final today = DateTime.now();
      final endDate = today.add(Duration(days: daysAhead));

      final response = await _supabase
          .from('user_plants')
          .select('''
            *,
            plant_types(name, description, growing_days, image_url)
          ''')
          .eq('user_id', userId)
          .eq('status', 'planting')
          .gte('expected_harvest_date', today.toIso8601String().split('T')[0])
          .lte('expected_harvest_date', endDate.toIso8601String().split('T')[0])
          .order('expected_harvest_date');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting upcoming harvests: $e');
    }
  }
}
