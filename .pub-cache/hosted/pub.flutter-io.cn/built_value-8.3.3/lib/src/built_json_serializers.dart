// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

/// Default implementation of [Serializers].
class BuiltJsonSerializers implements Serializers {
  final BuiltMap<Type, Serializer> _typeToSerializer;

  // Implementation note: wire name is what gets sent in the JSON, type name is
  // the runtime type name. Type name is complicated for two reasons:
  //
  // 1. Built Value classes have two types, the abstract class and the
  // generated implementation.
  //
  // 2. When compiled to javascript the runtime type names are obfuscated.
  final BuiltMap<String, Serializer> _wireNameToSerializer;
  final BuiltMap<String, Serializer> _typeNameToSerializer;

  @override
  final BuiltMap<FullType, Function> builderFactories;

  @override
  final BuiltList<SerializerPlugin> serializerPlugins;

  BuiltJsonSerializers._(
      this._typeToSerializer,
      this._wireNameToSerializer,
      this._typeNameToSerializer,
      this.builderFactories,
      this.serializerPlugins);

  @override
  Iterable<Serializer> get serializers => _wireNameToSerializer.values;

  @override
  T? deserializeWith<T>(Serializer<T> serializer, Object? serialized) {
    return deserialize(serialized,
        specifiedType: FullType(serializer.types.first)) as T?;
  }

  @override
  T? fromJson<T>(Serializer<T> serializer, String serialized) {
    return deserializeWith<T>(serializer, json.decode(serialized));
  }

  @override
  Object? serializeWith<T>(Serializer<T> serializer, T? object) {
    return serialize(object, specifiedType: FullType(serializer.types.first));
  }

  @override
  String toJson<T>(Serializer<T> serializer, T? object) {
    return json.encode(serializeWith<T>(serializer, object));
  }

  @override
  Object? serialize(Object? object,
      {FullType specifiedType = FullType.unspecified}) {
    var transformedObject = object;
    for (var plugin in serializerPlugins) {
      transformedObject =
          plugin.beforeSerialize(transformedObject, specifiedType);
    }
    var result = _serialize(transformedObject, specifiedType);
    for (var plugin in serializerPlugins) {
      result = plugin.afterSerialize(result, specifiedType);
    }
    return result;
  }

  Object? _serialize(Object? object, FullType specifiedType) {
    if (specifiedType.isUnspecified) {
      final serializer = serializerForType(object.runtimeType);
      if (serializer == null) {
        throw StateError("No serializer for '${object.runtimeType}'.");
      }
      if (serializer is StructuredSerializer) {
        final result = <Object?>[serializer.wireName];
        return result..addAll(serializer.serialize(this, object));
      } else if (serializer is PrimitiveSerializer) {
        return object == null
            ? <Object?>[serializer.wireName, null]
            : <Object>[serializer.wireName, serializer.serialize(this, object)];
      } else {
        throw StateError(
            'serializer must be StructuredSerializer or PrimitiveSerializer');
      }
    } else {
      final serializer = serializerForType(specifiedType.root);
      if (serializer == null) {
        // Might be an interface; try resolving using the runtime type.
        return serialize(object);
      }
      if (serializer is StructuredSerializer) {
        return object == null
            ? null
            : serializer
                .serialize(this, object, specifiedType: specifiedType)
                .toList();
      } else if (serializer is PrimitiveSerializer) {
        return object == null
            ? null
            : serializer.serialize(this, object, specifiedType: specifiedType);
      } else {
        throw StateError(
            'serializer must be StructuredSerializer or PrimitiveSerializer');
      }
    }
  }

  @override
  Object? deserialize(Object? object,
      {FullType specifiedType = FullType.unspecified}) {
    var transformedObject = object;
    for (var plugin in serializerPlugins) {
      transformedObject =
          plugin.beforeDeserialize(transformedObject, specifiedType);
    }
    var result = _deserialize(object, transformedObject, specifiedType);
    for (var plugin in serializerPlugins) {
      result = plugin.afterDeserialize(result, specifiedType);
    }
    return result;
  }

