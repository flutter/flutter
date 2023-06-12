import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('DateTimeAdapter', () {
    test('.read()', () {
      var now = DateTime.now();
      var binaryReader = MockBinaryReader();
      when(() => binaryReader.readInt()).thenReturn(now.millisecondsSinceEpoch);

      var date = DateTimeAdapter().read(binaryReader);
      verify(() => binaryReader.readInt());
      expect(date, now.subtract(Duration(microseconds: now.microsecond)));
    });

    test('.write()', () {
      var now = DateTime.now();
      var binaryWriter = MockBinaryWriter();

      DateTimeAdapter().write(binaryWriter, now);
      verify(() => binaryWriter.writeInt(now.millisecondsSinceEpoch));
    });
  });

  group('DateTimeWithTimezoneAdapter', () {
    group('.read()', () {
      test('local', () {
        var now = DateTime.now();
        var binaryReader = MockBinaryReader();
        when(() => binaryReader.readInt())
            .thenReturn(now.millisecondsSinceEpoch);
        when(() => binaryReader.readBool()).thenReturn(false);

        var date = DateTimeWithTimezoneAdapter().read(binaryReader);
        verifyInOrder([
          () => binaryReader.readInt(),
          () => binaryReader.readBool(),
        ]);
        expect(date, now.subtract(Duration(microseconds: now.microsecond)));
      });

      test('UTC', () {
        var now = DateTime.now().toUtc();
        var binaryReader = MockBinaryReader();
        when(() => binaryReader.readInt())
            .thenReturn(now.millisecondsSinceEpoch);
        when(() => binaryReader.readBool()).thenReturn(true);

        var date = DateTimeWithTimezoneAdapter().read(binaryReader);
        verifyInOrder([
          () => binaryReader.readInt(),
          () => binaryReader.readBool(),
        ]);
        expect(date, now.subtract(Duration(microseconds: now.microsecond)));
        expect(date.isUtc, true);
      });
    });

    group('.write()', () {
      test('local', () {
        var now = DateTime.now();
        var binaryWriter = MockBinaryWriter();

        DateTimeWithTimezoneAdapter().write(binaryWriter, now);
        verifyInOrder([
          () => binaryWriter.writeInt(now.millisecondsSinceEpoch),
          () => binaryWriter.writeBool(false),
        ]);
      });

      test('UTC', () {
        var now = DateTime.now().toUtc();
        var binaryWriter = MockBinaryWriter();

        DateTimeWithTimezoneAdapter().write(binaryWriter, now);
        verifyInOrder([
          () => binaryWriter.writeInt(now.millisecondsSinceEpoch),
          () => binaryWriter.writeBool(true),
        ]);
      });
    });
  });
}
