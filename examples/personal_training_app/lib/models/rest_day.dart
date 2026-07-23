class RestDay {
  final String id;
  final DateTime date;
  final String clientName;
  final String? notes;

  RestDay({
    required this.id,
    required this.date,
    required this.clientName,
    this.notes,
  });

  RestDay copyWith({
    String? id,
    DateTime? date,
    String? clientName,
    String? notes,
  }) {
    return RestDay(
      id: id ?? this.id,
      date: date ?? this.date,
      clientName: clientName ?? this.clientName,
      notes: notes ?? this.notes,
    );
  }
}
