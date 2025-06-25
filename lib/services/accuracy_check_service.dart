import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // Tambahkan dependency ini

class AccuracyCheckService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  /// Submit accuracy check dengan proper UUID generation
  Future<Map<String, dynamic>> submitAccuracyCheck({
    String? id, // Jadikan optional
    required String userPlantId,
    required String accuracyParameterId,
    required DateTime checkDate,
    String? userValue,
    required int accuracyPercentage,
    bool isAccurate = false,
  }) async {
    try {
      debugPrint('🚀 Submitting accuracy check...');

      // Generate proper UUID jika tidak disediakan
      final checkId = id ?? _uuid.v4();

      debugPrint(
        '📊 Data: id=$checkId, userPlantId=$userPlantId, parameterId=$accuracyParameterId',
      );

      // Validasi input
      if (userPlantId.isEmpty || accuracyParameterId.isEmpty) {
        throw Exception(
          'Invalid input: userPlantId or accuracyParameterId is empty',
        );
      }

      final dataToInsert = {
        'id': checkId,
        'user_plant_id': userPlantId,
        'accuracy_parameter_id': accuracyParameterId,
        'check_date': checkDate.toIso8601String().split('T')[0],
        'user_value': userValue,
        'accuracy_percentage': accuracyPercentage,
        'is_accurate': isAccurate,
      };

      debugPrint('📤 Inserting data: $dataToInsert');

      final response =
          await _supabase
              .from('accuracy_checks')
              .insert(dataToInsert)
              .select()
              .single();

      debugPrint('✅ Submit response: $response');
      return _sanitizeResponse(response);
    } catch (e, stackTrace) {
      debugPrint('🚨 Error submitting accuracy check: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Jika error karena constraint, berikan pesan yang lebih jelas
      if (e.toString().contains('foreign key') ||
          e.toString().contains('constraint')) {
        throw Exception(
          'Data validation error: Please check if plant and parameter exist',
        );
      }

      throw Exception('Error submitting accuracy check: $e');
    }
  }

  /// Get accuracy checks dengan proper error handling untuk UUID
  Future<List<Map<String, dynamic>>> getAccuracyChecksForPlant(
    String userPlantId,
  ) async {
    try {
      debugPrint('🔍 Getting accuracy checks for plant: $userPlantId');

      // Validasi input
      if (userPlantId.isEmpty) {
        debugPrint('⚠️ Empty userPlantId provided');
        return [];
      }

      // Query dengan explicit column selection untuk menghindari masalah parsing
      final response = await _supabase
          .from('accuracy_checks')
          .select('''
            id,
            user_plant_id,
            accuracy_parameter_id,
            check_date,
            user_value,
            accuracy_percentage,
            is_accurate,
            created_at,
            accuracy_parameters!inner(
              id,
              parameter_name,
              parameter_description,
              expected_value
            )
          ''')
          .eq('user_plant_id', userPlantId)
          .order('check_date', ascending: false);

      debugPrint('📥 Raw Supabase response type: ${response.runtimeType}');
      debugPrint('📥 Raw response length: ${response.length}');

      // Debug first item structure
      if (response.isNotEmpty) {
        debugPrint('📄 First item: ${response.first}');
        _debugResponseStructure(response.first);
      }

      return _sanitizeResponseList(response);
    } catch (e, stackTrace) {
      debugPrint('🚨 Error getting accuracy checks: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Coba query sederhana sebagai fallback
      return await _getFallbackAccuracyChecks(userPlantId);
    }
  }

  /// Fallback method dengan query yang lebih sederhana
  Future<List<Map<String, dynamic>>> _getFallbackAccuracyChecks(
    String userPlantId,
  ) async {
    try {
      debugPrint('🔄 Trying fallback query...');

      final response = await _supabase
          .from('accuracy_checks')
          .select('*')
          .eq('user_plant_id', userPlantId)
          .order('check_date', ascending: false);

      debugPrint('📥 Fallback response length: ${response.length}');

      return _sanitizeResponseList(response);
    } catch (e) {
      debugPrint('🚨 Fallback query also failed: $e');
      return [];
    }
  }

  /// Debug structure dengan detail
  void _debugResponseStructure(dynamic item) {
    try {
      if (item is Map) {
        item.forEach((key, value) {
          debugPrint('🔍   $key (${value.runtimeType}): $value');

          // Special check untuk UUID format
          if (value is String && _isUuidLike(value)) {
            debugPrint('🆔     ^ This looks like UUID: ${value.length} chars');
          }

          // Check nested objects
          if (value is Map && key == 'accuracy_parameters') {
            debugPrint('🔍     Nested accuracy_parameters:');
            value.forEach((nestedKey, nestedValue) {
              debugPrint('🔍       $nestedKey: $nestedValue');
            });
          }
        });
      }
    } catch (e) {
      debugPrint('🚨 Error debugging structure: $e');
    }
  }

  /// Check if string looks like UUID
  bool _isUuidLike(String value) {
    // Check untuk pattern UUID yang lengkap atau partial
    return RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
        ).hasMatch(value) ||
        RegExp(r'^[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+').hasMatch(value);
  }

  /// Sanitize single response dari Supabase
  Map<String, dynamic> _sanitizeResponse(dynamic response) {
    try {
      if (response == null) return <String, dynamic>{};
      if (response is! Map) return <String, dynamic>{};

      Map<String, dynamic> sanitized = <String, dynamic>{};

      response.forEach((key, value) {
        try {
          String safeKey = key?.toString() ?? '';
          if (safeKey.isNotEmpty) {
            // Special handling untuk nested objects
            if (value is Map) {
              sanitized[safeKey] = _sanitizeResponse(value);
            } else if (value is List) {
              sanitized[safeKey] = _sanitizeResponseList(value);
            } else {
              // Pastikan value tidak null dan dalam format yang benar
              sanitized[safeKey] = value;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error sanitizing key $key: $e');
          // Skip problematic keys instead of failing completely
        }
      });

      return sanitized;
    } catch (e) {
      debugPrint('⚠️ Error in _sanitizeResponse: $e');
      return <String, dynamic>{};
    }
  }

  /// Sanitize list response dari Supabase
  List<Map<String, dynamic>> _sanitizeResponseList(dynamic response) {
    try {
      if (response == null) return [];
      if (response is! List) return [];

      List<Map<String, dynamic>> sanitized = [];

      for (int i = 0; i < response.length; i++) {
        try {
          var item = response[i];
          Map<String, dynamic> sanitizedItem = _sanitizeResponse(item);
          if (sanitizedItem.isNotEmpty) {
            sanitized.add(sanitizedItem);
          }
        } catch (e) {
          debugPrint('⚠️ Error sanitizing item $i: $e');
          // Continue dengan item berikutnya
        }
      }

      debugPrint(
        '✅ Sanitized ${sanitized.length} items from ${response.length}',
      );
      return sanitized;
    } catch (e) {
      debugPrint('⚠️ Error in _sanitizeResponseList: $e');
      return [];
    }
  }

  /// Get accuracy checks dengan retry mechanism dan better error handling
  Future<List<Map<String, dynamic>>> getAccuracyChecksForPlantWithRetry(
    String userPlantId, {
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Attempt ${attempt + 1} for userPlantId: $userPlantId');

        final result = await getAccuracyChecksForPlant(userPlantId);

        if (result.isNotEmpty || attempt == maxRetries) {
          return result;
        }

        // Wait before retry
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      } catch (e) {
        debugPrint('🚨 Attempt ${attempt + 1} failed: $e');

        if (attempt == maxRetries) {
          debugPrint('🛑 All attempts failed, returning empty list');
          return [];
        }
      }
    }

    return [];
  }

  /// Validate UUID format
  bool isValidUuid(String? uuid) {
    if (uuid == null || uuid.isEmpty) return false;

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    );

    return uuidRegex.hasMatch(uuid);
  }

  /// Generate new UUID
  String generateNewId() {
    return _uuid.v4();
  }
}
