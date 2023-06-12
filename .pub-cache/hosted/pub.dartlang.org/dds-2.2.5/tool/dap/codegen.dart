// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:collection/collection.dart';

import 'json_schema.dart';
import 'json_schema_extensions.dart';

/// Generates Dart classes from the Debug Adapter Protocol's JSON Schema.
class CodeGenerator {
  /// Writes all required Dart classes for the supplied DAP [schema].
  void writeAll(IndentableStringBuffer buffer, JsonSchema schema) {
    _writeDefinitionClasses(buffer, schema);
    buffer.writeln();
    _writeBodyClasses(buffer, schema);
    buffer.writeln();
    _writeEventTypeLookup(buffer, schema);
    buffer.writeln();
    _writeCommandArgumentTypeLookup(buffer, schema);
  }

  /// Maps a name used in the DAP spec to a valid name for use in Dart.
  ///
  /// Reserved words like `default` will be mapped to a suitable alternative.
  /// Prefixed underscores are removed to avoid making things private.
  ///
  /// Underscores between words are swapped for camelCase.
  String _dartSafeName(String name) {
    const improvedName = {
      'default': 'defaultValue',
    };
    return improvedName[name] ??
        // Some types are prefixed with _ in the spec but that will make them
        // private in Dart and inaccessible to the adapter so we strip it off.
        name
            .replaceAll(RegExp(r'^_+'), '')
            // Also replace any other underscores to make camelCase
            .replaceAllMapped(
                RegExp(r'_(.)'), (m) => m.group(1)!.toUpperCase());
  }

  /// Re-wraps [lines] at [maxLength] to help keep comments for indented code
  /// within 80 characters.
  Iterable<String> _wrapLines(List<String> lines, int maxLength) sync* {
    lines = lines.map((l) => l.trimRight()).toList();
    for (var line in lines) {
      while (true) {
        if (line.length <= maxLength || line.startsWith('-')) {
          yield line;
          break;
        } else {
          var lastSpace = line.lastIndexOf(' ', max(maxLength, 0));
          // If there was no valid place to wrap, yield the whole string.
          if (lastSpace == -1) {
            yield line;
            break;
          } else {
            yield line.substring(0, lastSpace);
            line = line.substring(lastSpace + 1);
          }
        }
      }
    }
  }

  /// For each Response/Event class in the spec, generate a specific class to
  /// represent its body.
  ///
  /// These classes are used to simplify sending responses/events from the
  /// Debug Adapters by avoiding the need to construct the entire response/event
  /// which requires additional fields (for example the corresponding requests
  /// id/command and sequences):
  ///
  ///     this.sendResponse(FooBody(x: 1))
  ///
  /// instead of
  ///
  ///     this.sendResponse(Response(
  ///       seq: seq++,
  ///       request_seq: request.seq,
  ///       command: request.command,
  ///       body: {
  ///         x: 1
  ///         ...
  ///       }
  ///     ))
  void _writeBodyClasses(IndentableStringBuffer buffer, JsonSchema schema) {
    for (final entry in schema.definitions.entries.sortedBy((e) => e.key)) {
      final name = entry.key;
      final type = entry.value;
      final baseType = type.baseType;

      if (baseType?.refName == 'Response' || baseType?.refName == 'Event') {
        final baseClass = baseType?.refName == 'Event'
            ? JsonType.named(schema, 'EventBody')
            : null;
        final classProperties = schema.propertiesFor(type);
        final bodyProperty = classProperties['body'];
        var bodyPropertyProperties = bodyProperty?.properties;

        _writeClass(
          buffer,
          bodyProperty ?? JsonType.empty(schema),
          '${name}Body',
          bodyPropertyProperties ?? {},
          {},
          baseClass,
          null,
        );
      }
    }
  }

  /// Writes a `canParse` function for a DAP spec class.
  ///
  /// The function checks whether an Object? is a a valid map that contains all
  /// required fields and matches the types of the spec class.
  ///
  /// This is used where the spec contains union classes and we need to decide
  /// which of the allowed types a given value is.
  void _writeCanParseMethod(
    IndentableStringBuffer buffer,
    JsonType type,
    Map<String, JsonType> properties, {
    required String? baseTypeRefName,
  }) {
    buffer
      ..writeIndentedln('static bool canParse(Object? obj) {')
      ..indent()
      ..writeIndentedln('if (obj is! Map<String, dynamic>) {')
      ..indent()
      ..writeIndentedln('return false;')
      ..outdent()
      ..writeIndentedln('}');
    // In order to consider this valid for parsing, all fields that must not be
    // undefined must be present and also type check for the correct type.
    // Any fields that are optional but present, must still type check.
    for (final entry in properties.entries.sortedBy((e) => e.key)) {
      final propertyName = entry.key;
      final propertyType = entry.value;
      final isOptional = !type.requiresField(propertyName);

      if (propertyType.isAny && isOptional) {
        continue;
      }

      buffer.writeIndented('if (');
      _writeTypeCheckCondition(buffer, propertyType, "obj['$propertyName']",
          isOptional: isOptional, invert: true);
      buffer
        ..writeln(') {')
        ..indent()
        ..writeIndentedln('return false;')
        ..outdent()
        ..writeIndentedln('}');
    }
    buffer
      ..writeIndentedln(
        baseTypeRefName != null
            ? 'return $baseTypeRefName.canParse(obj);'
            : 'return true;',
      )
      ..outdent()
      ..writeIndentedln('}');
  }

