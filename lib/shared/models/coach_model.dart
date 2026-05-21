class CoachModel {
  final String id;
  final String name;
  final String photoUrl;
  final String specialty;       // "Başlangıç", "İleri Seviye", "Turnuva Hazırlık"
  final double pricePerHour;
  final double rating;
  final int totalSessions;
  final Map<String, List<String>> availability; // {"monday": ["09:00","10:00",...], ...}

  CoachModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.specialty,
    required this.pricePerHour,
    required this.rating,
    required this.totalSessions,
    required this.availability,
  });

  factory CoachModel.fromMap(Map<String, dynamic> map, String id) {
    return CoachModel(
      id: id,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      specialty: map['specialty'] ?? '',
      pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      totalSessions: map['totalSessions'] ?? 0,
      availability: Map<String, List<String>>.from(
        (map['availability'] as Map).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'specialty': specialty,
      'pricePerHour': pricePerHour,
      'rating': rating,
      'totalSessions': totalSessions,
      'availability': availability,
    };
  }
}