class PlantPhoto {
  final String id;
  final String userPlantId;
  final String photoUrl;
  final DateTime photoDate;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantPhoto({
    required this.id,
    required this.userPlantId,
    required this.photoUrl,
    required this.photoDate,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlantPhoto.fromJson(Map<String, dynamic> json) {
    return PlantPhoto(
      id: json['id'],
      userPlantId: json['user_plant_id'],
      photoUrl: json['photo_url'],
      photoDate: DateTime.parse(json['photo_date']),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_plant_id': userPlantId,
      'photo_url': photoUrl,
      'photo_date': photoDate.toIso8601String().split('T')[0],
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
