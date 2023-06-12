// igamepadstatics.dart

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

import 'gamepad.dart';
import '../../foundation/collections/ivectorview.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IGamepadStatics = '{8BBCE529-D49C-39E9-9560-E47DDE96B7C8}';

/// {@category Interface}
/// {@category winrt}
class IGamepadStatics extends IInspectable {
  // vtable begins at 6, is 5 entries long.
  IGamepadStatics.fromRawPointer(super.ptr);

  factory IGamepadStatics.from(IInspectable interface) =>
      IGamepadStatics.fromRawPointer(
          interface.toInterface(IID_IGamepadStatics));

  int add_GamepadAdded(Pointer<NativeFunction<EventHandler>> value) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<EventHandler>> value,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<NativeFunction<EventHandler>> value,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_GamepadAdded(int token) {
    final hr = ptr.ref.vtable
        .elementAt(7)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<int Function(Pointer, int token)>()(ptr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int add_GamepadRemoved(Pointer<NativeFunction<EventHandler>> value) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<EventHandler>> value,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<NativeFunction<EventHandler>> value,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_GamepadRemoved(int token) {
    final hr = ptr.ref.vtable
        .elementAt(9)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<int Function(Pointer, int token)>()(ptr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  List<Gamepad> get gamepads {
    final retValuePtr = calloc<COMObject>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<COMObject>)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);
      return IVectorView<Gamepad>.fromRawPointer(retValuePtr,
              creator: Gamepad.fromRawPointer)
          .toList();
    } finally {
      free(retValuePtr);
    }
  }
}
