class TaskTemplate {
  final String id;
  final String plantTypeId;
  final String taskName;
  final String? taskDescription;
  final int dayNumber;
  final bool isDaily;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskTemplate({
    required this.id,
    required this.plantTypeId,
    required this.taskName,
    this.taskDescription,
    required this.dayNumber,
    this.isDaily = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'],
      plantTypeId: json['plant_type_id'],
      taskName: json['task_name'],
      taskDescription: json['task_description'],
      dayNumber: json['day_number'],
      isDaily: json['is_daily'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_type_id': plantTypeId,
      'task_name': taskName,
      'task_description': taskDescription,
      'day_number': dayNumber,
      'is_daily': isDaily,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
