import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AccuracyParameterService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAccuracyParametersForPlantType(
    String plantTypeId,
  ) async {
    try {
      debugPrint('🔍 Getting parameters for plant type: $plantTypeId');

      if (plantTypeId.isEmpty) {
        debugPrint('⚠️ Empty plantTypeId provided');
        return [];
      }

      // Query dengan explicit column selection
      final response = await _supabase
          .from('accuracy_parameters')
          .select('''
            id,
            plant_type_id,
            parameter_name,
            parameter_description,
            day_number,
            expected_value,
            created_at
          ''')
          .eq('plant_type_id', plantTypeId)
          .order('day_number');

      debugPrint('📥 Parameters response: ${response.length} items');

      if (response.isNotEmpty) {
        debugPrint('📄 First parameter: ${response.first}');
      }

      return _sanitizeResponseList(response);
    } catch (e, stackTrace) {
      debugPrint('🚨 Error getting parameters: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  List<Map<String, dynamic>> _sanitizeResponseList(dynamic response) {
    try {
      if (response == null) return [];
      if (response is! List) return [];

      List<Map<String, dynamic>> sanitized = [];
      for (var item in response) {
        if (item != null && item is Map) {
          Map<String, dynamic> safeItem = Map<String, dynamic>.from(item);
          sanitized.add(safeItem);
        }
      }

      return sanitized;
    } catch (e) {
      debugPrint('Error sanitizing parameters response: $e');
      return [];
    }
  }
}
