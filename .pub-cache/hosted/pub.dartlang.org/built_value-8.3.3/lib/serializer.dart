// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_collection/src/internal/hash.dart';
import 'package:built_value/src/big_int_serializer.dart';
import 'package:built_value/src/date_time_serializer.dart';
import 'package:built_value/src/duration_serializer.dart';
import 'package:built_value/src/int64_serializer.dart';
import 'package:built_value/src/json_object_serializer.dart';
import 'package:built_value/src/num_serializer.dart';
import 'package:built_value/src/uri_serializer.dart';

import 'src/bool_serializer.dart';
import 'src/built_json_serializers.dart';
import 'src/built_list_multimap_serializer.dart';
import 'src/built_list_serializer.dart';
import 'src/built_map_serializer.dart';
import 'src/built_set_multimap_serializer.dart';
import 'src/built_set_serializer.dart';
import 'src/double_serializer.dart';
import 'src/int_serializer.dart';
import 'src/null_serializer.dart';
import 'src/regexp_serializer.dart';
import 'src/string_serializer.dart';

/// Annotation to trigger code generation of a [Serializers] instance.
///
/// Use like this:
///
/// ```
/// @SerializersFor(const [
///   MySerializableClass,
///   MyOtherSerializableClass,
/// ])
/// final Serializers serializers = _$serializers;
/// ```
///
/// The `_$serializers` value will be generated for you in a part file next
/// to the current source file. It will hold serializers for the types
/// specified plus any types used in their fields, transitively.
class SerializersFor {
  final List<Type> types;

  const SerializersFor(this.types);
}

/// Serializes all known classes.
///
/// See: https://github.com/google/built_value.dart/tree/master/example
abstract class Serializers {
  /// Default [Serializers] that can serialize primitives and collections.
  ///
  /// Use [toBuilder] to add more serializers.
  factory Serializers() {
    return (SerializersBuilder()
          ..add(BigIntSerializer())
          ..add(BoolSerializer())
          ..add(BuiltListSerializer())
          ..add(BuiltListMultimapSerializer())
          ..add(BuiltMapSerializer())
          ..add(BuiltSetSerializer())
          ..add(BuiltSetMultimapSerializer())
          ..add(DateTimeSerializer())
          ..add(DoubleSerializer())
          ..add(DurationSerializer())
          ..add(IntSerializer())
          ..add(Int64Serializer())
          ..add(JsonObjectSerializer())
          ..add(NullSerializer())
          ..add(NumSerializer())
          ..add(RegExpSerializer())
          ..add(StringSerializer())
          ..add(UriSerializer())
          ..addBuilderFactory(const FullType(BuiltList, [FullType.object]),
              () => ListBuilder<Object>())
          ..addBuilderFactory(
              const FullType(
                  BuiltListMultimap, [FullType.object, FullType.object]),
              () => ListMultimapBuilder<Object, Object>())
          ..addBuilderFactory(
              const FullType(BuiltMap, [FullType.object, FullType.object]),
              () => MapBuilder<Object, Object>())
          ..addBuilderFactory(const FullType(BuiltSet, [FullType.object]),
              () => SetBuilder<Object>())
          ..addBuilderFactory(
              const FullType(
                  BuiltSetMultimap, [FullType.object, FullType.object]),
              () => SetMultimapBuilder<Object, Object>()))
        .build();
  }

  /// Merges iterable of [Serializers] into a single [Serializers].
  ///
  /// [Serializer] and builder factories are accumulated. Plugins are not.
  static Serializers merge(Iterable<Serializers> serializersIterable) =>
      (Serializers().toBuilder()..mergeAll(serializersIterable)).build();

  /// The installed [Serializer]s.
  Iterable<Serializer> get serializers;

  /// The installed builder factories.
  BuiltMap<FullType, Function> get builderFactories;

  /// The installed serializer plugins.
  Iterable<SerializerPlugin> get serializerPlugins;

  /// Serializes [object].
  ///
  /// A [Serializer] must have been provided for every type the object uses.
  ///
  /// Types that are known statically can be provided via [specifiedType]. This
  /// will reduce the amount of data needed on the wire. The exact same
  /// [specifiedType] will be needed to deserialize.
  ///
  /// Create one using [SerializersBuilder].
  ///
  /// TODO(davidmorgan): document the wire format.
  Object? serialize(Object? object,
      {FullType specifiedType = FullType.unspecified});

