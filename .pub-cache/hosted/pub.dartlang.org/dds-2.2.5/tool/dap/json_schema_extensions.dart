// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'json_schema.dart';

String _toDartType(String type) {
  if (type.startsWith('#/definitions/')) {
    return type.replaceAll('#/definitions/', '');
  }
  switch (type) {
    case 'object':
      return 'Map<String, Object?>';
    case 'integer':
      return 'int';
    case 'number':
      return 'num';
    case 'string':
      return 'String';
    case 'boolean':
      return 'bool';
    case 'null':
      return 'Null';
    default:
      return type;
  }
}

String _toDartUnionType(List<String> types) {
  const allLiteralTypes = {
    'array',
    'boolean',
    'integer',
    'null',
    'number',
    'object',
    'string'
  };
  if (types.length == 7 && allLiteralTypes.containsAll(types)) {
    return 'Object';
  }
  return 'Either${types.length}<${types.map(_toDartType).join(', ')}>';
}

extension JsonSchemaExtensions on JsonSchema {
  JsonType typeFor(JsonType type) => type.dollarRef != null
      // TODO(dantup): Do we need to support more than just refs to definitions?
      ? definitions[type.refName]!
      : type;

  Map<String, JsonType> propertiesFor(JsonType type,
      {bool includeBase = true}) {
    // Merge this types direct properties with anything from the included
    // (allOf) types, but excluding those that come from the base class.
    final baseType = type.baseType;
    final includedBaseTypes =
        (type.allOf ?? []).where((t) => includeBase || t != baseType);
    final properties = {
      for (final other in includedBaseTypes) ...propertiesFor(typeFor(other)),
      ...?type.properties,
    };

    return properties;
  }
}

extension JsonTypeExtensions on JsonType {
  String asDartType({bool isOptional = false}) {
    final dartType = dollarRef != null
        ? _toDartType(dollarRef!)
        : oneOf != null
            ? _toDartUnionType(oneOf!.map((item) => item.asDartType()).toList())
            : type == null
                ? refName
                : type!.valueEquals('array')
                    ? 'List<${items!.asDartType()}>'
                    : type!.map(_toDartType, _toDartUnionType);

    return isOptional ? '$dartType?' : dartType;
  }

  /// Whether this type can have any type of value (Object/dynamic/any).
  bool get isAny => asDartType() == 'Object';

  /// Whether this type represents a List.
  bool get isList => type?.valueEquals('array') ?? false;

  /// Whether this type is a simple value like `String`, `bool`, `int`.
  bool get isSimpleValue => isSimple && asDartType() != 'Map<String, Object?>';

  /// If this type is an alias to a simple value type, returns that type.
  /// Otherwise, returns `null`.
  JsonType? get aliasFor {
    final targetType = dollarRef != null ? root.typeFor(this) : null;
    if (targetType == null) {
      return null;
    }
    return targetType.isSimpleValue ? targetType : null;
  }

  /// Whether this type is a simple type that needs no special handling for
  /// deserialisation (such as `String`, `bool`, `int`, `Map<String, Object?>`).
  bool get isSimple {
    const _dartSimpleTypes = {
      'bool',
      'int',
      'num',
      'String',
      'Map<String, Object?>',
      'Null',
    };
    return type != null &&
        _dartSimpleTypes.contains(type!.map(_toDartType, _toDartUnionType));
  }

  /// Whether this type is a Union type using JSON schema's "oneOf" of where its
  /// [type] is a list of types.
  bool get isUnion =>
      oneOf != null || type != null && type!.map((_) => false, (_) => true);

  /// Whether this type is a reference to another spec type (using `dollarRef`).
  bool get isSpecType => dollarRef != null;

  /// Whether [propertyName] is a required for this type or its base types.
  bool requiresField(String propertyName) {
    if (required?.contains(propertyName) ?? false) {
      return true;
    }
    if (allOf?.any((type) => root.typeFor(type).requiresField(propertyName)) ??
        false) {
      return true;
    }

    return false;
  }

  /// The name of the type that this one references.
  String get refName => dollarRef!.replaceAll('#/definitions/', '');

  /// The literal value of this type, if it can have only one.
  ///
  /// These are represented in the spec using an enum with only a single value.
  String? get literalValue => enumValues?.singleOrNull;

  /// The base type for this type. Base types are inferred by a type using
  /// allOf and the first listed type being a reference (dollarRef) to another
  /// spec type.
  JsonType? get baseType {
    final all = allOf;
    if (all != null && all.length > 1 && all.first.dollarRef != null) {
      return all.first;
    }
    return null;
  }

  /// The list of possible types allowed by this union.
  ///
  /// May be represented using `oneOf` or a list of types in `type`.
  List<JsonType> get unionTypes {
    final types = oneOf ??
        // Fabricate a union for types where "type" is an array of literal types:
        // ['a', 'b']
        type!.map(
          (_) => throw 'unexpected non-union in isUnion condition',
          (types) =>
              types.map((t) => JsonType.fromJson(root, {'type': t})).toList(),
        )!;
    return types;
  }
}
