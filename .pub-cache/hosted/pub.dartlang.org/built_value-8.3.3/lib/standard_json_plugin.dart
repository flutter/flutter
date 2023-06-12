// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'dart:convert' show json;

/// Switches to "standard" JSON format.
///
/// The default serialization format is more powerful, with better performance
/// and support for more collection types. But, you may need to interact with
/// other systems that use simple map-based JSON. If so, use
/// [SerializersBuilder.addPlugin] to install this plugin.
///
/// When using this plugin you may wish to also install
/// `Iso8601DateTimeSerializer` which switches serialization of `DateTime`
/// from microseconds since epoch to ISO 8601 format.
class StandardJsonPlugin implements SerializerPlugin {
  static final BuiltSet<Type> _unsupportedTypes =
      BuiltSet<Type>([BuiltListMultimap, BuiltSetMultimap]);

  /// The field used to specify the value type if needed. Defaults to `$`.
  final String discriminator;

  // The key used when there is just a single value, for example if serializing
  // an `int`.
  final String valueKey;

  StandardJsonPlugin({this.discriminator = r'$', this.valueKey = ''});

  @override
  Object? beforeSerialize(Object? object, FullType specifiedType) {
    if (_unsupportedTypes.contains(specifiedType.root)) {
      throw ArgumentError(
          'Standard JSON cannot serialize type ${specifiedType.root}.');
    }
    return object;
  }

  @override
  Object? afterSerialize(Object? object, FullType specifiedType) {
    if (object is List &&
        specifiedType.root != BuiltList &&
        specifiedType.root != BuiltSet &&
        specifiedType.root != JsonObject) {
      if (specifiedType.isUnspecified) {
        return _toMapWithDiscriminator(object);
      } else {
        return _toMap(object, _needsEncodedKeys(specifiedType));
      }
    } else {
      return object;
    }
  }

  @override
  Object? beforeDeserialize(Object? object, FullType specifiedType) {
    if (object is Map && specifiedType.root != JsonObject) {
      if (specifiedType.isUnspecified) {
        return _toListUsingDiscriminator(object);
      } else {
        return _toList(object, _needsEncodedKeys(specifiedType),
            keepNulls: specifiedType.root == BuiltMap);
      }
    } else {
      return object;
    }
  }

  @override
  Object? afterDeserialize(Object? object, FullType specifiedType) {
    return object;
  }

  /// Returns whether a type has keys that aren't supported by JSON maps; this
  /// only applies to `BuiltMap` with non-String keys.
  bool _needsEncodedKeys(FullType specifiedType) =>
      specifiedType.root == BuiltMap &&
      specifiedType.parameters[0].root != String;

  /// Converts serialization output, a `List`, to a `Map`, when the serialized
  /// type is known statically.
  Map _toMap(List list, bool needsEncodedKeys) {
    var result = <String, Object?>{};
    for (var i = 0; i != list.length ~/ 2; ++i) {
      final key = list[i * 2];
      final value = list[i * 2 + 1];
      result[needsEncodedKeys ? _encodeKey(key) : key as String] = value;
    }
    return result;
  }

  /// Converts serialization output, a `List`, to a `Map`, when the serialized
  /// type is not known statically. The type will be specified in the
  /// [discriminator] field.
  Map _toMapWithDiscriminator(List list) {
    var type = list[0];

    if (type == 'list') {
      // Embed the list in the map.
      return <String, Object>{discriminator: type, valueKey: list.sublist(1)};
    }

    // Length is at least two because we have one entry for type and one for
    // the value.
    if (list.length == 2) {
      // Just a type and a primitive value. Encode the value in the map.
      return <String, Object?>{discriminator: type, valueKey: list[1]};
    }

    // If a map has non-String keys then they need encoding to strings before
    // it can be converted to JSON. Because we don't know the type, we also
    // won't know the type on deserialization, and signal this by changing the
    // type name on the wire to `encoded_map`.
    var needToEncodeKeys = false;
    if (type == 'map') {
      for (var i = 0; i != (list.length - 1) ~/ 2; ++i) {
        if (list[i * 2 + 1] is! String) {
          needToEncodeKeys = true;
          type = 'encoded_map';
          break;
        }
      }
    }

    var result = <String, Object>{discriminator: type};
    for (var i = 0; i != (list.length - 1) ~/ 2; ++i) {
      final key = needToEncodeKeys
          ? _encodeKey(list[i * 2 + 1])
          : list[i * 2 + 1] as String;
      final value = list[i * 2 + 2];
      result[key] = value;
    }
    return result;
  }

  /// JSON-encodes an `Object` key so it can be stored as a `String`. Needed
  /// because JSON maps are only allowed strings as keys.
  String _encodeKey(Object key) {
    return json.encode(key);
  }

  /// Converts [StandardJsonPlugin] serialization output, a `Map`, to a `List`,
  /// when the serialized type is known statically.
  ///
  /// By default keys with null values are dropped, pass [keepNulls] true when
  /// the map is an actual map with nullable values, so they should be kept.
  List<Object?> _toList(Map map, bool hasEncodedKeys,
      {bool keepNulls = false}) {
    var nullValueCount =
        keepNulls ? 0 : map.values.where((value) => value == null).length;
    var result = List<Object?>.filled(
        (map.length - nullValueCount) * 2, 0 /* Will be overwritten. */);
    var i = 0;
    map.forEach((key, value) {
      // Drop null values, they are represented by missing keys.
      if (!keepNulls && value == null) return;

      result[i] = hasEncodedKeys ? _decodeKey(key as String) : key;
      result[i + 1] = value;
      i += 2;
    });
    return result;
  }

  /// Converts [StandardJsonPlugin] serialization output, a `Map`, to a `List`,
  /// when the serialized type is not known statically. The type is retrieved
  /// from the [discriminator] field.
  List<Object?> _toListUsingDiscriminator(Map map) {
    var type = map[discriminator];

    if (type == null) {
      throw ArgumentError('Unknown type on deserialization. '
          'Need either specifiedType or discriminator field.');
    }

    if (type == 'list') {
      return [type, ...(map[valueKey] as Iterable)];
    }

    if (map.containsKey(valueKey)) {
      // Just a type and a primitive value. Retrieve the value in the map.
      final result = List<Object?>.filled(2, 0 /* Will be overwritten. */);
      result[0] = type;
      result[1] = map[valueKey];
      return result;
    }

    // A type name of `encoded_map` indicates that the map has non-String keys
    // that have been serialized and JSON-encoded; decode the keys when
    // converting back to a `List`.
    var needToDecodeKeys = type == 'encoded_map';
    if (needToDecodeKeys) {
      type = 'map';
    }

    var nullValueCount = map.values.where((value) => value == null).length;
    var result = List<Object>.filled(
        (map.length - nullValueCount) * 2 - 1, 0 /* Will be overwritten. */);
    result[0] = type;

    var i = 1;
    map.forEach((key, value) {
      if (key == discriminator) return;

      // Drop null values, they are represented by missing keys.
      if (value == null) return;

      result[i] = needToDecodeKeys ? _decodeKey(key as String) : key;
      result[i + 1] = value;
      i += 2;
    });
    return result;
  }

  /// JSON-decodes a `String` encoded using [_encodeKey].
  Object? _decodeKey(String key) {
    return json.decode(key);
  }
}
