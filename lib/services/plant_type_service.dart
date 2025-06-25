import 'package:supabase_flutter/supabase_flutter.dart';

class PlantService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get semua jenis tanaman
  Future<List<Map<String, dynamic>>> getAllPlantTypes() async {
    try {
      final response = await _supabase
          .from('plant_types')
          .select()
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting plant types: $e');
    }
  }

  /// Get plant type by ID
  Future<Map<String, dynamic>?> getPlantTypeById(String plantTypeId) async {
    try {
      final response =
          await _supabase
              .from('plant_types')
              .select()
              .eq('id', plantTypeId)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error getting plant type: $e');
    }
  }

  /// Add new plant type (admin function)
  Future<Map<String, dynamic>> addPlantType({
    required String id,
    required String name,
    String? description,
    required int growingDays,
    String? imageUrl,
  }) async {
    try {
      final response =
          await _supabase
              .from('plant_types')
              .insert({
                'id': id,
                'name': name,
                'description': description,
                'growing_days': growingDays,
                'image_url': imageUrl,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error adding plant type: $e');
    }
  }
}
