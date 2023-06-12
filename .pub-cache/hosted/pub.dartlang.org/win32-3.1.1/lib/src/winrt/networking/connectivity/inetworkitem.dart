// inetworkitem.dart

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

import '../../../guid.dart';
import 'enums.g.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_INetworkItem = '{01BC4D39-F5E0-4567-A28C-42080C831B2B}';

/// {@category Interface}
/// {@category winrt}
class INetworkItem extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  INetworkItem.fromRawPointer(super.ptr);

  factory INetworkItem.from(IInspectable interface) =>
      INetworkItem.fromRawPointer(interface.toInterface(IID_INetworkItem));

  GUID get networkId {
    final retValuePtr = calloc<GUID>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<GUID>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<GUID>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  NetworkTypes getNetworkTypes() {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return NetworkTypes.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }
}
