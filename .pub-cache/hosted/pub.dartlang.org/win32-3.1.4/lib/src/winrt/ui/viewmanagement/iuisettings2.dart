// iuisettings2.dart

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
import '../../internal/hstring_array.dart';
import 'uisettings.dart';

/// @nodoc
const IID_IUISettings2 = '{bad82401-2721-44f9-bb91-2bb228be442f}';

/// {@category Interface}
/// {@category winrt}
class IUISettings2 extends IInspectable {
  // vtable begins at 6, is 3 entries long.
  IUISettings2.fromRawPointer(super.ptr);

  factory IUISettings2.from(IInspectable interface) =>
      IUISettings2.fromRawPointer(interface.toInterface(IID_IUISettings2));

  double get textScaleFactor {
    final retValuePtr = calloc<Double>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Double>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Double>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int add_TextScaleFactorChanged(
      Pointer<NativeFunction<TypedEventHandler>> handler) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<TypedEventHandler>> handler,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<NativeFunction<TypedEventHandler>> handler,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, handler, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_TextScaleFactorChanged(int cookie) {
    final hr = ptr.ref.vtable
        .elementAt(8)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr cookie)>>>()
        .value
        .asFunction<
            int Function(Pointer, int cookie)>()(ptr.ref.lpVtbl, cookie);

    if (FAILED(hr)) throw WindowsException(hr);
  }
}
