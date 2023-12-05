// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

typedef GamepadHand = String;
typedef GamepadHapticsResult = String;
typedef GamepadHapticActuatorType = String;
typedef GamepadHapticEffectType = String;

@JS('GamepadHapticActuator')
@staticInterop
class GamepadHapticActuator {}

extension GamepadHapticActuatorExtension on GamepadHapticActuator {
  external bool canPlayEffectType(GamepadHapticEffectType type);
  external JSPromise playEffect(
    GamepadHapticEffectType type, [
    GamepadEffectParameters params,
  ]);
  external JSPromise pulse(
    num value,
    num duration,
  );
  external JSPromise reset();
  external GamepadHapticActuatorType get type;
}

@JS()
@staticInterop
@anonymous
class GamepadEffectParameters {
  external factory GamepadEffectParameters({
    num duration,
    num startDelay,
    num strongMagnitude,
    num weakMagnitude,
  });
}

extension GamepadEffectParametersExtension on GamepadEffectParameters {
  external set duration(num value);
  external num get duration;
  external set startDelay(num value);
  external num get startDelay;
  external set strongMagnitude(num value);
  external num get strongMagnitude;
  external set weakMagnitude(num value);
  external num get weakMagnitude;
}

@JS('GamepadPose')
@staticInterop
class GamepadPose {}

extension GamepadPoseExtension on GamepadPose {
  external bool get hasOrientation;
  external bool get hasPosition;
  external JSFloat32Array? get position;
  external JSFloat32Array? get linearVelocity;
  external JSFloat32Array? get linearAcceleration;
  external JSFloat32Array? get orientation;
  external JSFloat32Array? get angularVelocity;
  external JSFloat32Array? get angularAcceleration;
}

@JS('GamepadTouch')
@staticInterop
class GamepadTouch {}

extension GamepadTouchExtension on GamepadTouch {
  external int get touchId;
  external int get surfaceId;
  external JSFloat32Array get position;
  external JSUint32Array? get surfaceDimensions;
}
