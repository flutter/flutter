// iwwwformurldecoderruntimeclass.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../../winrt/internal/hstring_array.dart';

import '../../com/iinspectable.dart';

/// @nodoc
const IID_IWwwFormUrlDecoderRuntimeClass =
    '{D45A0451-F225-4542-9296-0E1DF5D254DF}';

/// {@category Interface}
/// {@category winrt}
class IWwwFormUrlDecoderRuntimeClass extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IWwwFormUrlDecoderRuntimeClass.fromRawPointer(super.ptr);

  factory IWwwFormUrlDecoderRuntimeClass.from(IInspectable interface) =>
      IWwwFormUrlDecoderRuntimeClass.fromRawPointer(
          interface.toInterface(IID_IWwwFormUrlDecoderRuntimeClass));

  String getFirstValueByName(String name) {
    final retValuePtr = calloc<HSTRING>();
    final nameHstring = convertToHString(name);

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr name, Pointer<IntPtr>)>>>()
              .value
              .asFunction<int Function(Pointer, int name, Pointer<IntPtr>)>()(
          ptr.ref.lpVtbl, nameHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(nameHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }
}
