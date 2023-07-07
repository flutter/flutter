// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

/// A JSON value.
///
/// This class is suitable for use in built_value fields. When serialized it
/// maps directly onto JSON values.
///
/// Deep operator== and hashCode are provided, meaning the contents of a
/// List or Map is used for equality and hashing.
///
/// List and Map classes are wrapped in [UnmodifiableListView] and
/// [UnmodifiableMapView] so they won't be modifiable via this object. You
/// must ensure that no updates are made via the original reference, as a
/// copy is not made.
///
/// Note: this is an experimental feature. API may change without a major
/// version increase.
abstract class JsonObject {
  /// The value, which may be a bool, a List, a Map, a num or a String.
  Object get value;

  /// Whether the value is a [bool].
  bool get isBool => false;

  /// The value as a [bool], or throw if not.
  bool get asBool => throw StateError('Not a bool.');

  /// Whether the value is a [List].
  bool get isList => false;

  /// The value as a [List], or throw if not.
  List get asList => throw StateError('Not a List.');

  /// Whether the value is a [Map].
  bool get isMap => false;

  /// The value as a [Map], or throw if not.
  Map get asMap => throw StateError('Not a Map.');

  /// Whether the value is a [num].
  bool get isNum => false;

  /// The value as a [num], or throw if not.
  num get asNum => throw StateError('Not a num.');

  /// Whether the value is a [String].
  bool get isString => false;

  /// The value as a [String], or throw if not.
  String get asString => throw StateError('Not a String.');

  /// Instantiates with [value], which must be a bool, a List, a Map, a num
  /// or a String. Otherwise, an [ArgumentError] is thrown.
  factory JsonObject(Object? value) {
    if (value is num) {
      return NumJsonObject(value);
    } else if (value is String) {
      return StringJsonObject(value);
    } else if (value is bool) {
      return BoolJsonObject(value);
    } else if (value is List<Object?>) {
      return ListJsonObject(value);
    } else if (value is Map<String, Object?>) {
      return MapJsonObject(value);
    } else if (value is Map) {
      // Allow wrong type map, check individual values.
      return MapJsonObject(value.cast());
    } else {
      throw ArgumentError.value(value, 'value',
          'Must be bool, List<Object?>, Map<String?, Object?>, num or String');
    }
  }

  JsonObject._();

  @override
  String toString() {
    return value.toString();
  }
}

/// A [JsonObject] holding a bool.
class BoolJsonObject extends JsonObject {
  @override
  final bool value;

  BoolJsonObject(this.value) : super._();

  @override
  bool get isBool => true;

  @override
  bool get asBool => value;

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! BoolJsonObject) return false;
    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// A [JsonObject] holding a List.
class ListJsonObject extends JsonObject {
  @override
  final List<Object?> value;

  ListJsonObject(List<Object?> value)
      : value = UnmodifiableListView<Object?>(value),
        super._();

  @override
  bool get isList => true;

  @override
  List<Object?> get asList => value;

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! ListJsonObject) return false;
    return const DeepCollectionEquality().equals(value, other.value);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(value);
}

/// A [JsonObject] holding a Map.
class MapJsonObject extends JsonObject {
  @override
  final Map<String, Object?> value;

  MapJsonObject(Map<String, Object?> value)
      : value = UnmodifiableMapView(value),
        super._();

  @override
  bool get isMap => true;

  @override
  Map<String, Object?> get asMap => value;

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! MapJsonObject) return false;
    return const DeepCollectionEquality().equals(value, other.value);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(value);
}

/// A [JsonObject] holding a num.
class NumJsonObject extends JsonObject {
  @override
  final num value;

  NumJsonObject(this.value) : super._();

  @override
  bool get isNum => true;

  @override
  num get asNum => value;

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! NumJsonObject) return false;
    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// A [JsonObject] holding a String.
class StringJsonObject extends JsonObject {
  @override
  final String value;

  StringJsonObject(this.value) : super._();

  @override
  bool get isString => true;

  @override
  String get asString => value;

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! StringJsonObject) return false;
    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
