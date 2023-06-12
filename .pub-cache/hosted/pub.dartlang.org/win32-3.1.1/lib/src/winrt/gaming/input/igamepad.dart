// igamepad.dart

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

import 'igamecontroller.dart';
import 'structs.g.dart';
import 'headset.dart';
import '../../system/userchangedeventargs.dart';
import '../../system/user.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IGamepad = '{BC7BB43C-0A69-3903-9E9D-A50F86A45DE5}';

/// {@category Interface}
/// {@category winrt}
class IGamepad extends IInspectable implements IGameController {
  // vtable begins at 6, is 3 entries long.
  IGamepad.fromRawPointer(super.ptr);

  factory IGamepad.from(IInspectable interface) =>
      IGamepad.fromRawPointer(interface.toInterface(IID_IGamepad));

  GamepadVibration get vibration {
    final retValuePtr = calloc<GamepadVibration>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(Pointer, Pointer<GamepadVibration>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<GamepadVibration>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  set vibration(GamepadVibration value) {
    final hr = ptr.ref.vtable
        .elementAt(7)
        .cast<
            Pointer<
                NativeFunction<HRESULT Function(Pointer, GamepadVibration)>>>()
        .value
        .asFunction<
            int Function(Pointer, GamepadVibration)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  GamepadReading getCurrentReading() {
    final retValuePtr = calloc<GamepadReading>();

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(8)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, Pointer<GamepadReading>)>>>()
                  .value
                  .asFunction<int Function(Pointer, Pointer<GamepadReading>)>()(
              ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  // IGameController methods
  late final _iGameController = IGameController.from(this);

  @override
  int add_HeadsetConnected(Pointer<NativeFunction<TypedEventHandler>> value) =>
      _iGameController.add_HeadsetConnected(value);

  @override
  void remove_HeadsetConnected(int token) =>
      _iGameController.remove_HeadsetConnected(token);

  @override
  int add_HeadsetDisconnected(
          Pointer<NativeFunction<TypedEventHandler>> value) =>
      _iGameController.add_HeadsetDisconnected(value);

  @override
  void remove_HeadsetDisconnected(int token) =>
      _iGameController.remove_HeadsetDisconnected(token);

  @override
  int add_UserChanged(Pointer<NativeFunction<TypedEventHandler>> value) =>
      _iGameController.add_UserChanged(value);

  @override
  void remove_UserChanged(int token) =>
      _iGameController.remove_UserChanged(token);

  @override
  Headset get headset => _iGameController.headset;

  @override
  bool get isWireless => _iGameController.isWireless;

  @override
  User get user => _iGameController.user;
}