  /// Writes the Dart class for [type].
  void _writeClass(
    IndentableStringBuffer buffer,
    JsonType type,
    String name,
    Map<String, JsonType> classProperties,
    Map<String, JsonType> baseProperties,
    JsonType? baseType,
    JsonType? resolvedBaseType, {
    Map<String, String> additionalValues = const {},
  }) {
    _writeTypeDescription(buffer, type);

    // Types that are just aliases to simple value types should be written as
    // typedefs.
    if (type.isSimpleValue) {
      buffer.writeln('typedef $name = ${type.asDartType()};');
      return;
    }

    // Some properties are defined in both the base and the class, because the
    // type may be narrowed, but sometimes we only want those that are defined
    // only in this class.
    final classOnlyProperties = {
      for (final property in classProperties.entries)
        if (!baseProperties.containsKey(property.key))
          property.key: property.value,
    };
    buffer.write('class $name ');
    if (baseType != null) {
      buffer.write('extends ${baseType.refName} ');
    }
    buffer
      ..writeln('{')
      ..indent();
    for (final val in additionalValues.entries) {
      buffer
        ..writeIndentedln('@override')
        ..writeIndentedln("final ${val.key} = '${val.value}';");
    }
    _writeFields(buffer, type, classOnlyProperties);
    buffer.writeln();
    _writeFromJsonStaticMethod(buffer, name);
    buffer.writeln();
    _writeConstructor(buffer, name, type, classProperties, baseProperties,
        classOnlyProperties,
        baseType: resolvedBaseType);
    buffer.writeln();
    _writeFromMapConstructor(buffer, name, type, classOnlyProperties,
        callSuper: resolvedBaseType != null);
    buffer.writeln();
    _writeCanParseMethod(buffer, type, classProperties,
        baseTypeRefName: baseType?.refName);
    buffer.writeln();
    _writeToJsonMethod(buffer, name, type, classOnlyProperties,
        callSuper: resolvedBaseType != null);
    buffer
      ..outdent()
      ..writeln('}')
      ..writeln();
  }

  /// Write a map to look up the `command` for a given `RequestArguments` type
  /// to simplify sending requests back to the client:
  ///
  ///     this.sendRequest(FooArguments(x: 1))
  ///
  /// instead of
  ///
  ///     this.sendRequest(Request(
  ///       seq: seq++,
  ///       command: request.command,
  ///       arguments: {
  ///         x: 1
  ///         ...
  ///       }
  ///     ))
  void _writeCommandArgumentTypeLookup(
      IndentableStringBuffer buffer, JsonSchema schema) {
    buffer
      ..writeln('const commandTypes = {')
      ..indent();
    for (final entry in schema.definitions.entries.sortedBy((e) => e.key)) {
      final type = entry.value;
      final baseType = type.baseType;

      if (baseType?.refName == 'Request') {
        final classProperties = schema.propertiesFor(type);
        final argumentsProperty = classProperties['arguments'];
        final commandType = classProperties['command']?.literalValue;
        if (argumentsProperty?.dollarRef != null && commandType != null) {
          buffer.writeIndentedln(
              "${argumentsProperty!.refName}: '$commandType',");
        }
      }
    }
    buffer
      ..writeln('};')
      ..outdent();
  }

