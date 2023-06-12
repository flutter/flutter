// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Label that appears on the physical controller button.
///
/// {@category Enum}
enum GameControllerButtonLabel implements WinRTEnum {
  none(0),
  xboxBack(1),
  xboxStart(2),
  xboxMenu(3),
  xboxView(4),
  xboxUp(5),
  xboxDown(6),
  xboxLeft(7),
  xboxRight(8),
  xboxA(9),
  xboxB(10),
  xboxX(11),
  xboxY(12),
  xboxLeftBumper(13),
  xboxLeftTrigger(14),
  xboxLeftStickButton(15),
  xboxRightBumper(16),
  xboxRightTrigger(17),
  xboxRightStickButton(18),
  xboxPaddle1(19),
  xboxPaddle2(20),
  xboxPaddle3(21),
  xboxPaddle4(22),
  mode(23),
  select(24),
  menu(25),
  view(26),
  back(27),
  start(28),
  options(29),
  share(30),
  up(31),
  down(32),
  left(33),
  right(34),
  letterA(35),
  letterB(36),
  letterC(37),
  letterL(38),
  letterR(39),
  letterX(40),
  letterY(41),
  letterZ(42),
  cross(43),
  circle(44),
  square(45),
  triangle(46),
  leftBumper(47),
  leftTrigger(48),
  leftStickButton(49),
  left1(50),
  left2(51),
  left3(52),
  rightBumper(53),
  rightTrigger(54),
  rightStickButton(55),
  right1(56),
  right2(57),
  right3(58),
  paddle1(59),
  paddle2(60),
  paddle3(61),
  paddle4(62),
  plus(63),
  minus(64),
  downLeftArrow(65),
  dialLeft(66),
  dialRight(67),
  suspension(68);

  @override
  final int value;

  const GameControllerButtonLabel(this.value);

  factory GameControllerButtonLabel.from(int value) =>
      GameControllerButtonLabel.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Specifies the button type.
///
/// {@category Enum}
class GamepadButtons extends WinRTEnum {
  const GamepadButtons(super.value, {super.name});

  factory GamepadButtons.from(int value) => GamepadButtons.values
      .firstWhere((e) => e.value == value, orElse: () => GamepadButtons(value));

  static const none = GamepadButtons(0, name: 'none');
  static const menu = GamepadButtons(1, name: 'menu');
  static const view = GamepadButtons(2, name: 'view');
  static const a = GamepadButtons(4, name: 'a');
  static const b = GamepadButtons(8, name: 'b');
  static const x = GamepadButtons(16, name: 'x');
  static const y = GamepadButtons(32, name: 'y');
  static const dPadUp = GamepadButtons(64, name: 'dPadUp');
  static const dPadDown = GamepadButtons(128, name: 'dPadDown');
  static const dPadLeft = GamepadButtons(256, name: 'dPadLeft');
  static const dPadRight = GamepadButtons(512, name: 'dPadRight');
  static const leftShoulder = GamepadButtons(1024, name: 'leftShoulder');
  static const rightShoulder = GamepadButtons(2048, name: 'rightShoulder');
  static const leftThumbstick = GamepadButtons(4096, name: 'leftThumbstick');
  static const rightThumbstick = GamepadButtons(8192, name: 'rightThumbstick');
  static const paddle1 = GamepadButtons(16384, name: 'paddle1');
  static const paddle2 = GamepadButtons(32768, name: 'paddle2');
  static const paddle3 = GamepadButtons(65536, name: 'paddle3');
  static const paddle4 = GamepadButtons(131072, name: 'paddle4');

  static const List<GamepadButtons> values = [
    none,
    menu,
    view,
    a,
    b,
    x,
    y,
    dPadUp,
    dPadDown,
    dPadLeft,
    dPadRight,
    leftShoulder,
    rightShoulder,
    leftThumbstick,
    rightThumbstick,
    paddle1,
    paddle2,
    paddle3,
    paddle4
  ];

  GamepadButtons operator &(GamepadButtons other) =>
      GamepadButtons(value & other.value);

  GamepadButtons operator |(GamepadButtons other) =>
      GamepadButtons(value | other.value);

  /// Determines whether one or more bit fields are set in the current enum
  /// value.
  ///
  /// ```dart
  /// final fileAttributes = FileAttributes.readOnly | FileAttributes.archive;
  /// fileAttributes.hasFlag(FileAttributes.readOnly)); // `true`
  /// fileAttributes.hasFlag(FileAttributes.temporary)); // `false`
  /// fileAttributes.hasFlag(
  ///     FileAttributes.readOnly | FileAttributes.archive)); // `true`
  /// ```
  bool hasFlag(GamepadButtons flag) {
    if (value != 0 && flag.value == 0) return false;
    return value & flag.value == flag.value;
  }
}
