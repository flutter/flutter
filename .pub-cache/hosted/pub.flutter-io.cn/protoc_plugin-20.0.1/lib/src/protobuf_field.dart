// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../protoc.dart';

class ProtobufField {
  static final RegExp _hexLiteralRegex =
      RegExp(r'^0x[0-9a-f]+$', multiLine: false, caseSensitive: false);
  static final RegExp _integerLiteralRegex = RegExp(r'^[+-]?[0-9]+$');
  static final RegExp _decimalLiteralRegexA = RegExp(
      r'^[+-]?([0-9]*)\.[0-9]+(e[+-]?[0-9]+)?$',
      multiLine: false,
      caseSensitive: false);
  static final RegExp _decimalLiteralRegexB = RegExp(
      r'^[+-]?[0-9]+e[+-]?[0-9]+$',
      multiLine: false,
      caseSensitive: false);

  final FieldDescriptorProto descriptor;

  /// Dart names within a GeneratedMessage or `null` for an extension.
  final FieldNames? memberNames;

  final String fullName;
  final BaseType baseType;
  final ProtobufContainer parent;

  ProtobufField.message(
      FieldNames names, ProtobufContainer parent, GenerationContext ctx)
      : this._(names.descriptor, names, parent, ctx);

  ProtobufField.extension(FieldDescriptorProto descriptor,
      ProtobufContainer parent, GenerationContext ctx)
      : this._(descriptor, null, parent, ctx);

  ProtobufField._(this.descriptor, FieldNames? dartNames, this.parent,
      GenerationContext ctx)
      : memberNames = dartNames,
        fullName = '${parent.fullName}.${descriptor.name}',
        baseType = BaseType(descriptor, ctx);

  /// The index of this field in MessageGenerator.fieldList.
  ///
  /// `null` for an extension.
  int? get index => memberNames?.index;

  String? get quotedProtoName =>
      (_unCamelCase(descriptor.jsonName) == descriptor.name)
          ? null
          : "'${descriptor.name}'";

  /// The position of this field as it appeared in the original DescriptorProto.
  int? get sourcePosition => memberNames?.sourcePosition;

  /// True if the field is to be encoded with [deprecated = true] encoding.
  bool get isDeprecated => descriptor.options.deprecated;

  bool get isRequired =>
      descriptor.label == FieldDescriptorProto_Label.LABEL_REQUIRED;

  bool get isRepeated =>
      descriptor.label == FieldDescriptorProto_Label.LABEL_REPEATED;

  /// Whether a numeric field is repeated and must be encoded with packed
  /// encoding.
  ///
  /// In proto3 repeated fields are encoded as packed by default. The proto2
  /// requires `[packed=true]` option.
  bool get isPacked {
    if (!isRepeated) {
      return false; // only repeated fields can be packed
    }

    if (!baseType.isPackable) {
      return false;
    }

    switch (parent.fileGen!.syntax) {
      case ProtoSyntax.proto3:
        if (!descriptor.hasOptions()) {
          return true; // packed by default in proto3
        } else {
          return !descriptor.options.hasPacked() || descriptor.options.packed;
        }
      case ProtoSyntax.proto2:
        if (!descriptor.hasOptions()) {
          return false; // not packed by default in proto3
        } else {
          return descriptor.options.packed;
        }
    }
  }

  /// Whether the field has the `overrideGetter` annotation set to true.
  bool get overridesGetter => _hasBooleanOption(Dart_options.overrideGetter);

  /// Whether the field has the `overrideSetter` annotation set to true.
  bool get overridesSetter => _hasBooleanOption(Dart_options.overrideSetter);

  /// Whether the field has the `overrideHasMethod` annotation set to true.
  bool get overridesHasMethod =>
      _hasBooleanOption(Dart_options.overrideHasMethod);

  /// Whether the field has the `overrideClearMethod` annotation set to true.
  bool get overridesClearMethod =>
      _hasBooleanOption(Dart_options.overrideClearMethod);

  /// True if this field uses the Int64 from the fixnum package.
  bool get needsFixnumImport =>
      baseType.unprefixed == '$_fixnumImportPrefix.Int64';