  /// Writes a constructor for [type].
  ///
  /// The constructor will have named arguments for all fields, with those that
  /// are mandatory marked with `required`.
  void _writeConstructor(
    IndentableStringBuffer buffer,
    String name,
    JsonType type,
    Map<String, JsonType> classProperties,
    Map<String, JsonType> baseProperties,
    Map<String, JsonType> classOnlyProperties, {
    required JsonType? baseType,
  }) {
    buffer.writeIndented('$name(');
    if (classProperties.isNotEmpty || baseProperties.isNotEmpty) {
      buffer
        ..writeln('{')
        ..indent();

      // Properties for this class are written as 'this.foo'.
      for (final entry in classOnlyProperties.entries.sortedBy((e) => e.key)) {
        final propertyName = entry.key;
        final fieldName = _dartSafeName(propertyName);
        final isOptional = !type.requiresField(propertyName);
        buffer.writeIndented('');
        if (!isOptional) {
          buffer.write('required ');
        }
        buffer.writeln('this.$fieldName, ');
      }

      // Properties from the base class are standard arguments that will be
      // passed to a super() call.
      for (final entry in baseProperties.entries.sortedBy((e) => e.key)) {
        final propertyName = entry.key;
        // If this field is defined by the class and the base, prefer the
        // class one as it may contain things like the literal values.
        final propertyType = classProperties[propertyName] ?? entry.value;

        final fieldName = _dartSafeName(propertyName);
        if (propertyType.literalValue != null) {
          continue;
        }
        final isOptional = !type.requiresField(propertyName);
        final dartType = propertyType.asDartType(isOptional: isOptional);
        buffer.writeIndented('');
        if (!isOptional) {
          buffer.write('required ');
        }
        buffer.writeln('$dartType $fieldName, ');
      }
      buffer
        ..outdent()
        ..writeIndented('}');
    }
    buffer.write(')');

    if (baseType != null) {
      buffer.write(': super(');
      if (baseProperties.isNotEmpty) {
        buffer
          ..writeln()
          ..indent();
        for (final entry in baseProperties.entries) {
          final propertyName = entry.key;
          // Skip any properties that have literal values defined by the base
          // as we won't need to supply them.
          if (entry.value.literalValue != null) {
            continue;
          }
          // If this field is defined by the class and the base, prefer the
          // class one as it may contain things like the literal values.
          final propertyType = classProperties[propertyName] ?? entry.value;
          final fieldName = _dartSafeName(propertyName);
          final literalValue = propertyType.literalValue;
          final value = literalValue != null ? "'$literalValue'" : fieldName;
          buffer.writeIndentedln('$fieldName: $value, ');
        }
        buffer
          ..outdent()
          ..writeIndented('');
      }
      buffer.write(')');
    }
    buffer.writeln(';');
  }

  /// Write a class for each item in the DAP spec.
  ///
  /// Skips over the Request and Event sub-classes, as they are handled by the
  /// simplified body classes written by [_writeBodyClasses]. Uses
  /// [RequestArguments] as the base class for all argument classes.
  void _writeDefinitionClasses(
      IndentableStringBuffer buffer, JsonSchema schema) {
    for (final entry in schema.definitions.entries.sortedBy((e) => e.key)) {
      final name = entry.key;
      final type = entry.value;

      var baseType = type.baseType;
      final resolvedBaseType =
          baseType != null ? schema.typeFor(baseType) : null;
      final classProperties = schema.propertiesFor(type, includeBase: false);
      final baseProperties = resolvedBaseType != null
          ? schema.propertiesFor(resolvedBaseType)
          : <String, JsonType>{};

      // Skip creation of Request sub-classes, as we don't use these we just
      // pass the arguments in to the method directly.
      if (name != 'Request' && name.endsWith('Request')) {
        continue;
      }

      // Skip creation of Event sub-classes, as we don't use these we just
      // pass the body in to sendEvent directly.
      if (name != 'Event' && name.endsWith('Event')) {
        continue;
      }

      // Create a synthetic base class for arguments to provide type safety
      // for sending requests.
      if (baseType == null && name.endsWith('Arguments')) {
        baseType = JsonType.named(schema, 'RequestArguments');
      }

      _writeClass(
        buffer,
        type,
        name,
        classProperties,
        baseProperties,
        baseType,
        resolvedBaseType,
      );
    }
  }

  /// Writes a DartDoc comment, wrapped at 80 characters taking into account
  /// the indentation.
  void _writeDescription(IndentableStringBuffer buffer, String? description) {
    final maxLength = 80 - buffer.totalIndent - 4;
    if (description != null) {
      for (final line in _wrapLines(description.split('\n'), maxLength)) {
        buffer.writeIndentedln('/// $line');
      }
    }
  }