  /// Convenience method for when you know the type you're serializing.
  /// Specify the type by specifying its [Serializer] class. Equivalent to
  /// calling [serialize] with a `specifiedType`.
  Object? serializeWith<T>(Serializer<T> serializer, T? object);

  /// Convenience method for when you want a JSON string and know the type
  /// you're serializing. Specify the type by specifying its [Serializer]
  /// class. Equivalent to calling [serialize] with a `specifiedType` then
  /// calling `json.encode`.
  String toJson<T>(Serializer<T> serializer, T? object);

  /// Deserializes [serialized].
  ///
  /// A [Serializer] must have been provided for every type the object uses.
  ///
  /// If [serialized] was produced by calling [serialize] with [specifiedType],
  /// the exact same [specifiedType] must be provided to deserialize.
  Object? deserialize(Object? serialized,
      {FullType specifiedType = FullType.unspecified});

  /// Convenience method for when you know the type you're deserializing.
  /// Specify the type by specifying its [Serializer] class. Equivalent to
  /// calling [deserialize] with a `specifiedType`.
  T? deserializeWith<T>(Serializer<T> serializer, Object? serialized);

  /// Convenience method for when you have a JSON string and know the type
  /// you're deserializing. Specify the type by specifying its [Serializer]
  /// class. Equivalent to calling [deserialize] with a `specifiedType` then
  /// calling `json.decode`.
  T? fromJson<T>(Serializer<T> serializer, String serialized);

  /// Gets a serializer; returns `null` if none is found. For use in plugins
  /// and other extension code.
  Serializer? serializerForType(Type type);

  /// Gets a serializer; returns `null` if none is found. For use in plugins
  /// and other extension code.
  Serializer? serializerForWireName(String wireName);

  /// Creates a new builder for the type represented by [fullType].
  ///
  /// For example, if [fullType] is `BuiltList<int, String>`, returns a
  /// `ListBuilder<int, String>`. This helps serializers to instantiate with
  /// correct generic type parameters.
  ///
  /// Throws a [StateError] if no matching builder factory has been added.
  Object newBuilder(FullType fullType);

  /// Whether a builder for [fullType] is available via [newBuilder].
  bool hasBuilder(FullType fullType);

  /// Throws if a builder for [fullType] is not available via [newBuilder].
  void expectBuilder(FullType fullType);

  SerializersBuilder toBuilder();
}

/// Note: this is an experimental feature. API may change without a major
/// version increase.
abstract class SerializerPlugin {
  Object? beforeSerialize(Object? object, FullType specifiedType);

  Object? afterSerialize(Object? object, FullType specifiedType);

  Object? beforeDeserialize(Object? object, FullType specifiedType);

  Object? afterDeserialize(Object? object, FullType specifiedType);
}

/// Builder for [Serializers].
abstract class SerializersBuilder {
  factory SerializersBuilder() = BuiltJsonSerializersBuilder;

  /// Adds a [Serializer]. It will be used to handle the type(s) it declares
  /// via its `types` property.
  void add(Serializer serializer);

  /// Merges a [Serializers], adding all of its [Serializer] instances and
  /// builder factories. Does _not_ add plugins.
  void merge(Serializers serializers);

  /// Adds an iterable of [Serializer].
  void addAll(Iterable<Serializer> serializers);

  /// Merges an iterable of [Serializers].
  void mergeAll(Iterable<Serializers> serializersIterable);

  /// Adds a builder factory.
  ///
  /// Builder factories are needed when deserializing to types that use
  /// generics. For example, to deserialize a `BuiltList<Foo>`, `built_value`
  /// needs a builder factory for `BuiltList<Foo>`.
  ///
  /// `built_value` tries to generate code that will install all the builder
  /// factories you need, but this support is incomplete. So you may need to
  /// add your own. For example:
  ///
  /// ```dart
  /// serializers = (serializers.toBuilder()
  ///       ..addBuilderFactory(
  ///         const FullType(BuiltList, [FullType(Foo)]),
  ///         () => ListBuilder<Foo>(),
  ///       ))
  ///     .build();
  /// ```
  void addBuilderFactory(FullType specifiedType, Function function);

  /// Installs a [SerializerPlugin] that applies to all serialization and
  /// deserialization.
  void addPlugin(SerializerPlugin plugin);

  Serializers build();
}

/// A [Type] with, optionally, [FullType] generic type parameters.
///
/// May also be [unspecified], indicating that no type information is
/// available.
class FullType {
  /// An unspecified type.
  static const FullType unspecified = FullType(null);

  /// The [Object] type.
  static const FullType object = FullType(Object);

