class MonthlyPlantingStats {
  final int month;
  final int total;
  final int harvested;
  final int failed;
  final int planting;

  MonthlyPlantingStats({
    required this.month,
    this.total = 0,
    this.harvested = 0,
    this.failed = 0,
    this.planting = 0,
  });

  factory MonthlyPlantingStats.fromJson(Map<String, dynamic> json) {
    return MonthlyPlantingStats(
      month: json['month'],
      total: json['total'] ?? 0,
      harvested: json['harvested'] ?? 0,
      failed: json['failed'] ?? 0,
      planting: json['planting'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'total': total,
      'harvested': harvested,
      'failed': failed,
      'planting': planting,
    };
  }

  double get successRate {
    final completed = harvested + failed;
    return completed > 0 ? (harvested / completed) * 100 : 0.0;
  }
}

class PlantTypePopularity {
  final String plantTypeId;
  final String name;
  final String? imageUrl;
  final int count;

  PlantTypePopularity({
    required this.plantTypeId,
    required this.name,
    this.imageUrl,
    required this.count,
  });

  factory PlantTypePopularity.fromJson(Map<String, dynamic> json) {
    return PlantTypePopularity(
      plantTypeId: json['plant_type_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant_type_id': plantTypeId,
      'name': name,
      'image_url': imageUrl,
      'count': count,
    };
  }
}

class TaskCompletionRate {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;

  TaskCompletionRate({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
  });

  factory TaskCompletionRate.fromJson(Map<String, dynamic> json) {
    return TaskCompletionRate(
      totalTasks: json['total_tasks'],
      completedTasks: json['completed_tasks'],
      completionRate: (json['completion_rate']).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'completion_rate': completionRate,
    };
  }
}
