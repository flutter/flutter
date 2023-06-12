// iwwwformurldecoderruntimeclassfactory.dart

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

import '../../winrt/foundation/wwwformurldecoder.dart';
import '../../com/iinspectable.dart';

/// @nodoc
const IID_IWwwFormUrlDecoderRuntimeClassFactory =
    '{5B8C6B3D-24AE-41B5-A1BF-F0C3D544845B}';

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

    if (FAILED(hr)) throw WindowsException(hr);

    WindowsDeleteString(queryHstring);
    return WwwFormUrlDecoder.fromRawPointer(retValuePtr);
  }
}
