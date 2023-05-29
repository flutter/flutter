// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// The type of step taken according to the pedometer.
///
/// {@category Enum}
enum PedometerStepKind implements WinRTEnum {
  unknown(0),
  walking(1),
  running(2);

  @override
  final int value;

  const PedometerStepKind(this.value);

  factory PedometerStepKind.from(int value) =>
      PedometerStepKind.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}
