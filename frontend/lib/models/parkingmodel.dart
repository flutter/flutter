class Parking {
  final int id;
  final String name;
  final String? location; // Make location nullable

  Parking({required this.id, required this.name, this.location}); // Update constructor

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location ?? '', // Use default value if location is null
    };
  }
}
