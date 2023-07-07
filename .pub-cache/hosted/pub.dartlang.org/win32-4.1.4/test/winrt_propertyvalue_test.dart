@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/src/winrt/internal/comobject_pointer.dart';
import 'package:win32/winrt.dart';

// Test the WinRT PropertyValue object to make sure overrides, properties and
// methods are working correctly.

void main() {
  if (isWindowsRuntimeAvailable()) {
    test('UInt8', () {
      final pv = PropertyValue.createUInt8(30);
      expect(pv.type, equals(PropertyType.uint8));
      expect(pv.getUInt8(), equals(30));

      pv.release();
    });

    test('UInt8Array', () {
      final array = calloc<Uint8>(5);
      for (var idx = 0; idx < 5; idx++) {
        array[idx] = (10 * idx) + 10;
      }
      final pv = PropertyValue.createUInt8Array(5, array);
      expect(pv.type, equals(PropertyType.uint8Array));

      final arraySize = calloc<Uint32>();
      final newArray = calloc<Pointer<Uint8>>();

      pv.getUInt8Array(arraySize, newArray);
      expect(arraySize.value, equals(5));
      expect(newArray.value[0], equals(10));
      expect(newArray.value[1], equals(20));
      expect(newArray.value[2], equals(30));
      expect(newArray.value[3], equals(40));
      expect(newArray.value[4], equals(50));

      pv.release();
    });

    test('UInt16', () {
      final pv = PropertyValue.createUInt16(65534);
      expect(pv.type, equals(PropertyType.uint16));
      expect(pv.getUInt16(), equals(65534));

      pv.release();
    });

    test('UInt16Array', () {
      final array = calloc<Uint16>(5);
      for (var idx = 0; idx < 5; idx++) {
        array[idx] = (100 * idx) + 100;
      }
      final pv = PropertyValue.createUInt16Array(5, array);
      expect(pv.type, equals(PropertyType.uint16Array));

      final arraySize = calloc<Uint32>();
      final newArray = calloc<Pointer<Uint16>>();

      pv.getUInt16Array(arraySize, newArray);
      expect(arraySize.value, equals(5));
      expect(newArray.value[0], equals(100));
      expect(newArray.value[1], equals(200));
      expect(newArray.value[2], equals(300));
      expect(newArray.value[3], equals(400));
      expect(newArray.value[4], equals(500));

      pv.release();
    });

    test('Guid', () {
      final pv = PropertyValue.createGuid(Guid.parse(IID_ICalendar));
      expect(pv.type, equals(PropertyType.guid));
      expect(pv.getGuid().toString(), equals(IID_ICalendar));

      pv.release();
    });

    test('GuidArray', () {
      final array = calloc<GUID>(3);
      array[0].setGUID(IID_ICalendar);
      array[1].setGUID(IID_IFileOpenPicker);
      array[2].setGUID(IID_IStorageItem);
      final pv = PropertyValue.createGuidArray(3, array);
      expect(pv.type, equals(PropertyType.guidArray));

      final arraySize = calloc<Uint32>();
      final newArray = calloc<Pointer<GUID>>();

      pv.getGuidArray(arraySize, newArray);
      expect(arraySize.value, equals(3));
      expect(newArray.value[0].toString(), equals(IID_ICalendar));
      expect(newArray.value[1].toString(), equals(IID_IFileOpenPicker));
      expect(newArray.value[2].toString(), equals(IID_IStorageItem));

      pv.release();
    });

    test('Inspectable', () {
      final calendar = Calendar();
      final pv = PropertyValue.createInspectable(calendar.ptr);
      expect(IInspectable(pv).runtimeClassName,
          equals('Windows.Globalization.Calendar'));

      calendar.release();
    });

    test('InspectableArray', () {
      final calendar = Calendar();
      final formatter = PhoneNumberFormatter();
      final array = calloc<COMObject>(2);
      array[0] = calendar.ptr.ref;
      array[1] = formatter.ptr.ref;
      final pv = PropertyValue.createInspectableArray(2, array);
      expect(pv.type, equals(PropertyType.inspectableArray));

      final arraySize = calloc<Uint32>();
      final newArray = calloc<Pointer<COMObject>>();

      pv.getInspectableArray(arraySize, newArray);
      expect(arraySize.value, equals(2));
      final list = newArray.value.toList(IInspectable.new, length: 2);
      final firstElement = list.first;
      final lastElement = list.last;
      expect(firstElement.runtimeClassName,
          equals('Windows.Globalization.Calendar'));
      expect(
          lastElement.runtimeClassName,
          equals(
              'Windows.Globalization.PhoneNumberFormatting.PhoneNumberFormatter'));

      lastElement.release();
      firstElement.release();
      free(newArray);
      pv.release();
      free(array);
    });
  }
}
