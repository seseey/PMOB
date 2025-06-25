class PlantingHistory {
  final String id;
  final String userPlantId;
  final String actionType;
  final DateTime actionDate;
  final String? description;
  final String? additionalData;
  final DateTime createdAt;

  PlantingHistory({
    required this.id,
    required this.userPlantId,
    required this.actionType,
    required this.actionDate,
    this.description,
    this.additionalData,
    required this.createdAt,
  });

  factory PlantingHistory.fromJson(Map<String, dynamic> json) {
    return PlantingHistory(
      id: json['id'],
      userPlantId: json['user_plant_id'],
      actionType: json['action_type'],
      actionDate: DateTime.parse(json['action_date']),
      description: json['description'],
      additionalData: json['additional_data'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_plant_id': userPlantId,
      'action_type': actionType,
      'action_date': actionDate.toIso8601String().split('T')[0],
      'description': description,
      'additional_data': additionalData,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
