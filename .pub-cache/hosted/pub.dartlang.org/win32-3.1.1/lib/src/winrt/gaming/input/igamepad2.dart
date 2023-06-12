// igamepad2.dart

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

import 'igamepad.dart';
import 'igamecontroller.dart';
import 'enums.g.dart';
import 'structs.g.dart';
import 'headset.dart';
import '../../system/userchangedeventargs.dart';
import '../../system/user.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IGamepad2 = '{3C1689BD-5915-4245-B0C0-C89FAE0308FF}';

/// {@category Interface}
/// {@category winrt}
class IGamepad2 extends IInspectable implements IGamepad, IGameController {
  // vtable begins at 6, is 1 entries long.
  IGamepad2.fromRawPointer(super.ptr);

  factory IGamepad2.from(IInspectable interface) =>
      IGamepad2.fromRawPointer(interface.toInterface(IID_IGamepad2));

  GameControllerButtonLabel getButtonLabel(GamepadButtons button) {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Uint32 button, Pointer<Int32>)>>>()
              .value
              .asFunction<int Function(Pointer, int button, Pointer<Int32>)>()(
          ptr.ref.lpVtbl, button.value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return GameControllerButtonLabel.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }

  // IGamepad methods
  late final _iGamepad = IGamepad.from(this);

  @override
  GamepadVibration get vibration => _iGamepad.vibration;

  @override
  set vibration(GamepadVibration value) => _iGamepad.vibration = value;

  @override
  GamepadReading getCurrentReading() => _iGamepad.getCurrentReading();
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
