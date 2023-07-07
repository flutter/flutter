// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Defines errors encountered while parsing JSON data.
///
/// {@category Enum}
enum JsonErrorStatus implements WinRTEnum {
  unknown(0),
  invalidJsonString(1),
  invalidJsonNumber(2),
  jsonValueNotFound(3),
  implementationLimit(4);

  @override
  final int value;

  const JsonErrorStatus(this.value);

  factory JsonErrorStatus.from(int value) =>
      JsonErrorStatus.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Specifies the JSON value type of a JsonValue object.
///
/// {@category Enum}
enum JsonValueType implements WinRTEnum {
  null_(0),
  boolean(1),
  number(2),
  string(3),
  array(4),
  object(5);

  @override
  final int value;

  const JsonValueType(this.value);

  factory JsonValueType.from(int value) =>
      JsonValueType.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}
