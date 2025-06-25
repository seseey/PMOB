import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class DailyTaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate daily tasks for plant
  Future<void> generateDailyTasksForPlant(
    String userPlantId, {
    DateTime? targetDate,
  }) async {
    try {
      final DateTime taskDate = targetDate ?? DateTime.now();

      // Format tanggal
      final dateStr =
          '${taskDate.year}-${taskDate.month.toString().padLeft(2, '0')}-${taskDate.day.toString().padLeft(2, '0')}';

      // Cek apakah sudah ada tasks untuk tanggal ini
      final existingTasks = await _supabase
          .from('daily_tasks')
          .select('id')
          .eq('user_plant_id', userPlantId)
          .eq('task_date', dateStr);

      // Jika sudah ada tasks, skip generate
      if (existingTasks.isNotEmpty) {
        developer.log('Tasks already exist for $dateStr');
        return;
      }

      // Get plant info
      final plantResponse =
          await _supabase
              .from('user_plants')
              .select('''
          id,
          plant_type_id,
          planting_date,
          plant_types!inner(
            id,
            name,
            category,
            growth_duration
          )
        ''')
              .eq('id', userPlantId)
              .single();

      // Fixed: Remove unnecessary null comparison
      final plantingDate = DateTime.parse(plantResponse['planting_date']);
      final daysSincePlanting = taskDate.difference(plantingDate).inDays;
      final plantTypeId = plantResponse['plant_type_id'];

      // Get tasks template based on plant type and growth stage
      final tasksResponse = await _supabase
          .from('task_templates')
          .select('*')
          .eq('plant_type_id', plantTypeId)
          .lte('start_day', daysSincePlanting)
          .gte('end_day', daysSincePlanting)
          .order('priority');

      final taskTemplates = List<Map<String, dynamic>>.from(tasksResponse);

      if (taskTemplates.isEmpty) {
        developer.log('No task templates found for day $daysSincePlanting');
        return;
      }

      // Generate daily tasks
      final tasksToInsert = <Map<String, dynamic>>[];

      for (final template in taskTemplates) {
        tasksToInsert.add({
          'id': const Uuid().v4(),
          'user_plant_id': userPlantId,
          'task_template_id': template['id'],
          'task_name': template['task_name'],
          'task_description': template['description'],
          'task_type': template['task_type'],
          'task_date': dateStr,
          'priority': template['priority'],
          'estimated_duration': template['estimated_duration'],
          'is_completed': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Insert tasks
      if (tasksToInsert.isNotEmpty) {
        await _supabase.from('daily_tasks').insert(tasksToInsert);
        developer.log('Generated ${tasksToInsert.length} tasks for $dateStr');
      }

      // Generate accuracy checks if needed
      await _generateAccuracyChecksForDate(userPlantId, taskDate, plantTypeId);
    } catch (e) {
      developer.log('Error generating daily tasks: $e');
      throw Exception('Failed to generate daily tasks: $e');
    }
  }

  // Tambahkan method untuk generate accuracy checks
  Future<void> _generateAccuracyChecksForDate(
    String userPlantId,
    DateTime targetDate,
    int plantTypeId,
  ) async {
    try {
      final dateStr =
          '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      // Cek apakah sudah ada accuracy checks untuk tanggal ini
      final existingChecks = await _supabase
          .from('accuracy_checks')
          .select('id')
          .eq('user_plant_id', userPlantId)
          .eq('check_date', dateStr);

      if (existingChecks.isNotEmpty) {
        developer.log('Accuracy checks already exist for $dateStr');
        return;
      }

      // Get accuracy check templates
      final checksResponse = await _supabase
          .from('accuracy_check_templates')
          .select('*')
          .eq('plant_type_id', plantTypeId)
          .order('priority');

      final checkTemplates = List<Map<String, dynamic>>.from(checksResponse);

      if (checkTemplates.isEmpty) {
        developer.log('No accuracy check templates found');
        return;
      }

      // Generate accuracy checks (biasanya 1-3 per hari)
      final checksToInsert = <Map<String, dynamic>>[];

      for (final template in checkTemplates.take(2)) {
        // Ambil maksimal 2 checks per hari
        checksToInsert.add({
          'id': const Uuid().v4(),
          'user_plant_id': userPlantId,
          'check_name': template['check_name'],
          'check_description': template['description'],
          'check_type': template['check_type'],
          'check_date': dateStr,
          'is_completed': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Insert accuracy checks
      if (checksToInsert.isNotEmpty) {
        await _supabase.from('accuracy_checks').insert(checksToInsert);
        developer.log(
          'Generated ${checksToInsert.length} accuracy checks for $dateStr',
        );
      }
    } catch (e) {
      developer.log('Error generating accuracy checks: $e');
    }
  }

  /// Get daily tasks for user plant
  Future<List<Map<String, dynamic>>> getDailyTasksForPlant(
    String userPlantId, {
    DateTime? date,
  }) async {
    try {
      var query = _supabase
          .from('daily_tasks_view')
          .select()
          .eq('user_plant_id', userPlantId);

      if (date != null) {
        query = query.eq('task_date', date.toIso8601String().split('T')[0]);
      }

      final response = await query.order('task_date');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting daily tasks: $e');
    }
  }

  /// Complete daily task
  Future<Map<String, dynamic>> completeTask({
    required String taskId,
    String? notes,
  }) async {
    try {
      final response =
          await _supabase
              .from('daily_tasks')
              .update({
                'is_completed': true,
                'completed_at': DateTime.now().toIso8601String(),
                'notes': notes,
              })
              .eq('id', taskId)
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error completing task: $e');
    }
  }

  // In your DailyTaskService class, update the getTodayTasksForUser method:

  Future<List<Map<String, dynamic>>> getTodayTasksForUser(String userId) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Option 1: If your view has user_plant_id, join with user_plants table
      final response = await _supabase
          .from('daily_tasks_view')
          .select('''
          *,
          user_plants!inner(user_id)
        ''')
          .eq('user_plants.user_id', userId)
          .eq('task_date', dateStr);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting today tasks: $e');
    }
  }

  // Alternative Option 2: Query the base daily_tasks table instead of the view
  Future<List<Map<String, dynamic>>> getTodayTasksForUserAlternative(
    String userId,
  ) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_tasks')
          .select('''
          *,
          user_plants!inner(
            id,
            user_id,
            plant_name,
            plant_types(name)
          )
        ''')
          .eq('user_plants.user_id', userId)
          .eq('task_date', dateStr)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting today tasks: $e');
    }
  }
}
