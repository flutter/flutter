// ipropertyvalue.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../internal/hstring_array.dart';

import 'enums.g.dart';
import '../../guid.dart';
import 'structs.g.dart';
import '../../com/iinspectable.dart';

/// @nodoc
const IID_IPropertyValue = '{4BD682DD-7554-40E9-9A9B-82654EDE7E62}';

/// {@category Interface}
/// {@category winrt}
class IPropertyValue extends IInspectable {
  // vtable begins at 6, is 39 entries long.
  IPropertyValue.fromRawPointer(super.ptr);

  factory IPropertyValue.from(IInspectable interface) =>
      IPropertyValue.fromRawPointer(interface.toInterface(IID_IPropertyValue));

  PropertyType get type {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return PropertyType.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }

  bool get isNumericScalar {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getUInt8() {
    final retValuePtr = calloc<Uint8>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint8>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint8>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getInt16() {
    final retValuePtr = calloc<Int16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getUInt16() {
    final retValuePtr = calloc<Uint16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getInt32() {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getUInt32() {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getInt64() {
    final retValuePtr = calloc<Int64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getUInt64() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(14)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  double getSingle() {
    final retValuePtr = calloc<Float>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(15)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Float>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Float>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  double getDouble() {
    final retValuePtr = calloc<Double>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(16)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Double>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Double>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getChar16() {
    final retValuePtr = calloc<Uint16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(17)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  bool getBoolean() {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(18)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  String getString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(19)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<IntPtr>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  GUID getGuid() {
    final retValuePtr = calloc<GUID>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(20)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<GUID>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<GUID>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  DateTime getDateTime() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(21)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return DateTime.utc(1601, 01, 01)
          .add(Duration(microseconds: retValuePtr.value ~/ 10));
    } finally {
      free(retValuePtr);
    }
  }

  Duration getTimeSpan() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(22)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return Duration(microseconds: retValuePtr.value ~/ 10);
    } finally {
      free(retValuePtr);
    }
  }

  Point getPoint() {
    final retValuePtr = calloc<Point>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(23)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Point>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Point>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  Size getSize() {
    final retValuePtr = calloc<Size>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(24)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Size>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Size>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  Rect getRect() {
    final retValuePtr = calloc<Rect>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(25)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Rect>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Rect>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  void getUInt8Array(Pointer<Uint32> valueSize, Pointer<Pointer<Uint8>> value) {
    final hr = ptr.ref.vtable
            .elementAt(26)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Uint8>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Uint8>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getInt16Array(Pointer<Uint32> valueSize, Pointer<Pointer<Int16>> value) {
    final hr = ptr.ref.vtable
            .elementAt(27)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Int16>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Int16>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getUInt16Array(
      Pointer<Uint32> valueSize, Pointer<Pointer<Uint16>> value) {
    final hr = ptr.ref.vtable
            .elementAt(28)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Uint16>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Uint16>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getInt32Array(Pointer<Uint32> valueSize, Pointer<Pointer<Int32>> value) {
    final hr = ptr.ref.vtable
            .elementAt(29)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Int32>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Int32>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getUInt32Array(
      Pointer<Uint32> valueSize, Pointer<Pointer<Uint32>> value) {
    final hr = ptr.ref.vtable
            .elementAt(30)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Uint32>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Uint32>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getInt64Array(Pointer<Uint32> valueSize, Pointer<Pointer<Int64>> value) {
    final hr = ptr.ref.vtable
            .elementAt(31)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Int64>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Int64>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getUInt64Array(
      Pointer<Uint32> valueSize, Pointer<Pointer<Uint64>> value) {
    final hr = ptr.ref.vtable
            .elementAt(32)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Uint64>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Uint64>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getSingleArray(
      Pointer<Uint32> valueSize, Pointer<Pointer<Float>> value) {
    final hr = ptr.ref.vtable
            .elementAt(33)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Float>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Float>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getDoubleArray(
      Pointer<Uint32> valueSize, Pointer<Pointer<Double>> value) {
    final hr = ptr.ref.vtable
            .elementAt(34)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Double>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Double>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getChar16Array(
      Pointer<Uint32> valueSize, Pointer<Pointer<Uint16>> value) {
    final hr = ptr.ref.vtable
            .elementAt(35)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Uint16>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Uint16>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getBooleanArray(
      Pointer<Uint32> valueSize, Pointer<Pointer<Bool>> value) {
    final hr = ptr.ref.vtable
            .elementAt(36)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Bool>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Bool>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getStringArray(
      Pointer<Uint32> valueSize, Pointer<Pointer<IntPtr>> value) {
    final hr = ptr.ref.vtable
            .elementAt(37)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<IntPtr>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<IntPtr>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getInspectableArray(
      Pointer<Uint32> valueSize, Pointer<Pointer<COMObject>> value) {
    final hr = ptr.ref.vtable
            .elementAt(38)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<COMObject>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<COMObject>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getGuidArray(Pointer<Uint32> valueSize, Pointer<Pointer<GUID>> value) {
    final hr = ptr.ref.vtable
            .elementAt(39)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<GUID>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<GUID>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getDateTimeArray(
      Pointer<Uint32> valueSize, Pointer<Pointer<Uint64>> value) {
    final hr = ptr.ref.vtable
            .elementAt(40)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Uint64>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Uint64>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getTimeSpanArray(
      Pointer<Uint32> valueSize, Pointer<Pointer<Uint64>> value) {
    final hr = ptr.ref.vtable
            .elementAt(41)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Uint64>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Uint64>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getPointArray(Pointer<Uint32> valueSize, Pointer<Pointer<Point>> value) {
    final hr = ptr.ref.vtable
            .elementAt(42)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Point>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Point>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getSizeArray(Pointer<Uint32> valueSize, Pointer<Pointer<Size>> value) {
    final hr = ptr.ref.vtable
            .elementAt(43)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Size>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Size>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void getRectArray(Pointer<Uint32> valueSize, Pointer<Pointer<Rect>> value) {
    final hr = ptr.ref.vtable
            .elementAt(44)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<Uint32> valueSize,
                            Pointer<Pointer<Rect>> value)>>>()
            .value
            .asFunction<
                int Function(Pointer, Pointer<Uint32> valueSize,
                    Pointer<Pointer<Rect>> value)>()(
        ptr.ref.lpVtbl, valueSize, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }
}
