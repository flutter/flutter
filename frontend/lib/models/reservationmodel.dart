class Reservation {
  final int id;
  final int userId;
  final int parkingId;
  final String date;

  Reservation({
    required this.id,
    required this.userId,
    required this.parkingId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'parkingId': parkingId,
      'date': date,
    };
  }
}
