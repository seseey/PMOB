import 'package:supabase_flutter/supabase_flutter.dart';

class PlantingHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add planting history record
  Future<Map<String, dynamic>> addPlantingHistory({
    required String id,
    required String userPlantId,
    required String actionType,
    required DateTime actionDate,
    String? description,
    String? additionalData,
  }) async {
    try {
      final response =
          await _supabase
              .from('planting_history')
              .insert({
                'id': id,
                'user_plant_id': userPlantId,
                'action_type': actionType,
                'action_date': actionDate.toIso8601String().split('T')[0],
                'description': description,
                'additional_data': additionalData,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error adding planting history: $e');
    }
  }

  /// Get planting history for plant
  Future<List<Map<String, dynamic>>> getPlantingHistoryForPlant(
    String userPlantId,
  ) async {
    try {
      final response = await _supabase
          .from('planting_history')
          .select()
          .eq('user_plant_id', userPlantId)
          .order('action_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting planting history: $e');
    }
  }
}