  Object? _deserialize(
      Object? objectBeforePlugins, Object? object, FullType specifiedType) {
    if (specifiedType.isUnspecified) {
      final wireName = (object as List<Object?>).first as String;

      final serializer = serializerForWireName(wireName);
      if (serializer == null) {
        throw StateError("No serializer for '$wireName'.");
      }

      if (serializer is StructuredSerializer) {
        try {
          return serializer.deserialize(this, object.sublist(1));
        } on Error catch (error) {
          throw DeserializationError(object, specifiedType, error);
        }
      } else if (serializer is PrimitiveSerializer) {
        try {
          var primitive = object[1];
          return primitive == null
              ? null
              : serializer.deserialize(this, primitive);
        } on Error catch (error) {
          throw DeserializationError(object, specifiedType, error);
        }
      } else {
        throw StateError(
            'serializer must be StructuredSerializer or PrimitiveSerializer');
      }
    } else {
      final serializer = serializerForType(specifiedType.root);
      if (serializer == null) {
        if (object is List && object.first is String) {
          // Might be an interface; try resolving using the type on the wire.
          return deserialize(objectBeforePlugins);
        } else {
          throw StateError("No serializer for '${specifiedType.root}'.");
        }
      }

      if (serializer is StructuredSerializer) {
        try {
          return object == null
              ? null
              : serializer.deserialize(this, object as Iterable<Object?>,
                  specifiedType: specifiedType);
        } on Error catch (error) {
          throw DeserializationError(object, specifiedType, error);
        }
      } else if (serializer is PrimitiveSerializer) {
        try {
          return object == null
              ? null
              : serializer.deserialize(this, object,
                  specifiedType: specifiedType);
        } on Error catch (error) {
          throw DeserializationError(object, specifiedType, error);
        }
      } else {
        throw StateError(
            'serializer must be StructuredSerializer or PrimitiveSerializer');
      }
    }
  }

  @override
  Serializer? serializerForType(Type? type) =>
      _typeToSerializer[type] ?? _typeNameToSerializer[_getRawName(type)];

  @override
  Serializer? serializerForWireName(String wireName) =>
      _wireNameToSerializer[wireName];

  @override
  Object newBuilder(FullType fullType) {
    var builderFactory = builderFactories[fullType];
    if (builderFactory == null) _throwMissingBuilderFactory(fullType);
    return builderFactory();
  }

  @override
  void expectBuilder(FullType fullType) {
    if (!hasBuilder(fullType)) _throwMissingBuilderFactory(fullType);
  }

  Never _throwMissingBuilderFactory(FullType fullType) {
    throw StateError('No builder factory for $fullType. '
        'Fix by adding one, see SerializersBuilder.addBuilderFactory.');
  }

  @override
  bool hasBuilder(FullType fullType) {
    return builderFactories.containsKey(fullType);
  }

  @override
  SerializersBuilder toBuilder() {
    return BuiltJsonSerializersBuilder._(
        _typeToSerializer.toBuilder(),
        _wireNameToSerializer.toBuilder(),
        _typeNameToSerializer.toBuilder(),
        builderFactories.toBuilder(),
        serializerPlugins.toBuilder());
  }
}

/// Default implementation of [SerializersBuilder].
class BuiltJsonSerializersBuilder implements SerializersBuilder {
  final MapBuilder<Type, Serializer> _typeToSerializer;
  final MapBuilder<String, Serializer> _wireNameToSerializer;
  final MapBuilder<String, Serializer> _typeNameToSerializer;

  final MapBuilder<FullType, Function> _builderFactories;

  final ListBuilder<SerializerPlugin> _plugins;

  factory BuiltJsonSerializersBuilder() => BuiltJsonSerializersBuilder._(
      MapBuilder<Type, Serializer>(),
      MapBuilder<String, Serializer>(),
      MapBuilder<String, Serializer>(),
      MapBuilder<FullType, Function>(),
      ListBuilder<SerializerPlugin>());

  BuiltJsonSerializersBuilder._(
      this._typeToSerializer,
      this._wireNameToSerializer,
      this._typeNameToSerializer,
      this._builderFactories,
      this._plugins);

  @override
  void add(Serializer serializer) {
    if (serializer is! StructuredSerializer &&
        serializer is! PrimitiveSerializer) {
      throw ArgumentError(
          'serializer must be StructuredSerializer or PrimitiveSerializer');
    }

    _wireNameToSerializer[serializer.wireName] = serializer;
    for (var type in serializer.types) {
      _typeToSerializer[type] = serializer;
      _typeNameToSerializer[_getRawName(type)] = serializer;
    }
  }

  @override
  void addAll(Iterable<Serializer> serializers) {
    serializers.forEach(add);
  }

  @override
  void addBuilderFactory(FullType types, Function function) {
    _builderFactories[types] = function;
    // Nullability of the top level type is irrelevant to serialization, but
    // lookup might be done with either nullable or not nullable depending
    // on the context. So, store both for fast lookup.
    _builderFactories[types.withNullability(!types.nullable)] = function;
  }

  @override
  void merge(Serializers serializers) {
    addAll(serializers.serializers);
    _builderFactories.addAll(serializers.builderFactories.asMap());
  }

  @override
  void mergeAll(Iterable<Serializers> serializersIterable) {
    for (var serializers in serializersIterable) {
      merge(serializers);
    }
  }

  @override
  void addPlugin(SerializerPlugin plugin) {
    _plugins.add(plugin);
  }

  @override
  Serializers build() {
    return BuiltJsonSerializers._(
        _typeToSerializer.build(),
        _wireNameToSerializer.build(),
        _typeNameToSerializer.build(),
        _builderFactories.build(),
        _plugins.build());
  }
}

String _getRawName(Type? type) {
  var name = type.toString();
  var genericsStart = name.indexOf('<');
  return genericsStart == -1 ? name : name.substring(0, genericsStart);
}
