// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

/// A base class for all proto enum types.
///
/// All proto `enum` classes inherit from [ProtobufEnum]. For example, given
/// the following enum defined in a proto file:
///
///     message MyMessage {
///       enum Color {
///         RED = 0;
///         GREEN = 1;
///         BLUE = 2;
///       };
///       // ...
///     }
///
/// the generated Dart file will include a `MyMessage_Color` class that extends
/// `ProtobufEnum`. It will also include a `const MyMessage_Color` for each of
/// the three values defined. Here are some examples:
///
/// ```
/// MyMessage_Color.RED  // => a MyMessage_Color instance
/// MyMessage_Color.GREEN.value  // => 1
/// MyMessage_Color.GREEN.name   // => "GREEN"
/// ```
class ProtobufEnum {
  /// This enum's integer value, as specified in the .proto file.
  final int value;

  /// This enum's name, as specified in the .proto file.
  final String name;

  /// Creates a new constant [ProtobufEnum] using [value] and [name].
  const ProtobufEnum(this.value, this.name);

  /// Creates a Map for all of the [ProtobufEnum]s in [byIndex], mapping each
  /// [ProtobufEnum]'s [value] to the [ProtobufEnum].
  static Map<int, T> initByValue<T extends ProtobufEnum>(List<T> byIndex) {
    var byValue = <int, T>{};
    for (var v in byIndex) {
      byValue[v.value] = v;
    }
    return byValue;
  }

  // Subclasses will typically have a private constructor and a fixed set of
  // instances, so `Object.operator==()` will work, and does not need to
  // be overridden explicitly.
  @override
  bool operator ==(Object other);

  @override
  int get hashCode => value;

  /// Returns this enum's [name] or the [value] if names are not represented.
  @override
  String toString() => name == '' ? value.toString() : name;
}
