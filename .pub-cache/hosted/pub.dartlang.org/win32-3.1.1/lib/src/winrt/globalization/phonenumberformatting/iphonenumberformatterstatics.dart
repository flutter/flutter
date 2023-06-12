// iphonenumberformatterstatics.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../internal/hstring_array.dart';

import 'phonenumberformatter.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IPhoneNumberFormatterStatics =
    '{5CA6F931-84D9-414B-AB4E-A0552C878602}';

/// {@category Interface}
/// {@category winrt}
class IPhoneNumberFormatterStatics extends IInspectable {
  // vtable begins at 6, is 4 entries long.
  IPhoneNumberFormatterStatics.fromRawPointer(super.ptr);

  factory IPhoneNumberFormatterStatics.from(IInspectable interface) =>
      IPhoneNumberFormatterStatics.fromRawPointer(
          interface.toInterface(IID_IPhoneNumberFormatterStatics));

  void tryCreate(String regionCode, PhoneNumberFormatter phoneNumber) {
    final regionCodeHstring = convertToHString(regionCode);

    final hr = ptr.ref.vtable
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
        ptr.ref.lpVtbl, regionCodeHstring, phoneNumber.ptr);

    if (FAILED(hr)) throw WindowsException(hr);
    WindowsDeleteString(regionCodeHstring);
  }

  int getCountryCodeForRegion(String regionCode) {
    final retValuePtr = calloc<Int32>();
    final regionCodeHstring = convertToHString(regionCode);

    try {
      final hr = ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr regionCode, Pointer<Int32>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int regionCode, Pointer<Int32>)>()(
          ptr.ref.lpVtbl, regionCodeHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(regionCodeHstring);
      free(retValuePtr);
    }
  }

  String getNationalDirectDialingPrefixForRegion(
      String regionCode, bool stripNonDigit) {
    final retValuePtr = calloc<HSTRING>();
    final regionCodeHstring = convertToHString(regionCode);

    try {
      final hr = ptr.ref.vtable
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
          ptr.ref.lpVtbl, regionCodeHstring, stripNonDigit, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(regionCodeHstring);

      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String wrapWithLeftToRightMarkers(String number) {
    final retValuePtr = calloc<HSTRING>();
    final numberHstring = convertToHString(number);

    try {
      final hr = ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr number, Pointer<IntPtr>)>>>()
              .value
              .asFunction<int Function(Pointer, int number, Pointer<IntPtr>)>()(
          ptr.ref.lpVtbl, numberHstring, retValuePtr);

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
