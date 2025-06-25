class TimelineItem {
  final DateTime date;
  final int dayNumber;
  final int totalTasks;
  final int completedTasks;
  final int totalAccuracyChecks;
  final int completedAccuracyChecks;
  double overallAccuracy;
  final double overallCompletion;
  TimelineStatus status;
  final String? notes;

  TimelineItem({
    required this.date,
    required this.dayNumber,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalAccuracyChecks,
    required this.completedAccuracyChecks,
    required this.overallAccuracy,
    required this.overallCompletion,
    required this.status,
    this.notes,
  });

  TimelineItem copyWith({
    DateTime? date,
    int? dayNumber,
    int? totalTasks,
    int? completedTasks,
    int? totalAccuracyChecks,
    int? completedAccuracyChecks,
    double? overallAccuracy,
    double? overallCompletion,
    TimelineStatus? status,
    String? notes,
  }) {
    return TimelineItem(
      date: date ?? this.date,
      dayNumber: dayNumber ?? this.dayNumber,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      totalAccuracyChecks: totalAccuracyChecks ?? this.totalAccuracyChecks,
      completedAccuracyChecks: completedAccuracyChecks ?? this.completedAccuracyChecks,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      overallCompletion: overallCompletion ?? this.overallCompletion,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

enum TimelineStatus {
  excellent,
  good,
  average,
  poor,
  incomplete,
  pending,
}