class IllnessDay {
  final String id;
  final DateTime date;
  final String? reason;
  final String? notes;

  IllnessDay({required this.id, required this.date, this.reason, this.notes});

  IllnessDay copyWith({
    String? id,
    DateTime? date,
    String? reason,
    String? notes,
  }) {
    return IllnessDay(
      id: id ?? this.id,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
    );
  }
}