  /// Write a map to look up the `event` for a given `EventBody` type
  /// to simplify sending events back to the client:
  ///
  ///     this.sendEvent(FooEvent(x: 1))
  ///
  /// instead of
  ///
  ///     this.sendEvent(Event(
  ///       seq: seq++,
  ///       event: 'FooEvent',
  ///       arguments: {
  ///         x: 1
  ///         ...
  ///       }
  ///     ))
  void _writeEventTypeLookup(IndentableStringBuffer buffer, JsonSchema schema) {
    buffer
      ..writeln('const eventTypes = {')
      ..indent();
    for (final entry in schema.definitions.entries.sortedBy((e) => e.key)) {
      final name = entry.key;
      final type = entry.value;
      final baseType = type.baseType;

      if (baseType?.refName == 'Event') {
        final classProperties = schema.propertiesFor(type);
        final eventType = classProperties['event']!.literalValue;
        buffer.writeIndentedln("${name}Body: '$eventType',");
      }
    }
    buffer
      ..writeln('};')
      ..outdent();
  }

  /// Writes Dart fields for [properties], taking into account whether they are
  /// required for [type].
  void _writeFields(IndentableStringBuffer buffer, JsonType type,
      Map<String, JsonType> properties) {
    for (final entry in properties.entries.sortedBy((e) => e.key)) {
      final propertyName = entry.key;
      final fieldName = _dartSafeName(propertyName);
      final propertyType = entry.value;
      final isOptional = !type.requiresField(propertyName);
      final dartType = propertyType.asDartType(isOptional: isOptional);
      _writeDescription(buffer, propertyType.description);
      buffer.writeIndentedln('final $dartType $fieldName;');
    }
  }

  /// Writes an expression to deserialize a [valueCode].
  ///
  /// If [type] represents a spec type, it's `fromJson` function will be called.
  /// If [type] is a [List], it will be mapped over this function again.
  /// If [type] is an union, the appropriate `canParse` functions will be used to
  ///   determine which `fromJson` function to call.
  void _writeFromJsonExpression(
      IndentableStringBuffer buffer, JsonType type, String valueCode,
      {bool isOptional = false}) {
    final baseType = type.aliasFor ?? type;
    final dartType = type.asDartType(isOptional: isOptional);
    final dartTypeNotNullable = type.asDartType();
    final nullOp = isOptional ? '?' : '';

    if (baseType.isAny || baseType.isSimple) {
      buffer.write('$valueCode');
      if (dartType != 'Object?') {
        buffer.write(' as $dartType');
      }
    } else if (type.isList) {
      buffer.write('($valueCode as List$nullOp)$nullOp.map((item) => ');
      _writeFromJsonExpression(buffer, type.items!, 'item');
      buffer.write(').toList()');
    } else if (type.isUnion) {
      final types = type.unionTypes;

      // Write a check against each type, e.g.:
      // x is y ? new Either.tx(x) : (...)
      for (var i = 0; i < types.length; i++) {
        final isLast = i == types.length - 1;

        // For the last item, if we're optional we won't wrap if in a check, as
        // the constructor will only be called if canParse() returned true, so
        // it'll the only remaining option.
        if (!isLast || isOptional) {
          _writeTypeCheckCondition(buffer, types[i], valueCode,
              isOptional: false);
          buffer.write(' ? ');
        }
        buffer.write('$dartTypeNotNullable.t${i + 1}(');
        _writeFromJsonExpression(buffer, types[i], valueCode);
        buffer.write(')');

        if (!isLast) {
          buffer.write(' : ');
        } else if (isLast && isOptional) {
          buffer.write(' : null');
        }
      }
    } else if (type.isSpecType) {
      if (isOptional) {
        buffer.write('$valueCode == null ? null : ');
      }
      buffer.write(
          '$dartTypeNotNullable.fromJson($valueCode as Map<String, Object?>)');
    } else {
      throw 'Unable to type check $valueCode against $type';
    }
  }

  /// Writes a static `fromJson` method that converts an object into a spec type
  /// by calling its fromMap constructor.
  ///
  /// This is a helper method used as a tear-off since the constructor cannot be.
  void _writeFromJsonStaticMethod(
    IndentableStringBuffer buffer,
    String name,
  ) =>
      buffer.writeIndentedln(
          'static $name fromJson(Map<String, Object?> obj) => $name.fromMap(obj);');

  /// Writes a fromMap constructor to construct an object from a JSON map.
  void _writeFromMapConstructor(
    IndentableStringBuffer buffer,
    String name,
    JsonType type,
    Map<String, JsonType> properties, {
    bool callSuper = false,
  }) {
    buffer.writeIndented('$name.fromMap(Map<String, Object?> obj)');
    if (properties.isNotEmpty || callSuper) {
      buffer
        ..writeln(':')
        ..indent();
      var isFirst = true;
      for (final entry in properties.entries.sortedBy((e) => e.key)) {
        if (isFirst) {
          isFirst = false;
        } else {
          buffer.writeln(',');
        }

        final propertyName = entry.key;
        final fieldName = _dartSafeName(propertyName);
        final propertyType = entry.value;
        final isOptional = !type.requiresField(propertyName);

        buffer.writeIndented('$fieldName = ');
        _writeFromJsonExpression(buffer, propertyType, "obj['$propertyName']",
            isOptional: isOptional);
      }
      if (callSuper) {
        if (!isFirst) {
          buffer.writeln(',');
        }
        buffer.writeIndented('super.fromMap(obj)');
      }
      buffer.outdent();
    }
    buffer.writeln(';');
  }

