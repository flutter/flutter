// ihostnamestatics.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';
import '../internal/hstring_array.dart';

/// @nodoc
const IID_IHostNameStatics = '{f68cd4bf-a388-4e8b-91ea-54dd6dd901c0}';

/// {@category Interface}
/// {@category winrt}
class IHostNameStatics extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IHostNameStatics.fromRawPointer(super.ptr);

  factory IHostNameStatics.from(IInspectable interface) =>
      IHostNameStatics.fromRawPointer(
          interface.toInterface(IID_IHostNameStatics));

  int compare(String value1, String value2) {
    final retValuePtr = calloc<Int32>();
    final value1Hstring = convertToHString(value1);
    final value2Hstring = convertToHString(value2);

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, IntPtr value1,
                                  IntPtr value2, Pointer<Int32>)>>>()
                  .value
                  .asFunction<
                      int Function(
                          Pointer, int value1, int value2, Pointer<Int32>)>()(
              ptr.ref.lpVtbl, value1Hstring, value2Hstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      WindowsDeleteString(value1Hstring);
      WindowsDeleteString(value2Hstring);
      free(retValuePtr);
    }
  }
}
