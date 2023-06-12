import 'package:flutter/material.dart' show TimeOfDay;
import 'package:test/test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mockito/mockito.dart';

import '../mocks.dart';

void main() {
  group('TimeOfDayAdapter', () {
    late TimeOfDay time;
    late int totalMinutes;

    setUp(() {
      time = TimeOfDay(hour: 8, minute: 0);
      totalMinutes = time.hour * 60 + time.minute;
    });

    test('.read()', () {
      final BinaryReader binaryReader = MockBinaryReader();
      when(binaryReader.readInt()).thenReturn(totalMinutes);

      final readTime = TimeOfDayAdapter().read(binaryReader);
      verify(binaryReader.readInt()).called(1);
      expect(readTime, time);
    });

    test('.write()', () {
      final BinaryWriter binaryWriter = MockBinaryWriter();

      TimeOfDayAdapter().write(binaryWriter, time);
      verify(binaryWriter.writeInt(totalMinutes));
    });
  });
}
