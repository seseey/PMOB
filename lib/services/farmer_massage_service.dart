import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class FarmerMessageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getFarmerMessage({
    required String accuracyParameterId,
    required int accuracyPercentage,
  }) async {
    try {
      debugPrint(
        '🔍 Getting farmer message for: $accuracyParameterId, $accuracyPercentage%',
      );

      if (accuracyParameterId.isEmpty) {
        debugPrint('⚠️ Empty accuracyParameterId provided');
        return null;
      }

      final response =
          await _supabase
              .from('farmer_messages')
              .select('*')
              .eq('accuracy_parameter_id', accuracyParameterId)
              .eq('accuracy_percentage', accuracyPercentage)
              .maybeSingle();

      debugPrint('📥 Farmer message response: $response');

      return _sanitizeResponse(response);
    } catch (e, stackTrace) {
      debugPrint('🚨 Error getting farmer message: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  Map<String, dynamic>? _sanitizeResponse(dynamic response) {
    try {
      if (response == null) return null;
      if (response is! Map) return null;

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('⚠️ Error sanitizing farmer message response: $e');
      return null;
    }
  }
}
