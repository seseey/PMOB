import 'accuracy_parameter_model.dart';

class AccuracyCheck {
  final String id;
  final String userPlantId;
  final String accuracyParameterId;
  final DateTime checkDate;
  final String? userValue;
  final int accuracyPercentage;
  final bool isAccurate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final AccuracyParameter? accuracyParameter;

  AccuracyCheck({
    required this.id,
    required this.userPlantId,
    required this.accuracyParameterId,
    required this.checkDate,
    this.userValue,
    required this.accuracyPercentage,
    this.isAccurate = false,
    required this.createdAt,
    required this.updatedAt,
    this.accuracyParameter,
  });

  factory AccuracyCheck.fromJson(Map<String, dynamic> json) {
    return AccuracyCheck(
      id: json['id'],
      userPlantId: json['user_plant_id'],
      accuracyParameterId: json['accuracy_parameter_id'],
      checkDate: DateTime.parse(json['check_date']),
      userValue: json['user_value'],
      accuracyPercentage: json['accuracy_percentage'],
      isAccurate: json['is_accurate'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      accuracyParameter:
          json['accuracy_parameters'] != null
              ? AccuracyParameter.fromJson(json['accuracy_parameters'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_plant_id': userPlantId,
      'accuracy_parameter_id': accuracyParameterId,
      'check_date': checkDate.toIso8601String().split('T')[0],
      'user_value': userValue,
      'accuracy_percentage': accuracyPercentage,
      'is_accurate': isAccurate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get accuracyStatus {
    if (accuracyPercentage >= 90) return 'excellent';
    if (accuracyPercentage >= 75) return 'good';
    if (accuracyPercentage >= 50) return 'fair';
    return 'poor';
  }
}
