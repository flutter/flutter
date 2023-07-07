// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common structs used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: camel_case_extensions, camel_case_types
// ignore_for_file: directives_ordering, unnecessary_getters_setters
// ignore_for_file: unused_field, unused_import
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Represents the current state of the gamepad.
///
/// {@category Struct}
class GamepadReading extends Struct {
  @Uint64()
  external int Timestamp;

  @Uint32()
  external int Buttons;

  @Double()
  external double LeftTrigger;

  @Double()
  external double RightTrigger;

  @Double()
  external double LeftThumbstickX;

  @Double()
  external double LeftThumbstickY;

  @Double()
  external double RightThumbstickX;

  @Double()
  external double RightThumbstickY;
}

/// Describes the gamepad motor speed.
///
/// {@category Struct}
class GamepadVibration extends Struct {
  @Double()
  external double LeftMotor;

  @Double()
  external double RightMotor;

  @Double()
  external double LeftTrigger;

  @Double()
  external double RightTrigger;
}
