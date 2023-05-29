// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Indicates the status of the battery.
///
/// {@category Enum}
enum BatteryStatus implements WinRTEnum {
  notPresent(0),
  discharging(1),
  idle(2),
  charging(3);

  @override
  final int value;

  const BatteryStatus(this.value);

  factory BatteryStatus.from(int value) =>
      BatteryStatus.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}
