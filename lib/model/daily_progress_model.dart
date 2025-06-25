class DailyProgress {
  final String id;
  final String userPlantId;
  final DateTime progressDate;
  final int totalTasks;
  final int completedTasks;
  final int totalAccuracyChecks;
  final int completedAccuracyChecks;
  final int overallCompletionPercentage;
  final String? notes;
  final List<String>? photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final String? plantName;
  final String? plantTypeName;

  DailyProgress({
    required this.id,
    required this.userPlantId,
    required this.progressDate,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalAccuracyChecks = 0,
    this.completedAccuracyChecks = 0,
    this.overallCompletionPercentage = 0,
    this.notes,
    this.photos,
    required this.createdAt,
    required this.updatedAt,
    this.plantName,
    this.plantTypeName,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      id: json['id'],
      userPlantId: json['user_plant_id'],
      progressDate: DateTime.parse(json['progress_date']),
      totalTasks: json['total_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      totalAccuracyChecks: json['total_accuracy_checks'] ?? 0,
      completedAccuracyChecks: json['completed_accuracy_checks'] ?? 0,
      overallCompletionPercentage: json['overall_completion_percentage'] ?? 0,
      notes: json['notes'],
      photos:
          json['photos'] != null
              ? json['photos'].split(',').cast<String>()
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      plantName: json['plant_name'],
      plantTypeName: json['plant_type_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_plant_id': userPlantId,
      'progress_date': progressDate.toIso8601String().split('T')[0],
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'total_accuracy_checks': totalAccuracyChecks,
      'completed_accuracy_checks': completedAccuracyChecks,
      'overall_completion_percentage': overallCompletionPercentage,
      'notes': notes,
      'photos': photos?.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get taskCompletionRate {
    return totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
  }

  double get accuracyCompletionRate {
    return totalAccuracyChecks > 0
        ? (completedAccuracyChecks / totalAccuracyChecks) * 100
        : 0.0;
  }
}
