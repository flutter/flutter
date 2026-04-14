// lib/models/shift_entry.dart

class ShiftEntry {
  final String date; // e.g. "06/04/2026"
  final String startTime; // e.g. "06:48 PM"
  final String endTime;
  final String totalHours;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  const ShiftEntry({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    this.startLat = 23.0225,
    this.startLng = 72.5714,
    this.endLat = 23.0225,
    this.endLng = 72.5714,
  });
}

/// Grouped model used for the timesheet table
class ShiftGroup {
  final String date;
  final List<ShiftEntry> entries;
  const ShiftGroup({required this.date, required this.entries});
}

/// ── Dummy Data ───────────────────────────────────────────────────────────────
const List<ShiftEntry> kDummyShifts = [
  ShiftEntry(
    date: '06/04/2026',
    startTime: '06:48 PM',
    endTime: '06:52 PM',
    totalHours: '00:04',
  ),
  ShiftEntry(
    date: '06/04/2026',
    startTime: '06:39 PM',
    endTime: '06:45 PM',
    totalHours: '00:06',
  ),
  ShiftEntry(
    date: '06/04/2026',
    startTime: '02:50 PM',
    endTime: '03:01 PM',
    totalHours: '00:11',
  ),
  ShiftEntry(
    date: '04/04/2026',
    startTime: '12:38 AM',
    endTime: '12:49 AM',
    totalHours: '00:11',
  ),
  ShiftEntry(
    date: '04/04/2026',
    startTime: '12:02 AM',
    endTime: '12:13 AM',
    totalHours: '00:11',
  ),
  ShiftEntry(
    date: '03/04/2026',
    startTime: '11:58 PM',
    endTime: '11:59 PM',
    totalHours: '00:01',
  ),
  ShiftEntry(
    date: '02/04/2026',
    startTime: '05:46 PM',
    endTime: '05:47 PM',
    totalHours: '00:01',
  ),
  ShiftEntry(
    date: '02/04/2026',
    startTime: '05:35 PM',
    endTime: '05:37 PM',
    totalHours: '00:02',
  ),
  ShiftEntry(
    date: '01/04/2026',
    startTime: '04:39 PM',
    endTime: '05:18 PM',
    totalHours: '00:39',
  ),
  ShiftEntry(
    date: '01/04/2026',
    startTime: '04:28 PM',
    endTime: '04:31 PM',
    totalHours: '00:03',
  ),
  ShiftEntry(
    date: '31/03/2026',
    startTime: '09:00 AM',
    endTime: '05:30 PM',
    totalHours: '08:30',
  ),
  ShiftEntry(
    date: '30/03/2026',
    startTime: '08:45 AM',
    endTime: '05:00 PM',
    totalHours: '08:15',
  ),
  ShiftEntry(
    date: '29/03/2026',
    startTime: '09:15 AM',
    endTime: '06:00 PM',
    totalHours: '08:45',
  ),
];

List<ShiftGroup> groupShifts(List<ShiftEntry> entries) {
  final Map<String, List<ShiftEntry>> map = {};
  for (final e in entries) {
    map.putIfAbsent(e.date, () => []).add(e);
  }
  return map.entries
      .map((e) => ShiftGroup(date: e.key, entries: e.value))
      .toList();
}
