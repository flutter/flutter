// iipinformation.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/ireference.dart';
import '../../internal/hstring_array.dart';
import '../../internal/ipropertyvalue_helpers.dart';
import 'networkadapter.dart';

/// @nodoc
const IID_IIPInformation = '{d85145e0-138f-47d7-9b3a-36bb488cef33}';

/// {@category Interface}
/// {@category winrt}
class IIPInformation extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IIPInformation.fromRawPointer(super.ptr);

  factory IIPInformation.from(IInspectable interface) =>
      IIPInformation.fromRawPointer(interface.toInterface(IID_IIPInformation));

  NetworkAdapter? get networkAdapter {
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

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return NetworkAdapter.fromRawPointer(retValuePtr);
  }

  int? get prefixLength {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(7)
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

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    final reference = IReference<int>.fromRawPointer(retValuePtr,
        referenceIid: '{e5198cc8-2873-55f5-b0a1-84ff9e4aad62}');
    final value = reference.value;
    reference.release();

    return value;
  }
}
