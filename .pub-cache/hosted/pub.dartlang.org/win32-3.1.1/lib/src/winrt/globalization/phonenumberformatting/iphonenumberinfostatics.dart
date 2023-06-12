// iphonenumberinfostatics.dart

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

import 'phonenumberinfo.dart';
import 'enums.g.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IPhoneNumberInfoStatics = '{5B3F4F6A-86A9-40E9-8649-6D61161928D4}';

/// {@category Interface}
/// {@category winrt}
class IPhoneNumberInfoStatics extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IPhoneNumberInfoStatics.fromRawPointer(super.ptr);

  factory IPhoneNumberInfoStatics.from(IInspectable interface) =>
      IPhoneNumberInfoStatics.fromRawPointer(
          interface.toInterface(IID_IPhoneNumberInfoStatics));

  PhoneNumberParseResult tryParse(String input, PhoneNumberInfo phoneNumber) {
    final retValuePtr = calloc<Int32>();
    final inputHstring = convertToHString(input);

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer,
                                  IntPtr input,
                                  Pointer<COMObject> phoneNumber,
                                  Pointer<Int32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int input,
                          Pointer<COMObject> phoneNumber, Pointer<Int32>)>()(
              ptr.ref.lpVtbl, inputHstring, phoneNumber.ptr, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return PhoneNumberParseResult.from(retValuePtr.value);
    } finally {
      WindowsDeleteString(inputHstring);

      free(retValuePtr);
    }
  }

  PhoneNumberParseResult tryParseWithRegion(
      String input, String regionCode, PhoneNumberInfo phoneNumber) {
    final retValuePtr = calloc<Int32>();
    final inputHstring = convertToHString(input);
    final regionCodeHstring = convertToHString(regionCode);

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(7)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer,
                                  IntPtr input,
                                  IntPtr regionCode,
                                  Pointer<COMObject> phoneNumber,
                                  Pointer<Int32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int input, int regionCode,
                          Pointer<COMObject> phoneNumber, Pointer<Int32>)>()(
              ptr.ref.lpVtbl,
              inputHstring,
              regionCodeHstring,
              phoneNumber.ptr,
              retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return PhoneNumberParseResult.from(retValuePtr.value);
    } finally {
      WindowsDeleteString(inputHstring);
      WindowsDeleteString(regionCodeHstring);

      free(retValuePtr);
    }
  }
}
