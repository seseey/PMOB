enum PlantStatus {
  planting('planting'),
  harvested('harvested'),
  failed('failed');

  const PlantStatus(this.value);
  final String value;

  static PlantStatus fromString(String value) {
    switch (value) {
      case 'planting':
        return PlantStatus.planting;
      case 'harvested':
        return PlantStatus.harvested;
      case 'failed':
        return PlantStatus.failed;
      default:
        return PlantStatus.planting;
    }
  }
}