  /// The root of the type.
  final Type? root;

  /// Type parameters of the type.
  final List<FullType> parameters;

  /// Whether the type is nullable.
  final bool nullable;

  const FullType(this.root, [this.parameters = const []]) : nullable = false;
  const FullType.nullable(this.root, [this.parameters = const []])
      : nullable = true;

  bool get isUnspecified => identical(root, null);

  FullType withNullability(bool nullability) => nullability
      ? FullType.nullable(root, parameters)
      : FullType(root, parameters);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! FullType) return false;
    if (root != other.root) return false;
    if (nullable != other.nullable) return false;
    if (parameters.length != other.parameters.length) return false;
    for (var i = 0; i != parameters.length; ++i) {
      if (parameters[i] != other.parameters[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return hash2(root, hashObjects(parameters)) ^ (nullable ? 0x696eefd9 : 0);
  }

  @override
  String toString() => isUnspecified
      ? 'unspecified'
      : (parameters.isEmpty
              ? _getRawName(root)
              : '${_getRawName(root)}<${parameters.join(", ")}>') +
          _nullabilitySuffix;

  String get _nullabilitySuffix => nullable ? '?' : '';

  static String _getRawName(Type? type) {
    var name = type.toString();
    var genericsStart = name.indexOf('<');
    return genericsStart == -1 ? name : name.substring(0, genericsStart);
  }
}

/// Serializes a single type.
///
/// You should not usually need to implement this interface. Implementations
/// are provided for collections and primitives in `built_json`. Classes using
/// `built_value` and enums using `EnumClass` can have implementations
/// generated using `built_json_generator`.
///
/// Implementations must extend either [PrimitiveSerializer] or
/// [StructuredSerializer].
abstract class Serializer<T> {
  /// The [Type]s that can be serialized.
  ///
  /// They must all be equal to T or a subclass of T. Subclasses are used when
  /// T is an abstract class, which is the case with built_value generated
  /// serializers.
  Iterable<Type> get types;

  /// The wire name of the serializable type. For most classes, the class name.
  /// For primitives and collections a lower-case name is defined as part of
  /// the `built_json` wire format.
  String get wireName;
}

/// A [Serializer] that serializes to and from primitive JSON values.
abstract class PrimitiveSerializer<T> implements Serializer<T> {
  /// Serializes [object].
  ///
  /// Use [serializers] as needed for nested serialization. Information about
  /// the type being serialized is provided in [specifiedType].
  ///
  /// Returns a value that can be represented as a JSON primitive: a boolean,
  /// an integer, a double, or a String.
  ///
  /// TODO(davidmorgan): document the wire format.
  Object serialize(Serializers serializers, T object,
      {FullType specifiedType = FullType.unspecified});

  /// Deserializes [serialized].
  ///
  /// [serialized] is a boolean, an integer, a double or a String.
  ///
  /// Use [serializers] as needed for nested deserialization. Information about
  /// the type being deserialized is provided in [specifiedType].
  T deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified});
}

/// A [Serializer] that serializes to and from an [Iterable] of primitive JSON
/// values.
abstract class StructuredSerializer<T> implements Serializer<T> {
  /// Serializes [object].
  ///
  /// Use [serializers] as needed for nested serialization. Information about
  /// the type being serialized is provided in [specifiedType].
  ///
  /// Returns an [Iterable] of values that can be represented as structured
  /// JSON: booleans, integers, doubles, Strings and [Iterable]s.
  ///
  /// TODO(davidmorgan): document the wire format.
  Iterable<Object?> serialize(Serializers serializers, T object,
      {FullType specifiedType = FullType.unspecified});

  /// Deserializes [serialized].
  ///
  /// [serialized] is an [Iterable] that may contain booleans, integers,
  /// doubles, Strings and/or [Iterable]s.
  ///
  /// Use [serializers] as needed for nested deserialization. Information about
  /// the type being deserialized is provided in [specifiedType].
  T deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified});
}

/// [Error] conveying why deserialization failed.
class DeserializationError extends Error {
  final String? json;
  final FullType type;
  final Error error;

  factory DeserializationError(Object? json, FullType type, Error error) {
    var limitedJson = json.toString();
    if (limitedJson.length > 80) {
      limitedJson = limitedJson.replaceRange(77, limitedJson.length, '...');
    }
    return DeserializationError._(limitedJson, type, error);
  }

  DeserializationError._(this.json, this.type, this.error);

  @override
  String toString() => "Deserializing '$json' to '$type' failed due to: $error";
}
