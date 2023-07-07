// iphonenumberformatter.dart

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
const IID_IPhoneNumberFormatter = '{1556B49E-BAD4-4B4A-900D-4407ADB7C981}';

/// {@category Interface}
/// {@category winrt}
class IPhoneNumberFormatter extends IInspectable {
  // vtable begins at 6, is 5 entries long.
  IPhoneNumberFormatter(super.ptr);

  late final Pointer<COMObject> _thisPtr =
      toInterface(IID_IPhoneNumberFormatter);

  String Format(Pointer<COMObject> number) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<COMObject> number,
                              Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, Pointer<COMObject> number, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl,
          number.cast<Pointer<COMObject>>().value,
          retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String FormatWithOutputFormat(Pointer<COMObject> number, int numberFormat) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<COMObject> number,
                              Int32 numberFormat, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> number,
                      int numberFormat, Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl,
          number.cast<Pointer<COMObject>>().value, numberFormat, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String FormatPartialString(String number) {
    final retValuePtr = calloc<HSTRING>();
    final numberHstring = convertToHString(number);

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr number, Pointer<IntPtr>)>>>()
              .value
              .asFunction<int Function(Pointer, int number, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, numberHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(numberHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String FormatString(String number) {
    final retValuePtr = calloc<HSTRING>();
    final numberHstring = convertToHString(number);

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr number, Pointer<IntPtr>)>>>()
              .value
              .asFunction<int Function(Pointer, int number, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, numberHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(numberHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String FormatStringWithLeftToRightMarkers(String number) {
    final retValuePtr = calloc<HSTRING>();
    final numberHstring = convertToHString(number);

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr number, Pointer<IntPtr>)>>>()
              .value
              .asFunction<int Function(Pointer, int number, Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, numberHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(numberHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }
}
