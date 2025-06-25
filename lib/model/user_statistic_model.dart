class UserStatistics {
  final String userId;
  final int totalPlantsGrown;
  final int totalSuccessfulHarvests;
  final int totalFailedPlants;
  final double successRate;
  final String? favoritePlantTypeId;
  final String? favoritePlantTypeName;
  final DateTime? lastActivityDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStatistics({
    required this.userId,
    this.totalPlantsGrown = 0,
    this.totalSuccessfulHarvests = 0,
    this.totalFailedPlants = 0,
    this.successRate = 0.0,
    this.favoritePlantTypeId,
    this.favoritePlantTypeName,
    this.lastActivityDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      userId: json['user_id'],
      totalPlantsGrown: json['total_plants_grown'] ?? 0,
      totalSuccessfulHarvests: json['total_successful_harvests'] ?? 0,
      totalFailedPlants: json['total_failed_plants'] ?? 0,
      successRate: (json['success_rate'] ?? 0.0).toDouble(),
      favoritePlantTypeId: json['favorite_plant_type_id'],
      favoritePlantTypeName: json['favorite_plant_type_name'],
      lastActivityDate:
          json['last_activity_date'] != null
              ? DateTime.parse(json['last_activity_date'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_plants_grown': totalPlantsGrown,
      'total_successful_harvests': totalSuccessfulHarvests,
      'total_failed_plants': totalFailedPlants,
      'success_rate': successRate,
      'favorite_plant_type_id': favoritePlantTypeId,
      'last_activity_date': lastActivityDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get totalCompletedPlants => totalSuccessfulHarvests + totalFailedPlants;
  int get activePlants => totalPlantsGrown - totalCompletedPlants;
}
