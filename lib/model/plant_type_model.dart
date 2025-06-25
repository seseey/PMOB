class PlantType {
  final String id;
  final String name;
  final String? description;
  final int growingDays;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantType({
    required this.id,
    required this.name,
    this.description,
    required this.growingDays,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlantType.fromJson(Map<String, dynamic> json) {
    return PlantType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      growingDays: json['growing_days'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'growing_days': growingDays,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