  /// True if this field is a map field definition:
  /// `map<key_type, value_type> map_field = N`.
  bool get isMapField {
    if (!isRepeated || !baseType.isMessage) return false;
    final generator = baseType.generator as MessageGenerator;
    return generator._descriptor.options.hasMapEntry();
  }

  // `true` if this field should have a `hazzer` generated.
  bool get hasPresence {
    if (isRepeated) return false;
    return true;
    // TODO(sigurdm): to provide the correct semantics for non-optional proto3
    // fields would need something like the following:
    // return baseType.isMessage ||
    //   descriptor.proto3Optional ||
    //   parent.fileGen.descriptor.syntax == "proto2";
    //
    // This change would break any accidental uses of the proto3 hazzers, and
    // would require some clean-up.
    //
    // We could consider keeping hazzers for proto3-oneof fields. There they
    // seem useful and not breaking proto3 semantics, and dart protobuf uses it
    // for example in package:protobuf/src/protobuf/mixins/well_known.dart.
  }

  /// Returns the expression to use for the Dart type.
  ///
  /// This will be a List for repeated types.
  String getDartType() {
    if (isMapField) {
      final d = baseType.generator as MessageGenerator;
      var keyType = d._fieldList[0].baseType.getDartType(parent.fileGen!);
      var valueType = d._fieldList[1].baseType.getDartType(parent.fileGen!);
      return '$coreImportPrefix.Map<$keyType, $valueType>';
    }
    if (isRepeated) return baseType.getRepeatedDartType(parent.fileGen!);
    return baseType.getDartType(parent.fileGen!);
  }

  /// Returns the tag number of the underlying proto field.
  int get number => descriptor.number;

  /// Returns the constant in PbFieldType corresponding to this type.
  String get typeConstant {
    var prefix = 'O';
    if (isRequired) {
      prefix = 'Q';
    } else if (isPacked) {
      prefix = 'K';
    } else if (isRepeated) {
      prefix = 'P';
    }
    return '$protobufImportPrefix.PbFieldType.' +
        prefix +
        baseType.typeConstantSuffix;
  }

  static String _formatArguments(
      List<String?> positionals, Map<String, String?> named) {
    final args = positionals.toList();
    while (args.last == null) {
      args.removeLast();
    }
    for (var i = 0; i < args.length; i++) {
      if (args[i] == null) {
        args[i] = 'null';
      }
    }
    named.forEach((key, value) {
      if (value != null) {
        args.add('$key: $value');
      }
    });
    return args.join(', ');
  }

