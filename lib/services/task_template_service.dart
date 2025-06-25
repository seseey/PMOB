import 'package:supabase_flutter/supabase_flutter.dart';

class TaskTemplateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get task templates for plant type
  Future<List<Map<String, dynamic>>> getTaskTemplatesForPlantType(
    String plantTypeId,
  ) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select()
          .eq('plant_type_id', plantTypeId)
          .order('day_number');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting task templates: $e');
    }
  }

  /// Add new task template (admin function)
  Future<Map<String, dynamic>> addTaskTemplate({
    required String id,
    required String plantTypeId,
    required String taskName,
    String? taskDescription,
    required int dayNumber,
    bool isDaily = false,
  }) async {
    try {
      final response =
          await _supabase
              .from('task_templates')
              .insert({
                'id': id,
                'plant_type_id': plantTypeId,
                'task_name': taskName,
                'task_description': taskDescription,
                'day_number': dayNumber,
                'is_daily': isDaily,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error adding task template: $e');
    }
  }
}