  /// Writes a toJson method to construct a JSON map for this class, recursively
  /// calling through base classes.
  void _writeToJsonMethod(
    IndentableStringBuffer buffer,
    String name,
    JsonType type,
    Map<String, JsonType> properties, {
    bool callSuper = false,
  }) {
    if (callSuper) {
      buffer.writeIndentedln('@override');
    }
    buffer
      ..writeIndentedln('Map<String, Object?> toJson() => {')
      ..indent();
    if (callSuper) {
      buffer.writeIndentedln('...super.toJson(),');
    }
    for (final entry in properties.entries.sortedBy((e) => e.key)) {
      final propertyName = entry.key;
      final fieldName = _dartSafeName(propertyName);
      final isOptional = !type.requiresField(propertyName);
      buffer.writeIndented('');
      if (isOptional) {
        buffer.write('if ($fieldName != null) ');
      }
      buffer.writeln("'$propertyName': $fieldName, ");
    }
    buffer
      ..outdent()
      ..writeIndentedln('};');
  }

  /// Writes an expression that checks whether [valueCode] represents a [type].
  void _writeTypeCheckCondition(
      IndentableStringBuffer buffer, JsonType type, String valueCode,
      {required bool isOptional, bool invert = false}) {
    final baseType = type.aliasFor ?? type;
    final dartType = type.asDartType(isOptional: isOptional);

    // When the expression is inverted, invert the operators so the generated
    // code is easier to read.
    final opBang = invert ? '!' : '';
    final opTrue = invert ? 'false' : 'true';
    final opIs = invert ? 'is!' : 'is';
    final opEquals = invert ? '!=' : '==';
    final opAnd = invert ? '||' : '&&';
    final opOr = invert ? '&&' : '||';
    final opEvery = invert ? 'any' : 'every';

    if (baseType.isAny) {
      buffer.write(opTrue);
    } else if (dartType == 'Null') {
      buffer.write('$valueCode $opEquals null');
    } else if (baseType.isSimple) {
      buffer.write('$valueCode $opIs $dartType');
    } else if (type.isList) {
      buffer.write('($valueCode $opIs List');
      buffer.write(' $opAnd ($valueCode.$opEvery((item) => ');
      _writeTypeCheckCondition(buffer, type.items!, 'item',
          isOptional: false, invert: invert);
      buffer.write('))');
      buffer.write(')');
    } else if (type.isUnion) {
      final types = type.unionTypes;
      // To type check a union, we recursively check against each of its types.
      buffer.write('(');
      for (var i = 0; i < types.length; i++) {
        if (i != 0) {
          buffer.write(' $opOr ');
        }
        _writeTypeCheckCondition(buffer, types[i], valueCode,
            isOptional: false, invert: invert);
      }
      if (isOptional) {
        buffer.write(' $opOr $valueCode $opEquals null');
      }
      buffer.write(')');
    } else if (type.isSpecType) {
      buffer.write('$opBang${type.asDartType()}.canParse($valueCode)');
    } else {
      throw 'Unable to type check $valueCode against $type';
    }
  }

  /// Writes the description for [type], looking at the base type from the
  /// DAP spec if necessary.
  void _writeTypeDescription(IndentableStringBuffer buffer, JsonType type) {
    // In the DAP spec, many of the descriptions are on one of the allOf types
    // rather than the type itself.
    final description = type.description ??
        type.allOf
            ?.firstWhereOrNull((element) => element.description != null)
            ?.description;

    _writeDescription(buffer, description);
  }
}

/// A [StringBuffer] with support for indenting.
class IndentableStringBuffer extends StringBuffer {
  int _indentLevel = 0;
  final int _indentSpaces = 2;

  int get totalIndent => _indentLevel * _indentSpaces;
  String get _indentString => ' ' * totalIndent;

  void indent() => _indentLevel++;
  void outdent() => _indentLevel--;

  void writeIndented(Object obj) {
    write(_indentString);
    write(obj);
  }

  void writeIndentedln(Object obj) {
    write(_indentString);
    writeln(obj);
  }
}