  /// Returns Dart code adding this field to a BuilderInfo object.
  /// The call will start with ".." and a method name.
  String generateBuilderInfoCall(String package) {
    assert(descriptor.hasJsonName());
    var quotedName = configurationDependent(
      'protobuf.omit_field_names',
      quoted(descriptor.jsonName),
    );

    var type = baseType.getDartType(parent.fileGen!);

    String invocation;

    var args = <String>[];
    var named = <String, String?>{'protoName': quotedProtoName};
    args.add('$number');
    args.add(quotedName);

    if (isMapField) {
      final generator = baseType.generator as MessageGenerator;
      var key = generator._fieldList[0];
      var value = generator._fieldList[1];
      var keyType = key.baseType.getDartType(parent.fileGen!);
      var valueType = value.baseType.getDartType(parent.fileGen!);

      invocation = 'm<$keyType, $valueType>';

      named['entryClassName'] = "'${generator.messageName}'";
      named['keyFieldType'] = key.typeConstant;
      named['valueFieldType'] = value.typeConstant;
      if (value.baseType.isMessage || value.baseType.isGroup) {
        named['valueCreator'] = '$valueType.create';
      }
      if (value.baseType.isEnum) {
        named['valueOf'] = '$valueType.valueOf';
        named['enumValues'] = '$valueType.values';
        named['defaultEnumValue'] = value.generateDefaultFunction();
      }
      if (package != '') {
        named['packageName'] =
            'const $protobufImportPrefix.PackageName(\'$package\')';
      }
    } else if (isRepeated) {
      if (typeConstant == '$protobufImportPrefix.PbFieldType.PS') {
        invocation = 'pPS';
      } else {
        args.add(typeConstant);
        if (baseType.isMessage || baseType.isGroup || baseType.isEnum) {
          invocation = 'pc<$type>';
        } else {
          invocation = 'p<$type>';
        }

        if (baseType.isMessage || baseType.isGroup) {
          named['subBuilder'] = '$type.create';
        } else if (baseType.isEnum) {
          named['valueOf'] = '$type.valueOf';
          named['enumValues'] = '$type.values';
          named['defaultEnumValue'] = generateDefaultFunction();
        }
      }
    } else {
      // Singular field.
      var makeDefault = generateDefaultFunction();

      if (baseType.isEnum) {
        args.add(typeConstant);
        named['defaultOrMaker'] = makeDefault;
        named['valueOf'] = '$type.valueOf';
        named['enumValues'] = '$type.values';
        invocation = 'e<$type>';
      } else if (makeDefault == null) {
        switch (type) {
          case '$coreImportPrefix.String':
            if (typeConstant == '$protobufImportPrefix.PbFieldType.OS') {
              invocation = 'aOS';
            } else if (typeConstant == '$protobufImportPrefix.PbFieldType.QS') {
              invocation = 'aQS';
            } else {
              invocation = 'a<$type>';
              args.add(typeConstant);
            }
            break;
          case '$coreImportPrefix.bool':
            if (typeConstant == '$protobufImportPrefix.PbFieldType.OB') {
              invocation = 'aOB';
            } else {
              invocation = 'a<$type>';
              args.add(typeConstant);
            }
            break;
          default:
            invocation = 'a<$type>';
            args.add(typeConstant);
            break;
        }
      } else {
        if (makeDefault == '$_fixnumImportPrefix.Int64.ZERO' &&
            type == '$_fixnumImportPrefix.Int64' &&
            typeConstant == '$protobufImportPrefix.PbFieldType.O6') {
          invocation = 'aInt64';
        } else {
          if (baseType.isMessage || baseType.isGroup) {
            named['subBuilder'] = '$type.create';
          }
          if (baseType.isMessage) {
            invocation = isRequired ? 'aQM<$type>' : 'aOM<$type>';
          } else {
            invocation = 'a<$type>';
            named['defaultOrMaker'] = makeDefault;
            args.add(typeConstant);
          }
        }
      }
    }
    return '..$invocation(${_formatArguments(args, named)})';
  }

  /// Returns a Dart expression that evaluates to this field's default value.
  ///
  /// Returns "null" if unavailable, in which case FieldSet._getDefault()
  /// should be called instead.
  String getDefaultExpr() {
    if (isRepeated) return 'null';
    switch (descriptor.type) {
      case FieldDescriptorProto_Type.TYPE_BOOL:
        return _getDefaultAsBoolExpr('false')!;
      case FieldDescriptorProto_Type.TYPE_INT32:
      case FieldDescriptorProto_Type.TYPE_UINT32:
      case FieldDescriptorProto_Type.TYPE_SINT32:
      case FieldDescriptorProto_Type.TYPE_FIXED32:
      case FieldDescriptorProto_Type.TYPE_SFIXED32:
        return _getDefaultAsInt32Expr('0')!;
      case FieldDescriptorProto_Type.TYPE_STRING:
        return _getDefaultAsStringExpr("''")!;
      default:
        return 'null';
    }
  }

