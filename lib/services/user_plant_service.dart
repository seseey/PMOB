import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer; // Import logging framework

class UserPlantService {
  static final SupabaseClient _supabase =
      Supabase.instance.client; // Fixed: Made final

  Future<Map<String, dynamic>> startPlanting({
    required String id,
    required String userId,
    required String plantTypeId,
    String? plantName,
    required DateTime startDate,
  }) async {
    try {
      // Get plant type to calculate expected harvest date
      final plantType =
          await _supabase
              .from('plant_types')
              .select('growing_days')
              .eq('id', plantTypeId)
              .single();

      final expectedHarvestDate = startDate.add(
        Duration(days: plantType['growing_days']),
      );

      final response =
          await _supabase
              .from('user_plants')
              .insert({
                'id': id,
                'user_id': userId,
                'plant_type_id': plantTypeId,
                'plant_name': plantName,
                'start_date': startDate.toIso8601String().split('T')[0],
                'expected_harvest_date':
                    expectedHarvestDate.toIso8601String().split('T')[0],
                'status': 'planting',
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error starting plant: $e');
    }
  }

  /// Get user plants
  Future<List<Map<String, dynamic>>> getUserPlants(
    String userId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('user_plants')
          .select('''
            *,
            plant_types(name, description, growing_days, image_url)
          ''')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting user plants: $e');
    }
  }

  /// Update plant status to harvested
  Future<Map<String, dynamic>> harvestPlant({
    required String plantId,
    required DateTime actualHarvestDate,
    String? harvestNotes,
    double? totalHarvestWeight,
    String? harvestQuality,
  }) async {
    try {
      final response =
          await _supabase
              .from('user_plants')
              .update({
                'actual_harvest_date':
                    actualHarvestDate.toIso8601String().split('T')[0],
                'status': 'harvested',
                'harvest_notes': harvestNotes,
                'total_harvest_weight': totalHarvestWeight,
                'harvest_quality': harvestQuality,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', plantId)
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error harvesting plant: $e');
    }
  }

  /// Update plant status to failed
  Future<Map<String, dynamic>> markPlantAsFailed({
    required String plantId,
    String? notes,
  }) async {
    try {
      final response =
          await _supabase
              .from('user_plants')
              .update({
                'status': 'failed',
                'harvest_notes': notes,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', plantId)
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error marking plant as failed: $e');
    }
  }

  /// Get plant history view
  Future<List<Map<String, dynamic>>> getPlantingHistoryView(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('planting_history_view')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting planting history: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserPlantById(
    String userPlantId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      developer.log(
        'Querying user_plants table for ID: $userPlantId',
      ); // Fixed: Use logging framework

      final response = await supabase
          .from('user_plants')
          .select()
          .eq('id', userPlantId)
          .limit(1);

      if (response.isNotEmpty) {
        developer.log(
          'Found plant: ${response.first}',
        ); // Fixed: Use logging framework
        return response.first; // Fixed: Removed unnecessary cast
      } else {
        developer.log(
          'No plant found with ID: $userPlantId',
        ); // Fixed: Use logging framework

        // Debug: Check if there are any plants in the table
        final allPlants = await supabase.from('user_plants').select().limit(5);
        developer.log(
          'Available plants in database: $allPlants',
        ); // Fixed: Use logging framework
      }

      return null;
    } catch (e) {
      developer.log(
        'Error getting user plant by ID: $e',
      ); // Fixed: Use logging framework
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUserPlants(String userId) async {
    try {
      final response = await _supabase
          .from('user_plants')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      developer.log(
        'Found ${response.length} plants for user $userId',
      ); // Fixed: Use logging framework
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log(
        'Error getting all user plants: $e',
      ); // Fixed: Use logging framework
      return [];
    }
  }

  Future<String?> getActivePlantId(String userId) async {
    try {
      final response = await _supabase
          .from('user_plants')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'planting')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['id'] as String;
      }

      return null;
    } catch (e) {
      developer.log(
        'Error getting active plant ID: $e',
      ); // Fixed: Use logging framework
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getActivePlants(String userId) async {
    try {
      final response = await _supabase
          .from('user_plants')
          .select()
          .eq('user_id', userId)
          .eq('status', 'planting')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log(
        'Error getting active plants: $e',
      ); // Fixed: Use logging framework
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPlantsByName(
    String userId,
    String plantName,
  ) async {
    try {
      final response = await _supabase
          .from('user_plants')
          .select()
          .eq('user_id', userId)
          .ilike('plant_name', '%$plantName%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log(
        'Error getting plants by name: $e',
      ); // Fixed: Use logging framework
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestUserPlant(String userId) async {
    try {
      final response = await _supabase
          .from('user_plants')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first; // Fixed: Removed unnecessary cast
      }

      return null;
    } catch (e) {
      developer.log(
        'Error getting latest user plant: $e',
      ); // Fixed: Use logging framework
      return null;
    }
  }

  Future<bool> testConnection() async {
    try {
      await _supabase // Fixed: Removed unused variable
          .from('user_plants')
          .select('count')
          .limit(1);

      developer.log(
        'Database connection test successful',
      ); // Fixed: Use logging framework
      return true;
    } catch (e) {
      developer.log(
        'Database connection test failed: $e',
      ); // Fixed: Use logging framework
      return false;
    }
  }
}
