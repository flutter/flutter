// iphonenumberformatterstatics.dart

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
const IID_IPhoneNumberFormatterStatics =
    '{5CA6F931-84D9-414B-AB4E-A0552C878602}';

/// {@category Interface}
/// {@category winrt}
class IPhoneNumberFormatterStatics extends IInspectable {
  // vtable begins at 6, is 4 entries long.
  IPhoneNumberFormatterStatics(super.ptr);

  late final Pointer<COMObject> _thisPtr =
      toInterface(IID_IPhoneNumberFormatterStatics);

  void TryCreate(String regionCode, Pointer<COMObject> phoneNumber) {
    final regionCodeHstring = convertToHString(regionCode);

    final hr = _thisPtr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, IntPtr regionCode,
                            Pointer<COMObject> phoneNumber)>>>()
            .value
            .asFunction<
                int Function(
                    Pointer, int regionCode, Pointer<COMObject> phoneNumber)>()(
        _thisPtr.ref.lpVtbl, regionCodeHstring, phoneNumber);

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(regionCodeHstring);
  }

  int GetCountryCodeForRegion(String regionCode) {
    final retValuePtr = calloc<Int32>();
    final regionCodeHstring = convertToHString(regionCode);

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr regionCode, Pointer<Int32>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int regionCode, Pointer<Int32>)>()(
          _thisPtr.ref.lpVtbl, regionCodeHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(regionCodeHstring);
      free(retValuePtr);
    }
  }

  String GetNationalDirectDialingPrefixForRegion(
      String regionCode, bool stripNonDigit) {
    final retValuePtr = calloc<HSTRING>();
    final regionCodeHstring = convertToHString(regionCode);

    try {
      final hr = _thisPtr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, IntPtr regionCode,
                              Bool stripNonDigit, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int regionCode, bool stripNonDigit,
                      Pointer<IntPtr>)>()(
          _thisPtr.ref.lpVtbl, regionCodeHstring, stripNonDigit, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(regionCodeHstring);

      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String WrapWithLeftToRightMarkers(String number) {
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
}
