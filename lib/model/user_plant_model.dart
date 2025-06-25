import 'plant_type_model.dart';

class UserPlant {
  final String id;
  final String userId;
  final String plantTypeId;
  final String? plantName;
  final DateTime startDate;
  final DateTime expectedHarvestDate;
  final DateTime? actualHarvestDate;
  final String status; // 'planting', 'harvested', 'failed'
  final String? harvestNotes;
  final double? totalHarvestWeight;
  final String? harvestQuality; // 'excellent', 'good', 'fair', 'poor'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final PlantType? plantType;

  UserPlant({
    required this.id,
    required this.userId,
    required this.plantTypeId,
    this.plantName,
    required this.startDate,
    required this.expectedHarvestDate,
    this.actualHarvestDate,
    required this.status,
    this.harvestNotes,
    this.totalHarvestWeight,
    this.harvestQuality,
    required this.createdAt,
    required this.updatedAt,
    this.plantType,
  });

  factory UserPlant.fromJson(Map<String, dynamic> json) {
    return UserPlant(
      id: json['id'],
      userId: json['user_id'],
      plantTypeId: json['plant_type_id'],
      plantName: json['plant_name'],
      startDate: DateTime.parse(json['start_date']),
      expectedHarvestDate: DateTime.parse(json['expected_harvest_date']),
      actualHarvestDate:
          json['actual_harvest_date'] != null
              ? DateTime.parse(json['actual_harvest_date'])
              : null,
      status: json['status'],
      harvestNotes: json['harvest_notes'],
      totalHarvestWeight: json['total_harvest_weight']?.toDouble(),
      harvestQuality: json['harvest_quality'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      plantType:
          json['plant_types'] != null
              ? PlantType.fromJson(json['plant_types'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plant_type_id': plantTypeId,
      'plant_name': plantName,
      'start_date': startDate.toIso8601String().split('T')[0],
      'expected_harvest_date':
          expectedHarvestDate.toIso8601String().split('T')[0],
      'actual_harvest_date': actualHarvestDate?.toIso8601String().split('T')[0],
      'status': status,
      'harvest_notes': harvestNotes,
      'total_harvest_weight': totalHarvestWeight,
      'harvest_quality': harvestQuality,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get plantAgeInDays {
    return DateTime.now().difference(startDate).inDays;
  }

  int get daysUntilHarvest {
    return expectedHarvestDate.difference(DateTime.now()).inDays;
  }

  double get progressPercentage {
    if (plantType == null) return 0.0;
    final currentDays = plantAgeInDays;
    final percentage = (currentDays / plantType!.growingDays) * 100;
    return percentage > 100 ? 100 : percentage;
  }
}
