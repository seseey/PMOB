class AccuracyParameter {
  final String id;
  final String plantTypeId;
  final String parameterName;
  final String? parameterDescription;
  final int dayNumber;
  final String? expectedValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccuracyParameter({
    required this.id,
    required this.plantTypeId,
    required this.parameterName,
    this.parameterDescription,
    required this.dayNumber,
    this.expectedValue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccuracyParameter.fromJson(Map<String, dynamic> json) {
    return AccuracyParameter(
      id: json['id'],
      plantTypeId: json['plant_type_id'],
      parameterName: json['parameter_name'],
      parameterDescription: json['parameter_description'],
      dayNumber: json['day_number'],
      expectedValue: json['expected_value'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_type_id': plantTypeId,
      'parameter_name': parameterName,
      'parameter_description': parameterDescription,
      'day_number': dayNumber,
      'expected_value': expectedValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
