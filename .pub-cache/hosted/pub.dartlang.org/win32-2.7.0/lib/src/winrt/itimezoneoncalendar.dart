// itimezoneoncalendar.dart

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
const IID_ITimeZoneOnCalendar = '{BB3C25E5-46CF-4317-A3F5-02621AD54478}';

/// {@category Interface}
/// {@category winrt}
class ITimeZoneOnCalendar extends IInspectable {
  // vtable begins at 6, is 4 entries long.
  ITimeZoneOnCalendar(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_ITimeZoneOnCalendar);

  String GetTimeZone() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(6)
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

  void ChangeTimeZone(String timeZoneId) {
    final timeZoneIdHstring = convertToHString(timeZoneId);
    final hr = _thisPtr.ref.vtable
        .elementAt(7)
        .cast<
            Pointer<
                NativeFunction<HRESULT Function(Pointer, IntPtr timeZoneId)>>>()
        .value
        .asFunction<
            int Function(Pointer,
                int timeZoneId)>()(_thisPtr.ref.lpVtbl, timeZoneIdHstring);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(timeZoneIdHstring);
  }

  String TimeZoneAsFullString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(8)
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

  String TimeZoneAsString(int idealLength) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(9)
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
}
