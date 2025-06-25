enum HarvestQuality {
  excellent('excellent'),
  good('good'),
  fair('fair'),
  poor('poor');

  const HarvestQuality(this.value);
  final String value;

  static HarvestQuality? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'excellent':
        return HarvestQuality.excellent;
      case 'good':
        return HarvestQuality.good;
      case 'fair':
        return HarvestQuality.fair;
      case 'poor':
        return HarvestQuality.poor;
      default:
        return null;
    }
  }
}
