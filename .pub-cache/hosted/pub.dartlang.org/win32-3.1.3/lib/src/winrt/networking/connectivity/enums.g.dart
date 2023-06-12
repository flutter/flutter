// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Defines the network connection types.
///
/// {@category Enum}
class NetworkTypes extends WinRTEnum {
  const NetworkTypes(super.value, {super.name});

  factory NetworkTypes.from(int value) => NetworkTypes.values
      .firstWhere((e) => e.value == value, orElse: () => NetworkTypes(value));

  static const none = NetworkTypes(0, name: 'none');
  static const internet = NetworkTypes(1, name: 'internet');
  static const privateNetwork = NetworkTypes(2, name: 'privateNetwork');

  static const List<NetworkTypes> values = [none, internet, privateNetwork];

  NetworkTypes operator &(NetworkTypes other) =>
      NetworkTypes(value & other.value);

  NetworkTypes operator |(NetworkTypes other) =>
      NetworkTypes(value | other.value);

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
  bool hasFlag(NetworkTypes flag) {
    if (value != 0 && flag.value == 0) return false;
    return value & flag.value == flag.value;
  }
}