  /// Returns a function expression that returns the field's default value.
  String? generateDefaultFunction() {
    assert(!isRepeated);
    switch (descriptor.type) {
      case FieldDescriptorProto_Type.TYPE_BOOL:
        return _getDefaultAsBoolExpr(null);
      case FieldDescriptorProto_Type.TYPE_FLOAT:
      case FieldDescriptorProto_Type.TYPE_DOUBLE:
        if (!descriptor.hasDefaultValue()) {
          return null;
        } else if ('0.0' == descriptor.defaultValue ||
            '0' == descriptor.defaultValue) {
          return null;
        } else if (descriptor.defaultValue == 'inf') {
          return '$coreImportPrefix.double.infinity';
        } else if (descriptor.defaultValue == '-inf') {
          return '$coreImportPrefix.double.negativeInfinity';
        } else if (descriptor.defaultValue == 'nan') {
          return '$coreImportPrefix.double.nan';
        } else if (_hexLiteralRegex.hasMatch(descriptor.defaultValue)) {
          return '(${descriptor.defaultValue}).toDouble()';
        } else if (_integerLiteralRegex.hasMatch(descriptor.defaultValue)) {
          return '${descriptor.defaultValue}.0';
        } else if (_decimalLiteralRegexA.hasMatch(descriptor.defaultValue) ||
            _decimalLiteralRegexB.hasMatch(descriptor.defaultValue)) {
          return descriptor.defaultValue;
        }
        throw _invalidDefaultValue;
      case FieldDescriptorProto_Type.TYPE_INT32:
      case FieldDescriptorProto_Type.TYPE_UINT32:
      case FieldDescriptorProto_Type.TYPE_SINT32:
      case FieldDescriptorProto_Type.TYPE_FIXED32:
      case FieldDescriptorProto_Type.TYPE_SFIXED32:
        return _getDefaultAsInt32Expr(null);
      case FieldDescriptorProto_Type.TYPE_INT64:
      case FieldDescriptorProto_Type.TYPE_UINT64:
      case FieldDescriptorProto_Type.TYPE_SINT64:
      case FieldDescriptorProto_Type.TYPE_FIXED64:
      case FieldDescriptorProto_Type.TYPE_SFIXED64:
        var value = '0';
        if (descriptor.hasDefaultValue()) value = descriptor.defaultValue;
        if (value == '0') return '$_fixnumImportPrefix.Int64.ZERO';
        return "$protobufImportPrefix.parseLongInt('$value')";
      case FieldDescriptorProto_Type.TYPE_STRING:
        return _getDefaultAsStringExpr(null);
      case FieldDescriptorProto_Type.TYPE_BYTES:
        if (!descriptor.hasDefaultValue() || descriptor.defaultValue.isEmpty) {
          return null;
        }
        var byteList = descriptor.defaultValue.codeUnits
            .map((b) => '0x${b.toRadixString(16)}')
            .join(',');
        return '() => <$coreImportPrefix.int>[$byteList]';
      case FieldDescriptorProto_Type.TYPE_GROUP:
      case FieldDescriptorProto_Type.TYPE_MESSAGE:
        return '${baseType.getDartType(parent.fileGen!)}.getDefault';
      case FieldDescriptorProto_Type.TYPE_ENUM:
        var className = baseType.getDartType(parent.fileGen!);
        final gen = baseType.generator as EnumGenerator;
        if (descriptor.hasDefaultValue() &&
            descriptor.defaultValue.isNotEmpty) {
          return '$className.${descriptor.defaultValue}';
        } else if (gen._canonicalValues.isNotEmpty) {
          return '$className.${gen.dartNames[gen._canonicalValues[0].name]}';
        }
        return null;
      default:
        throw _typeNotImplemented('generatedDefaultFunction');
    }
  }

  String? _getDefaultAsBoolExpr(String? noDefault) {
    if (descriptor.hasDefaultValue() && 'false' != descriptor.defaultValue) {
      return descriptor.defaultValue;
    }
    return noDefault;
  }

  String? _getDefaultAsStringExpr(String? noDefault) {
    if (!descriptor.hasDefaultValue() || descriptor.defaultValue.isEmpty) {
      return noDefault;
    }

    return quoted(descriptor.defaultValue);
  }

  String? _getDefaultAsInt32Expr(String? noDefault) {
    if (descriptor.hasDefaultValue() && '0' != descriptor.defaultValue) {
      return descriptor.defaultValue;
    }
    return noDefault;
  }

  bool _hasBooleanOption(Extension extension) =>
      descriptor.options.getExtension(extension) as bool? ?? false;

  String get _invalidDefaultValue => 'dart-protoc-plugin:'
      ' invalid default value (${descriptor.defaultValue})'
      ' found in field $fullName';

  String _typeNotImplemented(String methodName) => 'dart-protoc-plugin:'
      ' $methodName not implemented for type (${descriptor.type})'
      ' found in field $fullName';

  static final RegExp _upperCase = RegExp('[A-Z]');

  static String _unCamelCase(String name) {
    return name.replaceAllMapped(
        _upperCase, (match) => '_${match.group(0)!.toLowerCase()}');
  }
}
