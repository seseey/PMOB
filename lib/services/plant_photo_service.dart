import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class PlantPhotoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload and save plant photo
  Future<Map<String, dynamic>> uploadPlantPhoto({
    required String id,
    required String userPlantId,
    required String filePath,
    required DateTime photoDate,
    String? description,
  }) async {
    try {
      // Upload file to storage
      final file = File(filePath);
      final fileExtension = path.extension(filePath).replaceFirst('.', '');
      final fileName =
          'plant_${userPlantId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage.from('plants').upload('photos/$fileName', file);

      final publicUrl = _supabase.storage
          .from('plants')
          .getPublicUrl('photos/$fileName');

      // Save to database
      final response =
          await _supabase
              .from('plant_photos')
              .insert({
                'id': id,
                'user_plant_id': userPlantId,
                'photo_url': publicUrl,
                'photo_date': photoDate.toIso8601String().split('T')[0],
                'description': description,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Error uploading plant photo: $e');
    }
  }

  /// Get plant photos
  Future<List<Map<String, dynamic>>> getPlantPhotos(String userPlantId) async {
    try {
      final response = await _supabase
          .from('plant_photos')
          .select()
          .eq('user_plant_id', userPlantId)
          .order('photo_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting plant photos: $e');
    }
  }

  /// Delete plant photo
  Future<void> deletePlantPhoto(String photoId, String photoUrl) async {
    try {
      // Delete from storage
      final fileName = photoUrl.split('/').last;
      await _supabase.storage.from('plants').remove(['photos/$fileName']);

      // Delete from database
      await _supabase.from('plant_photos').delete().eq('id', photoId);
    } catch (e) {
      throw Exception('Error deleting plant photo: $e');
    }
  }
}
