// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'gamepad_extensions.dart';
import 'hr_time.dart';

typedef GamepadMappingType = String;

@JS('Gamepad')
@staticInterop
class Gamepad {}

extension GamepadExtension on Gamepad {
  external GamepadHand get hand;
  external JSArray get hapticActuators;
  external GamepadPose? get pose;
  external JSArray? get touchEvents;
  external GamepadHapticActuator? get vibrationActuator;
  external String get id;
  external int get index;
  external bool get connected;
  external DOMHighResTimeStamp get timestamp;
  external GamepadMappingType get mapping;
  external JSArray get axes;
  external JSArray get buttons;
}

@JS('GamepadButton')
@staticInterop
class GamepadButton {}

extension GamepadButtonExtension on GamepadButton {
  external bool get pressed;
  external bool get touched;
  external num get value;
}

@JS('GamepadEvent')
@staticInterop
class GamepadEvent implements Event {
  external factory GamepadEvent(
    String type,
    GamepadEventInit eventInitDict,
  );
}

extension GamepadEventExtension on GamepadEvent {
  external Gamepad get gamepad;
}

@JS()
@staticInterop
@anonymous
class GamepadEventInit implements EventInit {
  external factory GamepadEventInit({required Gamepad gamepad});
}

extension GamepadEventInitExtension on GamepadEventInit {
  external set gamepad(Gamepad value);
  external Gamepad get gamepad;
}
