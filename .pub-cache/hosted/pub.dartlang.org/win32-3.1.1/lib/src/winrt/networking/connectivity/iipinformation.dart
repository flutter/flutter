// iipinformation.dart

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

import 'networkadapter.dart';
import '../../foundation/ireference.dart';
import '../../internal/ipropertyvalue_helpers.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IIPInformation = '{D85145E0-138F-47D7-9B3A-36BB488CEF33}';

/// {@category Interface}
/// {@category winrt}
class IIPInformation extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IIPInformation.fromRawPointer(super.ptr);

  factory IIPInformation.from(IInspectable interface) =>
      IIPInformation.fromRawPointer(interface.toInterface(IID_IIPInformation));

  NetworkAdapter get networkAdapter {
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

    return NetworkAdapter.fromRawPointer(retValuePtr);
  }

  int? get prefixLength {
    final retValuePtr = calloc<COMObject>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<COMObject>)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);
      return IReference<int>.fromRawPointer(retValuePtr).value;
    } finally {
      free(retValuePtr);
    }
  }
}
