// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Specifies where the context menu should be positioned relative to the
/// selection rectangle.
///
/// {@category Enum}
enum Placement implements WinRTEnum {
  default_(0),
  above(1),
  below(2),
  left(3),
  right(4);

  @override
  final int value;

  const Placement(this.value);

  factory Placement.from(int value) =>
      Placement.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}
