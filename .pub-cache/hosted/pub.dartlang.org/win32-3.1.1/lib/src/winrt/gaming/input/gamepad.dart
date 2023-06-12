// gamepad.dart

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
import 'igamepad2.dart';
import 'igamecontrollerbatteryinfo.dart';
import 'igamepadstatics.dart';
import 'igamepadstatics2.dart';
import 'structs.g.dart';
import 'headset.dart';
import '../../system/userchangedeventargs.dart';
import '../../system/user.dart';
import 'enums.g.dart';
import '../../devices/power/batteryreport.dart';
import '../../foundation/collections/ivectorview.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class Gamepad extends IInspectable
    implements
        IGamepad,
        IGameController,
        IGamepad2,
        IGameControllerBatteryInfo {
  Gamepad.fromRawPointer(super.ptr);

  static const _className = 'Windows.Gaming.Input.Gamepad';

  // IGamepadStatics methods
  static int add_GamepadAdded(Pointer<NativeFunction<EventHandler>> value) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IGamepadStatics);

    try {
      return IGamepadStatics.fromRawPointer(activationFactory)
          .add_GamepadAdded(value);
    } finally {
      free(activationFactory);
    }
  }

  static void remove_GamepadAdded(int token) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IGamepadStatics);

    try {
      return IGamepadStatics.fromRawPointer(activationFactory)
          .remove_GamepadAdded(token);
    } finally {
      free(activationFactory);
    }
  }

  static int add_GamepadRemoved(Pointer<NativeFunction<EventHandler>> value) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IGamepadStatics);

    try {
      return IGamepadStatics.fromRawPointer(activationFactory)
          .add_GamepadRemoved(value);
    } finally {
      free(activationFactory);
    }
  }

  static void remove_GamepadRemoved(int token) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IGamepadStatics);

    try {
      return IGamepadStatics.fromRawPointer(activationFactory)
          .remove_GamepadRemoved(token);
    } finally {
      free(activationFactory);
    }
  }

  static List<Gamepad> get gamepads {
    final activationFactory =
        CreateActivationFactory(_className, IID_IGamepadStatics);

    try {
      return IGamepadStatics.fromRawPointer(activationFactory).gamepads;
    } finally {
      free(activationFactory);
    }
  }

  // IGamepadStatics2 methods
  static Gamepad fromGameController(IGameController gameController) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IGamepadStatics2);

    try {
      return IGamepadStatics2.fromRawPointer(activationFactory)
          .fromGameController(gameController);
    } finally {
      free(activationFactory);
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
  // IGamepad2 methods
  late final _iGamepad2 = IGamepad2.from(this);

  @override
  GameControllerButtonLabel getButtonLabel(GamepadButtons button) =>
      _iGamepad2.getButtonLabel(button);
  // IGameControllerBatteryInfo methods
  late final _iGameControllerBatteryInfo =
      IGameControllerBatteryInfo.from(this);

  @override
  BatteryReport tryGetBatteryReport() =>
      _iGameControllerBatteryInfo.tryGetBatteryReport();
}
