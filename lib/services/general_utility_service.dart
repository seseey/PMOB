class PlantUtilityService {
  /// Calculate plant age in days
  int calculatePlantAge(DateTime startDate) {
    return DateTime.now().difference(startDate).inDays;
  }

  /// Calculate days until harvest
  int calculateDaysUntilHarvest(DateTime expectedHarvestDate) {
    return expectedHarvestDate.difference(DateTime.now()).inDays;
  }

  /// Calculate completion percentage
  double calculateCompletionPercentage(int completed, int total) {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  /// Generate unique ID with timestamp
  String generateUniqueId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Convert accuracy percentage to status
  String getAccuracyStatus(int percentage) {
    if (percentage >= 90) return 'excellent';
    if (percentage >= 75) return 'good';
    if (percentage >= 50) return 'fair';
    return 'poor';
  }

  /// Get plant status display text
  String getPlantStatusDisplay(String status) {
    switch (status) {
      case 'planting':
        return 'Sedang Ditanam';
      case 'harvested':
        return 'Sudah Dipanen';
      case 'failed':
        return 'Gagal';
      default:
        return 'Unknown';
    }
  }

  /// Get harvest quality display text
  String getHarvestQualityDisplay(String? quality) {
    if (quality == null) return 'Belum Dinilai';
    switch (quality) {
      case 'excellent':
        return 'Sangat Baik';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup';
      case 'poor':
        return 'Kurang';
      default:
        return quality;
    }
  }

  /// Format weight display
  String formatWeight(double? weight) {
    if (weight == null) return '0 gram';
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(1)} kg';
    }
    return '${weight.toStringAsFixed(0)} gram';
  }

  /// Get plant progress percentage based on days
  double getPlantProgressPercentage(DateTime startDate, int totalGrowingDays) {
    final currentDays = calculatePlantAge(startDate);
    final percentage = (currentDays / totalGrowingDays) * 100;
    return percentage > 100 ? 100 : percentage;
  }
}
