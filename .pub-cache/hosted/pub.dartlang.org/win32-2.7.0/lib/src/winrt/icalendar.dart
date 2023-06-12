// icalendar.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../combase.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../utils.dart';
import '../types.dart';
import '../winrt_helpers.dart';

import '../extensions/hstring_array.dart';
import 'ivector.dart';
import 'ivectorview.dart';

import '../com/iinspectable.dart';

/// @nodoc
const IID_ICalendar = '{CA30221D-86D9-40FB-A26B-D44EB7CF08EA}';

/// {@category Interface}
/// {@category winrt}
class ICalendar extends IInspectable {
  // vtable begins at 6, is 98 entries long.
  ICalendar(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_ICalendar);

  Pointer<COMObject> Clone() {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        _thisPtr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr;
  }

  void SetToMin() {
    final hr = _thisPtr.ref.vtable
        .elementAt(7)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(_thisPtr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void SetToMax() {
    final hr = _thisPtr.ref.vtable
        .elementAt(8)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(_thisPtr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  List<String> get Languages {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(9)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        _thisPtr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    try {
      return IVectorView<String>(retValuePtr).toList();
    } finally {
      free(retValuePtr);
    }
  }

  String get NumeralSystem {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  set NumeralSystem(String value) {
    final hstr = convertToHString(value);

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(11)
          .cast<Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr)>>>()
          .value
          .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, hstr);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hstr);
    }
  }

  String GetCalendarSystem() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  void ChangeCalendarSystem(String value) {
    final valueHstring = convertToHString(value);
    final hr = _thisPtr.ref.vtable
        .elementAt(13)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr value)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, int value)>()(_thisPtr.ref.lpVtbl, valueHstring);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(valueHstring);
  }

  String GetClock() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(14)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  void ChangeClock(String value) {
    final valueHstring = convertToHString(value);
    final hr = _thisPtr.ref.vtable
        .elementAt(15)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr value)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, int value)>()(_thisPtr.ref.lpVtbl, valueHstring);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(valueHstring);
  }

  DateTime GetDateTime() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(16)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Uint64>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return DateTime.utc(1601, 01, 01)
          .add(Duration(microseconds: retValuePtr.value ~/ 10));
    } finally {
      free(retValuePtr);
    }
  }

  void SetDateTime(DateTime value) {
    final valueDateTime =
        value.difference(DateTime.utc(1601, 01, 01)).inMicroseconds * 10;
    final hr = _thisPtr.ref.vtable
        .elementAt(17)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Uint64 value)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, int value)>()(_thisPtr.ref.lpVtbl, valueDateTime);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void SetToNow() {
    final hr = _thisPtr.ref.vtable
        .elementAt(18)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(_thisPtr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get FirstEra {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(19)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastEra {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(20)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfEras {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(21)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get Era {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(22)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Era(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(23)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddEras(int eras) {
    final hr = _thisPtr.ref.vtable
        .elementAt(24)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32 eras)>>>()
        .value
        .asFunction<
            int Function(Pointer, int eras)>()(_thisPtr.ref.lpVtbl, eras);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String EraAsFullString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(25)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String EraAsString(int idealLength) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(26)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 idealLength, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int idealLength, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, idealLength, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get FirstYearInThisEra {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(27)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastYearInThisEra {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(28)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfYearsInThisEra {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(29)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get Year {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(30)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Year(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(31)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddYears(int years) {
    final hr = _thisPtr.ref.vtable
        .elementAt(32)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32 years)>>>()
        .value
        .asFunction<
            int Function(Pointer, int years)>()(_thisPtr.ref.lpVtbl, years);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String YearAsString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(33)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String YearAsTruncatedString(int remainingDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(34)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Int32 remainingDigits,
                              Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int remainingDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, remainingDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String YearAsPaddedString(int minDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(35)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 minDigits, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int minDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, minDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get FirstMonthInThisYear {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(36)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastMonthInThisYear {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(37)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfMonthsInThisYear {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(38)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get Month {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(39)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Month(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(40)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddMonths(int months) {
    final hr = _thisPtr.ref.vtable
        .elementAt(41)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Int32 months)>>>()
        .value
        .asFunction<
            int Function(Pointer, int months)>()(_thisPtr.ref.lpVtbl, months);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String MonthAsFullString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(42)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String MonthAsString(int idealLength) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(43)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 idealLength, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int idealLength, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, idealLength, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String MonthAsFullSoloString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(44)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String MonthAsSoloString(int idealLength) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(45)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 idealLength, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int idealLength, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, idealLength, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String MonthAsNumericString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(46)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String MonthAsPaddedNumericString(int minDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(47)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 minDigits, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int minDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, minDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  void AddWeeks(int weeks) {
    final hr = _thisPtr.ref.vtable
        .elementAt(48)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32 weeks)>>>()
        .value
        .asFunction<
            int Function(Pointer, int weeks)>()(_thisPtr.ref.lpVtbl, weeks);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get FirstDayInThisMonth {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(49)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastDayInThisMonth {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(50)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfDaysInThisMonth {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(51)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get Day {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(52)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Day(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(53)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddDays(int days) {
    final hr = _thisPtr.ref.vtable
        .elementAt(54)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32 days)>>>()
        .value
        .asFunction<
            int Function(Pointer, int days)>()(_thisPtr.ref.lpVtbl, days);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String DayAsString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(55)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String DayAsPaddedString(int minDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(56)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 minDigits, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int minDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, minDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get DayOfWeek {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(57)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  String DayOfWeekAsFullString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(58)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String DayOfWeekAsString(int idealLength) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(59)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 idealLength, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int idealLength, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, idealLength, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String DayOfWeekAsFullSoloString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(60)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String DayOfWeekAsSoloString(int idealLength) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(61)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 idealLength, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int idealLength, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, idealLength, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get FirstPeriodInThisDay {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(62)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastPeriodInThisDay {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(63)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfPeriodsInThisDay {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(64)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get Period {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(65)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Period(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(66)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddPeriods(int periods) {
    final hr = _thisPtr.ref.vtable
        .elementAt(67)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Int32 periods)>>>()
        .value
        .asFunction<
            int Function(Pointer, int periods)>()(_thisPtr.ref.lpVtbl, periods);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String PeriodAsFullString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(68)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String PeriodAsString(int idealLength) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(69)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 idealLength, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int idealLength, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, idealLength, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get FirstHourInThisPeriod {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(70)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastHourInThisPeriod {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(71)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfHoursInThisPeriod {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(72)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get Hour {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(73)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Hour(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(74)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddHours(int hours) {
    final hr = _thisPtr.ref.vtable
        .elementAt(75)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32 hours)>>>()
        .value
        .asFunction<
            int Function(Pointer, int hours)>()(_thisPtr.ref.lpVtbl, hours);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String HourAsString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(76)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String HourAsPaddedString(int minDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(77)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 minDigits, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int minDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, minDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get Minute {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(78)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Minute(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(79)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddMinutes(int minutes) {
    final hr = _thisPtr.ref.vtable
        .elementAt(80)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Int32 minutes)>>>()
        .value
        .asFunction<
            int Function(Pointer, int minutes)>()(_thisPtr.ref.lpVtbl, minutes);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String MinuteAsString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(81)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String MinuteAsPaddedString(int minDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(82)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 minDigits, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int minDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, minDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get Second {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(83)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Second(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(84)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddSeconds(int seconds) {
    final hr = _thisPtr.ref.vtable
        .elementAt(85)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Int32 seconds)>>>()
        .value
        .asFunction<
            int Function(Pointer, int seconds)>()(_thisPtr.ref.lpVtbl, seconds);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String SecondAsString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(86)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String SecondAsPaddedString(int minDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(87)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 minDigits, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int minDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, minDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get Nanosecond {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(88)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Nanosecond(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(89)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void AddNanoseconds(int nanoseconds) {
    final hr = _thisPtr.ref.vtable
        .elementAt(90)
        .cast<
            Pointer<
                NativeFunction<HRESULT Function(Pointer, Int32 nanoseconds)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, int nanoseconds)>()(_thisPtr.ref.lpVtbl, nanoseconds);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String NanosecondAsString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(91)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String NanosecondAsPaddedString(int minDigits) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(92)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32 minDigits, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int minDigits, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, minDigits, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int Compare(Pointer<COMObject> other) {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(93)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<COMObject> other,
                              Pointer<Int32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, Pointer<COMObject> other, Pointer<Int32>)>()(
          _thisPtr.ref.lpVtbl,
          other.cast<Pointer<COMObject>>().value,
          retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int CompareDateTime(DateTime other) {
    final retValuePtr = calloc<Int32>();
    final otherDateTime =
        other.difference(DateTime.utc(1601, 01, 01)).inMicroseconds * 10;

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(94)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Uint64 other, Pointer<Int32>)>>>()
              .value
              .asFunction<int Function(Pointer, int other, Pointer<Int32>)>()(
          _thisPtr.ref.lpVtbl, otherDateTime, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void CopyTo(Pointer<COMObject> other) {
    final hr = _thisPtr.ref.vtable
            .elementAt(95)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject> other)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject> other)>()(
        _thisPtr.ref.lpVtbl, other.cast<Pointer<COMObject>>().value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get FirstMinuteInThisHour {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(96)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastMinuteInThisHour {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(97)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfMinutesInThisHour {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(98)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get FirstSecondInThisMinute {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(99)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get LastSecondInThisMinute {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(100)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get NumberOfSecondsInThisMinute {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(101)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  String get ResolvedLanguage {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(102)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  bool get IsDaylightSavingTime {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(103)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }
}
