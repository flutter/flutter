part of hive_flutter_adapters;

class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  @override
  TimeOfDay read(BinaryReader reader) {
    final totalMinutes = reader.readInt();
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeInt(obj.hour * 60 + obj.minute);
  }

  @override
  int get typeId => 201;
}
