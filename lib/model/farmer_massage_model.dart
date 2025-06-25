class FarmerMessage {
  final String id;
  final String accuracyParameterId;
  final int accuracyPercentage;
  final String message;
  final String? tips;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmerMessage({
    required this.id,
    required this.accuracyParameterId,
    required this.accuracyPercentage,
    required this.message,
    this.tips,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmerMessage.fromJson(Map<String, dynamic> json) {
    return FarmerMessage(
      id: json['id'],
      accuracyParameterId: json['accuracy_parameter_id'],
      accuracyPercentage: json['accuracy_percentage'],
      message: json['message'],
      tips: json['tips'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accuracy_parameter_id': accuracyParameterId,
      'accuracy_percentage': accuracyPercentage,
      'message': message,
      'tips': tips,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
