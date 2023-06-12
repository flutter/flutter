// iwwwformurldecoderruntimeclassfactory.dart

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
import 'wwwformurldecoder.dart';

/// @nodoc
const IID_IWwwFormUrlDecoderRuntimeClassFactory =
    '{5b8c6b3d-24ae-41b5-a1bf-f0c3d544845b}';

/// {@category Interface}
/// {@category winrt}
class IWwwFormUrlDecoderRuntimeClassFactory extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IWwwFormUrlDecoderRuntimeClassFactory.fromRawPointer(super.ptr);

  factory IWwwFormUrlDecoderRuntimeClassFactory.from(IInspectable interface) =>
      IWwwFormUrlDecoderRuntimeClassFactory.fromRawPointer(
          interface.toInterface(IID_IWwwFormUrlDecoderRuntimeClassFactory));

  WwwFormUrlDecoder createWwwFormUrlDecoder(String query) {
    final retValuePtr = calloc<COMObject>();
    final queryHstring = convertToHString(query);
    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr query, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int query, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, queryHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(queryHstring);
    return WwwFormUrlDecoder.fromRawPointer(retValuePtr);
  }
}
