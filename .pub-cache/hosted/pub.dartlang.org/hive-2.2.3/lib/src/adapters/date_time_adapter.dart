import 'package:hive/hive.dart';

/// Adapter for DateTime
class DateTimeAdapter<T extends DateTime> extends TypeAdapter<T> {
  @override
  final typeId = 16;

  @override
  T read(BinaryReader reader) {
    var millis = reader.readInt();
    return DateTimeWithoutTZ.fromMillisecondsSinceEpoch(millis) as T;
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}

class DateTimeWithoutTZ extends DateTime {
  DateTimeWithoutTZ.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch)
      : super.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

/// Alternative adapter for DateTime with time zone info
class DateTimeWithTimezoneAdapter extends TypeAdapter<DateTime> {
  @override
  final typeId = 18;

  @override
  DateTime read(BinaryReader reader) {
    var millis = reader.readInt();
    var isUtc = reader.readBool();
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: isUtc);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
    writer.writeBool(obj.isUtc);
  }
}
