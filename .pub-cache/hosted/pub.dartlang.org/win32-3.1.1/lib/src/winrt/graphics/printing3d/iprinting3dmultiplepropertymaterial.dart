// iprinting3dmultiplepropertymaterial.dart

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

import '../../foundation/collections/ivector.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IPrinting3DMultiplePropertyMaterial =
    '{25A6254B-C6E9-484D-A214-A25E5776BA62}';

/// {@category Interface}
/// {@category winrt}
class IPrinting3DMultiplePropertyMaterial extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IPrinting3DMultiplePropertyMaterial.fromRawPointer(super.ptr);

  factory IPrinting3DMultiplePropertyMaterial.from(IInspectable interface) =>
      IPrinting3DMultiplePropertyMaterial.fromRawPointer(
          interface.toInterface(IID_IPrinting3DMultiplePropertyMaterial));

  IVector<int> get materialIndices {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return IVector.fromRawPointer(retValuePtr, intType: Uint32);
  }
}
