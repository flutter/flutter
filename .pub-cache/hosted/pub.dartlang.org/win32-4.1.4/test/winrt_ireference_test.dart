@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/winrt.dart';

// Test the WinRT IReference<T> types to make sure everything is working
// correctly.

void main() {
  if (isWindowsRuntimeAvailable()) {
    test('IReference<bool>', () {
      final pv = PropertyValue.createBoolean(true);
      final ireference = IReference<bool>.fromRawPointer(
          pv.toInterface(IID_IReference_Boolean),
          referenceIid: IID_IReference_Boolean);
      expect(ireference.value, isNotNull);
      expect(ireference.value, isTrue);

      ireference.release();
      pv.release();
    });

    test('IReference<DateTime>', () {
      final dateTime = DateTime(2022, 8, 28, 17);
      final pv = PropertyValue.createDateTime(dateTime);
      final ireference = IReference<DateTime>.fromRawPointer(
          pv.toInterface(IID_IReference_DateTime),
          referenceIid: IID_IReference_DateTime);
      expect(ireference.value, isNotNull);
      expect(ireference.value!.millisecondsSinceEpoch,
          dateTime.millisecondsSinceEpoch);

      ireference.release();
      pv.release();
    });

    test('IReference<double> (Double)', () {
      final pv = PropertyValue.createDouble(3.0);
      final ireference = IReference<double>.fromRawPointer(
          pv.toInterface(IID_IReference_Double),
          referenceIid: IID_IReference_Double);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(3.0));

      ireference.release();
      pv.release();
    });

    test('IReference<double> (Float)', () {
      final pv = PropertyValue.createSingle(3.0);
      final ireference = IReference<double>.fromRawPointer(
          pv.toInterface(IID_IReference_Float),
          referenceIid: IID_IReference_Float);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(3.0));

      ireference.release();
      pv.release();
    });

    test('IReference<Duration>', () {
      const duration = Duration(seconds: 30);
      final pv = PropertyValue.createTimeSpan(duration);
      final ireference = IReference<Duration>.fromRawPointer(
          pv.toInterface(IID_IReference_TimeSpan),
          referenceIid: IID_IReference_TimeSpan);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(duration));

      ireference.release();
      pv.release();
    });

    test('IReference<Guid>', () {
      final pv = PropertyValue.createGuid(Guid.parse(IID_ICalendar));
      final ireference = IReference<Guid>.fromRawPointer(
          pv.toInterface(IID_IReference_Guid),
          referenceIid: IID_IReference_Guid);
      expect(ireference.value, isNotNull);
      expect(ireference.value!.toString(), equals(IID_ICalendar));

      ireference.release();
      pv.release();
    });

    test('IReference<int> (Int16)', () {
      final pv = PropertyValue.createInt16(16);
      final ireference = IReference<int>.fromRawPointer(
          pv.toInterface(IID_IReference_Int16),
          referenceIid: IID_IReference_Int16);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(16));

      ireference.release();
      pv.release();
    });

    test('IReference<int> (Int32)', () {
      final pv = PropertyValue.createInt32(32);
      final ireference = IReference<int>.fromRawPointer(
          pv.toInterface(IID_IReference_Int32),
          referenceIid: IID_IReference_Int32);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(32));

      ireference.release();
      pv.release();
    });

    test('IReference<int> (Int64)', () {
      final pv = PropertyValue.createInt64(64);
      final ireference = IReference<int>.fromRawPointer(
          pv.toInterface(IID_IReference_Int64),
          referenceIid: IID_IReference_Int64);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(64));

      ireference.release();
      pv.release();
    });

    test('IReference<int> (Uint8)', () {
      final pv = PropertyValue.createUInt8(8);
      final ireference = IReference<int>.fromRawPointer(
          pv.toInterface(IID_IReference_Uint8),
          referenceIid: IID_IReference_Uint8);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(8));

      ireference.release();
      pv.release();
    });

    test('IReference<int> (Uint32)', () {
      final pv = PropertyValue.createUInt32(32);
      final ireference = IReference<int>.fromRawPointer(
          pv.toInterface(IID_IReference_Uint32),
          referenceIid: IID_IReference_Uint32);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(32));

      ireference.release();
      pv.release();
    });

    test('IReference<int> (Uint64)', () {
      final pv = PropertyValue.createUInt64(64);
      final ireference = IReference<int>.fromRawPointer(
          pv.toInterface(IID_IReference_Uint64),
          referenceIid: IID_IReference_Uint64);
      expect(ireference.value, isNotNull);
      expect(ireference.value, equals(64));

      ireference.release();
      pv.release();
    });

    test('IReference<Point>', () {
      final pointPtr = calloc<Point>()
        ..ref.X = 50
        ..ref.Y = 100;
      final pv = PropertyValue.createPoint(pointPtr.ref);
      final ireference = IReference<Point>.fromRawPointer(
          pv.toInterface(IID_IReference_Point),
          referenceIid: IID_IReference_Point);
      expect(ireference.value, isNotNull);
      expect(ireference.value!.X, equals(50));
      expect(ireference.value!.Y, equals(100));

      ireference.release();
      pv.release();
      free(pointPtr);
    });

    test('IReference<Rect>', () {
      final rectPtr = calloc<Rect>()
        ..ref.Height = 200
        ..ref.Width = 100
        ..ref.X = 50
        ..ref.Y = 100;
      final pv = PropertyValue.createRect(rectPtr.ref);
      final ireference = IReference<Rect>.fromRawPointer(
          pv.toInterface(IID_IReference_Rect),
          referenceIid: IID_IReference_Rect);
      expect(ireference.value, isNotNull);
      expect(ireference.value!.Height, equals(200));
      expect(ireference.value!.Width, equals(100));
      expect(ireference.value!.X, equals(50));
      expect(ireference.value!.Y, equals(100));

      ireference.release();
      pv.release();
      free(rectPtr);
    });

    test('IReference<Size>', () {
      final sizePtr = calloc<Size>()
        ..ref.Height = 200
        ..ref.Width = 100;
      final pv = PropertyValue.createSize(sizePtr.ref);
      final ireference = IReference<Size>.fromRawPointer(
          pv.toInterface(IID_IReference_Size),
          referenceIid: IID_IReference_Size);
      expect(ireference.value, isNotNull);
      expect(ireference.value!.Height, equals(200));
      expect(ireference.value!.Width, equals(100));

      ireference.release();
      pv.release();
      free(sizePtr);
    });
  }
}
