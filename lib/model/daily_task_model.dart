class DailyTask {
  final String id;
  final String userPlantId;
  final String taskTemplateId;
  final DateTime taskDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final String? taskName;
  final String? taskDescription;
  final String? plantName;
  final String? plantTypeName;

  DailyTask({
    required this.id,
    required this.userPlantId,
    required this.taskTemplateId,
    required this.taskDate,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.taskName,
    this.taskDescription,
    this.plantName,
    this.plantTypeName,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'],
      userPlantId: json['user_plant_id'],
      taskTemplateId: json['task_template_id'],
      taskDate: DateTime.parse(json['task_date']),
      isCompleted: json['is_completed'] ?? false,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      taskName: json['task_name'],
      taskDescription: json['task_description'],
      plantName: json['plant_name'],
      plantTypeName: json['plant_type_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_plant_id': userPlantId,
      'task_template_id': taskTemplateId,
      'task_date': taskDate.toIso8601String().split('T')[0],
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
