// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This build-time codegen script runs against the Dart SDK's package_config.json.
// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Classification of how a Dart field is packed across the Dart <-> C++ FFI boundary.
///
/// Only Dart built-in primitives (`bool`, `int`, `double`, `String`, `List<String>`),
/// closed `enum`s in `dart:ui`, and types with a private `@_CppType` extension type
/// in `dart:ui` are accepted. Any other type throws an [UnsupportedError].
FieldEncodingSpec _classifyType(
  String dartType, {
  required Map<String, List<String>> knownEnums,
  required Map<String, FieldEncodingSpec> extensionTypeEncoders,
  required String className,
  required String fieldName,
}) {
  // Strip nullability suffix.
  final String baseType = dartType.endsWith('?')
      ? dartType.substring(0, dartType.length - 1)
      : dartType;

  // 1. Dart built-in primitives
  switch (baseType) {
    case 'bool':
      return const FieldEncodingSpec(kind: StorageKind.bitFlag, byteSize: 0, cppFieldType: 'bool');
    case 'int':
      return const FieldEncodingSpec(
        kind: StorageKind.primitive32,
        byteSize: 4,
        cppFieldType: 'int32_t',
        cppPackedType: 'int32_t',
        dartByteDataSetter: 'setInt32',
        dartValueExpr: '{name}',
      );
    case 'double':
      return const FieldEncodingSpec(
        kind: StorageKind.primitive64,
        byteSize: 8,
        cppFieldType: 'double',
        cppPackedType: 'double',
        dartByteDataSetter: 'setFloat64',
        dartValueExpr: '{name}',
      );
    case 'String':
      return const FieldEncodingSpec(
        kind: StorageKind.objectHandle,
        byteSize: 0,
        cppFieldType: 'std::string',
        dartObjectExpr: '{name}',
      );
    case 'List<String>':
      return const FieldEncodingSpec(
        kind: StorageKind.objectHandle,
        byteSize: 0,
        cppFieldType: 'std::vector<std::string>',
        dartObjectExpr: '{name}',
      );
  }

  // 2. Custom types mapped via private `@_CppType` extension types in `dart:ui`
  final FieldEncodingSpec? extensionSpec = extensionTypeEncoders[baseType];
  if (extensionSpec != null) {
    return extensionSpec;
  }

  // 3. Closed Enum types discovered in `dart:ui` AST
  final List<String>? enumValues = knownEnums[baseType];
  if (enumValues != null) {
    if (enumValues.length <= 2) {
      return FieldEncodingSpec(
        kind: StorageKind.bitFlag,
        byteSize: 0,
        cppFieldType: baseType,
        dartValueExpr: '{name}.index',
        enumTypeName: baseType,
      );
    }
    return FieldEncodingSpec(
      kind: StorageKind.primitive32,
      byteSize: 4,
      cppFieldType: baseType,
      cppPackedType: 'int32_t',
      dartByteDataSetter: 'setInt32',
      dartValueExpr: '{name}.index',
      enumTypeName: baseType,
    );
  }

  // 4. Unknown / open custom type -> throw an error!
  throw UnsupportedError(
    'Cannot generate FFI encoding for `$className.$fieldName` of type `$dartType`. '
    '`$baseType` is neither a primitive type, a closed `enum` in `dart:ui`, '
    'nor mapped by an `@_CppType` extension type.',
  );
}

/// How a field is laid out in the generated FFI payload.
enum StorageKind {
  /// Stored as a bit directly inside the 64-bit header mask (0 extra bytes).
  bitFlag,

  /// 8-byte aligned primitive (e.g. double, int64_t).
  primitive64,

  /// 4-byte aligned primitive (e.g. int32_t, uint32_t, enum index).
  primitive32,

  /// Heap object passed via the Dart_Handle object list.
  objectHandle,
}

/// Specification of a single field's Dart and C++ representations.
class FieldEncodingSpec {
  /// Creates a [FieldEncodingSpec].
  const FieldEncodingSpec({
    required this.kind,
    required this.byteSize,
    required this.cppFieldType,
    this.cppPackedType,
    this.dartByteDataSetter,
    this.dartValueExpr,
    this.dartObjectExpr,
    this.enumTypeName,
  });

  /// The storage bucket used for this field.
  final StorageKind kind;

  /// The number of bytes occupied in the packed `ByteData` payload.
  final int byteSize;

  /// The C++ type on the target `txt::*` class.
  final String cppFieldType;

  /// The C++ primitive type inside the `Packed*` struct, if applicable.
  final String? cppPackedType;

  /// The `ByteData` setter method name on the Dart side, if applicable.
  final String? dartByteDataSetter;

  /// Expression template converting the Dart field into its primitive value.
  final String? dartValueExpr;

  /// Expression template converting the Dart field into an object handle.
  final String? dartObjectExpr;

  /// If this field's type is a closed Dart enum, the name of that enum.
  final String? enumTypeName;
}

/// A parsed field from a style class in `dart:ui` along with its computed layout offsets.
class StyleField {
  /// Creates a [StyleField].
  StyleField({
    required this.name,
    required this.dartType,
    required this.spec,
    this.cppDefaultInitializer,
  });

  /// The Dart identifier name of the field.
  final String name;

  /// The Dart type annotation string (including `?` if nullable).
  final String dartType;

  /// The encoding specification for [dartType].
  final FieldEncodingSpec spec;

  /// Optional C++ default initializer expression extracted from `@_Default(...)`.
  final String? cppDefaultInitializer;

  /// Bit index in the 64-bit `mask` indicating whether this field is non-null.
  late int presenceBitIndex;

  /// Optional bit index in the 64-bit `mask` storing a 1-bit boolean/enum value.
  int? valueBitIndex;

  /// Byte offset in the `ByteData` buffer and `Packed*` C++ struct.
  int? byteOffset;

  /// Index in the `List<Object?>` handle array for heap objects.
  int? objectIndex;

  /// Whether [dartType] is nullable.
  bool get isNullable => dartType.endsWith('?');

  /// The `snake_case` name used in C++.
  String get snakeName =>
      name.replaceAllMapped(RegExp(r'[A-Z]'), (Match m) => '_${m.group(0)!.toLowerCase()}');

  /// The `PascalCase` suffix used for C++ `k*` constants.
  String get constantSuffix => name[0].toUpperCase() + name.substring(1);
}

/// The complete layout specification for a style class (e.g. `TextStyle`).
class StyleClassSpec {
  /// Creates a [StyleClassSpec].
  StyleClassSpec({
    required this.className,
    required this.fields,
    required this.totalByteSize,
    required this.objectCount,
  });

  /// The name of the Dart/C++ style class.
  final String className;

  /// The ordered list of fields in the class.
  final List<StyleField> fields;

  /// The 8-byte aligned size of the `ByteData` and `Packed*` C++ struct.
  final int totalByteSize;

  /// The number of heap object handles required by this class.
  final int objectCount;
}

/// AST visitor that collects all `enum` declarations and `static const` class
/// fields in `dart:ui`.
class _MetadataCollectorVisitor extends SimpleAstVisitor<void> {
  final Map<String, List<String>> enums = <String, List<String>>{};
  final Map<String, Map<String, Expression>> classStaticConsts =
      <String, Map<String, Expression>>{};
  final Map<String, FieldEncodingSpec> extensionTypeEncoders = <String, FieldEncodingSpec>{};

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final String enumName = node.namePart.typeName.lexeme;
    final List<String> constants = node.body.constants
        .map((EnumConstantDeclaration c) => c.name.lexeme)
        .toList();
    enums[enumName] = constants;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final String className = node.namePart.typeName.lexeme;
    final ClassBody body = node.body;
    if (body is! BlockClassBody) {
      return;
    }
    final consts = <String, Expression>{};
    for (final ClassMember member in body.members) {
      if (member is FieldDeclaration && member.isStatic && member.fields.isConst) {
        for (final VariableDeclaration v in member.fields.variables) {
          if (v.initializer != null) {
            consts[v.name.lexeme] = v.initializer!;
          }
        }
      }
    }
    if (consts.isNotEmpty) {
      classStaticConsts[className] = consts;
    }
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final ClassNamePart namePart = node.namePart;
    if (namePart is! PrimaryConstructorDeclaration || namePart.typeParameters != null) {
      return;
    }
    final NodeList<FormalParameter> params = namePart.formalParameters.parameters;
    if (params.length != 1) {
      return;
    }
    final String? representedDartType = params.first.type?.toSource();
    if (representedDartType == null) {
      return;
    }

    final String extensionTypeName = namePart.typeName.lexeme;
    final ClassBody body = node.body;
    if (body is! BlockClassBody) {
      return;
    }

    String? encodeReturnType;
    for (final ClassMember member in body.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'encode') {
        encodeReturnType = member.returnType?.toSource();
        break;
      }
    }
    if (encodeReturnType == null) {
      return;
    }

    String? cppFieldType;
    String? cppPackedType;
    for (final Annotation annotation in node.metadata) {
      if (annotation.name.name == '_CppType') {
        final NodeList<Argument>? args = annotation.arguments?.arguments;
        if (args != null && args.isNotEmpty) {
          for (final Argument arg in args) {
            if (arg is NamedArgument && arg.name.lexeme == 'cppPackedType') {
              final Expression val = arg.argumentExpression;
              if (val is SimpleStringLiteral) {
                cppPackedType = val.value;
              }
            } else if (arg is SimpleStringLiteral) {
              cppFieldType = arg.value;
            }
          }
        }
      }
    }

    final callExpr = '$extensionTypeName({name}).encode()';
    switch (encodeReturnType) {
      case 'bool':
        extensionTypeEncoders[representedDartType] = FieldEncodingSpec(
          kind: StorageKind.bitFlag,
          byteSize: 0,
          cppFieldType: cppFieldType ?? 'bool',
          dartValueExpr: '$callExpr ? 1 : 0',
        );
      case 'int':
        final String packed = cppPackedType ?? 'int32_t';
        final setter = packed == 'uint32_t' ? 'setUint32' : 'setInt32';
        extensionTypeEncoders[representedDartType] = FieldEncodingSpec(
          kind: StorageKind.primitive32,
          byteSize: 4,
          cppFieldType: cppFieldType ?? 'int32_t',
          cppPackedType: packed,
          dartByteDataSetter: setter,
          dartValueExpr: callExpr,
        );
      case 'double':
        extensionTypeEncoders[representedDartType] = FieldEncodingSpec(
          kind: StorageKind.primitive64,
          byteSize: 8,
          cppFieldType: cppFieldType ?? 'double',
          cppPackedType: cppPackedType ?? 'double',
          dartByteDataSetter: 'setFloat64',
          dartValueExpr: callExpr,
        );
      case 'String':
        extensionTypeEncoders[representedDartType] = FieldEncodingSpec(
          kind: StorageKind.objectHandle,
          byteSize: 0,
          cppFieldType: cppFieldType ?? 'std::string',
          dartObjectExpr: callExpr,
        );
      case 'List<String>':
        extensionTypeEncoders[representedDartType] = FieldEncodingSpec(
          kind: StorageKind.objectHandle,
          byteSize: 0,
          cppFieldType: cppFieldType ?? 'std::vector<std::string>',
          dartObjectExpr: callExpr,
        );
      default:
        if (cppFieldType == null) {
          return;
        }
        extensionTypeEncoders[representedDartType] = FieldEncodingSpec(
          kind: StorageKind.objectHandle,
          byteSize: 0,
          cppFieldType: cppFieldType,
          dartObjectExpr: callExpr,
        );
    }
  }
}

/// Evaluates a `@_Default(...)` or `@Default(...)` constant AST expression into
/// its C++ initializer string using the parsed AST metadata.
String? _evaluateDefaultAnnotation(
  NodeList<Annotation> metadata, {
  required Map<String, List<String>> knownEnums,
  required Map<String, Map<String, Expression>> classStaticConsts,
}) {
  for (final annotation in metadata) {
    final String name = annotation.name.name;
    if (name == '_Default' || name == 'Default') {
      final NodeList<Argument>? args = annotation.arguments?.arguments;
      if (args != null && args.isNotEmpty) {
        final Argument firstArg = args.first;
        if (firstArg is Expression) {
          return _evalConstExprToCpp(
            firstArg,
            knownEnums: knownEnums,
            classStaticConsts: classStaticConsts,
          );
        }
      }
    }
  }
  return null;
}

String _evalConstExprToCpp(
  Expression expr, {
  required Map<String, List<String>> knownEnums,
  required Map<String, Map<String, Expression>> classStaticConsts,
  String? enclosingClass,
}) {
  if (expr is DoubleLiteral || expr is IntegerLiteral || expr is BooleanLiteral) {
    return expr.toSource();
  }
  if (expr is PrefixExpression) {
    return expr.toSource();
  }
  if (expr is SimpleStringLiteral) {
    return '"${expr.value}"';
  }
  if (expr is InstanceCreationExpression) {
    final NodeList<Argument> args = expr.argumentList.arguments;
    if (args.length == 1 && args.first is Expression) {
      return _evalConstExprToCpp(
        args.first as Expression,
        knownEnums: knownEnums,
        classStaticConsts: classStaticConsts,
        enclosingClass: enclosingClass,
      );
    }
  }
  if (expr is MethodInvocation) {
    final NodeList<Argument> args = expr.argumentList.arguments;
    if (args.length == 1 && args.first is Expression) {
      return _evalConstExprToCpp(
        args.first as Expression,
        knownEnums: knownEnums,
        classStaticConsts: classStaticConsts,
        enclosingClass: enclosingClass,
      );
    }
  }
  if (expr is PrefixedIdentifier) {
    final String prefix = expr.prefix.name;
    final String id = expr.identifier.name;
    if (knownEnums.containsKey(prefix)) {
      return '$prefix::$id';
    }
    final Expression? target = classStaticConsts[prefix]?[id];
    if (target != null) {
      return _evalConstExprToCpp(
        target,
        knownEnums: knownEnums,
        classStaticConsts: classStaticConsts,
        enclosingClass: prefix,
      );
    }
  }
  if (expr is SimpleIdentifier && enclosingClass != null) {
    final Expression? target = classStaticConsts[enclosingClass]?[expr.name];
    if (target != null) {
      return _evalConstExprToCpp(
        target,
        knownEnums: knownEnums,
        classStaticConsts: classStaticConsts,
        enclosingClass: enclosingClass,
      );
    }
  }
  return expr.toSource();
}

/// AST visitor that extracts style class definitions (`StrutStyle`, `TextStyle`, `ParagraphStyle`)
/// and validates that every field/parameter type is a closed/supported type.
class _StyleClassVisitor extends SimpleAstVisitor<void> {
  _StyleClassVisitor({required this.targetClasses, required this.metadata});

  final Set<String> targetClasses;
  final _MetadataCollectorVisitor metadata;
  final Map<String, List<StyleField>> extractedClasses = <String, List<StyleField>>{};

  static const Set<String> _ignoredInternalFields = <String>{'_encoded'};

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final String className = node.namePart.typeName.lexeme;
    if (!targetClasses.contains(className)) {
      return;
    }

    final ClassBody body = node.body;
    if (body is! BlockClassBody) {
      return;
    }

    final fieldTypesByName = <String, String>{};
    final fieldDefaultsByName = <String, String>{};

    // 1. Inspect the primary constructor parameters (the public source of truth).
    for (final ClassMember member in body.members) {
      if (member is ConstructorDeclaration && member.name == null) {
        for (final FormalParameter param in member.parameters.parameters) {
          final String? paramName = param.name?.lexeme;
          if (paramName == null) {
            continue;
          }
          final String? typeSource = param.type?.toSource();
          if (typeSource != null) {
            fieldTypesByName[paramName] = typeSource;
          }
          final String? defaultCpp = _evaluateDefaultAnnotation(
            param.metadata,
            knownEnums: metadata.enums,
            classStaticConsts: metadata.classStaticConsts,
          );
          if (defaultCpp != null) {
            fieldDefaultsByName[paramName] = defaultCpp;
          }
        }
      }
    }

    // 2. Also inspect all non-static FieldDeclarations on the class so that
    // adding an unrepresentable field directly to the class body is also caught.
    for (final ClassMember member in body.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        final String? typeSource = member.fields.type?.toSource();
        if (typeSource == null) {
          continue;
        }
        final String? defaultCpp = _evaluateDefaultAnnotation(
          member.metadata,
          knownEnums: metadata.enums,
          classStaticConsts: metadata.classStaticConsts,
        );
        for (final VariableDeclaration variable in member.fields.variables) {
          final String rawName = variable.name.lexeme;
          if (_ignoredInternalFields.contains(rawName)) {
            continue;
          }
          final String normalizedName = rawName.startsWith('_') ? rawName.substring(1) : rawName;
          fieldTypesByName.putIfAbsent(normalizedName, () => typeSource);
          if (defaultCpp != null) {
            fieldDefaultsByName.putIfAbsent(normalizedName, () => defaultCpp);
          }
        }
      }
    }

    final fields = <StyleField>[];
    fieldTypesByName.forEach((String fieldName, String dartType) {
      final FieldEncodingSpec spec = _classifyType(
        dartType,
        knownEnums: metadata.enums,
        extensionTypeEncoders: metadata.extensionTypeEncoders,
        className: className,
        fieldName: fieldName,
      );
      fields.add(
        StyleField(
          name: fieldName,
          dartType: dartType,
          spec: spec,
          cppDefaultInitializer: fieldDefaultsByName[fieldName],
        ),
      );
    });

    extractedClasses[className] = fields;
  }
}

/// Computes the optimal zero-padding memory layout for [fields].
StyleClassSpec computeOptimalLayout(String className, List<StyleField> fields) {
  var nextBit = 0;
  for (final field in fields) {
    field.presenceBitIndex = nextBit++;
    if (field.spec.kind == StorageKind.bitFlag) {
      field.valueBitIndex = nextBit++;
    }
  }
  if (nextBit > 64) {
    throw StateError('$className requires $nextBit header bits, exceeding uint64_t mask capacity.');
  }

  // Reserve bytes 0..7 for uint64_t mask.
  var currentByteOffset = 8;

  // Place 8-byte primitives first (naturally 8-byte aligned, 0 padding).
  for (final field in fields) {
    if (field.spec.kind == StorageKind.primitive64) {
      assert(currentByteOffset % 8 == 0);
      field.byteOffset = currentByteOffset;
      currentByteOffset += 8;
    }
  }

  // Place 4-byte primitives second (naturally 4-byte aligned, 0 padding).
  for (final field in fields) {
    if (field.spec.kind == StorageKind.primitive32) {
      assert(currentByteOffset % 4 == 0);
      field.byteOffset = currentByteOffset;
      currentByteOffset += 4;
    }
  }

  // Pad total struct size to a multiple of 8 bytes so C++ `sizeof(Packed*)`
  // matches ByteData length without tail-padding mismatch on 64-bit compilers.
  final int alignedTotalBytes = (currentByteOffset + 7) & ~7;

  // Assign indices in the Dart_Handle object array for heap types.
  var nextObjectIndex = 0;
  for (final field in fields) {
    if (field.spec.kind == StorageKind.objectHandle) {
      field.objectIndex = nextObjectIndex++;
    }
  }

  return StyleClassSpec(
    className: className,
    fields: fields,
    totalByteSize: alignedTotalBytes,
    objectCount: nextObjectIndex,
  );
}

/// Generates the C++ header containing:
/// 1. The generated `txt::*` enum classes and `txt::StrutStyle`, `txt::TextStyle`,
///    and `txt::ParagraphStyle` classes (with `@_Default` initializers and `equals`).
/// 2. The aligned `Packed*` FFI structs, bitmasks, and `ApplyPacked*` decoders.
String generateCppHeader(List<StyleClassSpec> specs, Map<String, List<String>> knownEnums) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT BY HAND.')
    ..writeln('// Generated from //flutter/lib/ui/text.dart by generate_text_styles.dart.')
    ..writeln()
    ..writeln('#ifndef FLUTTER_LIB_UI_TEXT_TEXT_STYLE_GEN_H_')
    ..writeln('#define FLUTTER_LIB_UI_TEXT_TEXT_STYLE_GEN_H_')
    ..writeln()
    ..writeln('#include <cstdint>')
    ..writeln('#include <limits>')
    ..writeln('#include <optional>')
    ..writeln('#include <string>')
    ..writeln('#include <vector>')
    ..writeln()
    ..writeln('#include "flutter/display_list/dl_paint.h"')
    ..writeln('#include "flutter/txt/src/txt/font_features.h"')
    ..writeln('#include "flutter/txt/src/txt/text_shadow.h"')
    ..writeln('#include "third_party/skia/include/core/SkColor.h"')
    ..writeln()
    ..writeln('namespace txt {')
    ..writeln();

  // 1. Emit referenced closed enums in `namespace txt`.
  final emittedEnums = <String>{};
  for (final spec in specs) {
    for (final StyleField field in spec.fields) {
      final String? enumName = field.spec.enumTypeName;
      if (enumName != null && emittedEnums.add(enumName)) {
        final List<String> constants = knownEnums[enumName]!;
        buffer.writeln('enum class $enumName {');
        for (final constant in constants) {
          buffer.writeln('  $constant,');
        }
        buffer.writeln('};');
        buffer.writeln();
      }
    }
  }

  // 2. Emit `txt::StrutStyle`, `txt::TextStyle`, and `txt::ParagraphStyle`.
  final specsByName = <String, StyleClassSpec>{
    for (final StyleClassSpec s in specs) s.className: s,
  };

  for (final spec in specs) {
    final String cls = spec.className;
    buffer.writeln('class $cls {');
    buffer.writeln(' public:');
    for (final StyleField field in spec.fields) {
      final String cppType = field.spec.cppFieldType;
      final String name = field.snakeName;
      final String? init = field.cppDefaultInitializer;
      if (init != null) {
        buffer.writeln('  $cppType $name = $init;');
      } else if (field.spec.kind == StorageKind.primitive32 ||
          field.spec.kind == StorageKind.primitive64) {
        // Nullable primitive without @_Default becomes std::optional<T>
        buffer.writeln('  std::optional<$cppType> $name;');
      } else {
        buffer.writeln('  $cppType $name;');
      }
    }
    buffer.writeln();
    buffer.writeln('  bool operator==(const $cls& other) const = default;');
    buffer.writeln('  bool equals(const $cls& other) const { return *this == other; }');

    // Auto-generate `ParagraphStyle::GetTextStyle()` from the intersection of fields.
    if (cls == 'ParagraphStyle' && specsByName.containsKey('TextStyle')) {
      final StyleClassSpec textStyleSpec = specsByName['TextStyle']!;
      final textStyleFields = <String, StyleField>{
        for (final StyleField f in textStyleSpec.fields) f.snakeName: f,
      };
      buffer.writeln();
      buffer.writeln('  TextStyle GetTextStyle() const {');
      buffer.writeln('    TextStyle result;');
      for (final StyleField f in spec.fields) {
        final StyleField? target = textStyleFields[f.snakeName];
        if (target != null && target.spec.cppFieldType == f.spec.cppFieldType) {
          buffer.writeln('    result.${f.snakeName} = ${f.snakeName};');
        }
      }
      buffer.writeln('    return result;');
      buffer.writeln('  }');
    }

    buffer.writeln('};');
    buffer.writeln();
  }

  buffer.writeln('}  // namespace txt');
  buffer.writeln();
  buffer.writeln('namespace flutter {');
  buffer.writeln();

  // 3. Emit `Packed*` structs, bitmasks, and `ApplyPacked*Primitives` decoders.
  for (final spec in specs) {
    final String cls = spec.className;
    buffer.writeln(
      '// ============================================================================',
    );
    buffer.writeln(
      '// $cls Encoding & Packed Layout (${spec.totalByteSize} bytes, 0 alignment holes)',
    );
    buffer.writeln(
      '// ============================================================================',
    );
    buffer.writeln();

    for (final StyleField field in spec.fields) {
      buffer.writeln(
        'inline constexpr uint64_t k${cls}Has${field.constantSuffix}Mask = 1ULL << ${field.presenceBitIndex};',
      );
      if (field.valueBitIndex != null) {
        buffer.writeln(
          'inline constexpr uint64_t k$cls${field.constantSuffix}ValueBit = 1ULL << ${field.valueBitIndex};',
        );
      }
    }
    buffer.writeln();

    if (spec.objectCount > 0) {
      for (final StyleField field in spec.fields) {
        if (field.objectIndex != null) {
          buffer.writeln(
            'inline constexpr int k$cls${field.constantSuffix}ObjectIndex = ${field.objectIndex};',
          );
        }
      }
      buffer.writeln('inline constexpr int k${cls}ObjectCount = ${spec.objectCount};');
      buffer.writeln();
    }

    buffer.writeln('struct Packed$cls {');
    buffer.writeln('  uint64_t mask;  // offset 0');
    for (final StyleField field in spec.fields) {
      if (field.spec.kind == StorageKind.primitive64) {
        buffer.writeln(
          '  ${field.spec.cppPackedType} ${field.snakeName};  // offset ${field.byteOffset}',
        );
      }
    }
    var primitive32Count = 0;
    for (final StyleField field in spec.fields) {
      if (field.spec.kind == StorageKind.primitive32) {
        buffer.writeln(
          '  ${field.spec.cppPackedType} ${field.snakeName};  // offset ${field.byteOffset}',
        );
        primitive32Count++;
      }
    }
    if (primitive32Count.isOdd) {
      buffer.writeln('  uint32_t _padding;  // tail padding to 8-byte boundary');
    }
    buffer.writeln('};');
    buffer.writeln(
      'static_assert(sizeof(Packed$cls) == ${spec.totalByteSize}, "Packed$cls size mismatch");',
    );
    buffer.writeln();

    buffer.writeln('inline void ApplyPacked${cls}Primitives(');
    buffer.writeln('    const Packed$cls& packed,');
    buffer.writeln('    txt::$cls& style) {');
    for (final StyleField field in spec.fields) {
      final maskConst = 'k${cls}Has${field.constantSuffix}Mask';
      final String cppFieldType = field.spec.enumTypeName != null
          ? 'txt::${field.spec.cppFieldType}'
          : field.spec.cppFieldType;
      if (field.spec.kind == StorageKind.bitFlag) {
        final valBit = 'k$cls${field.constantSuffix}ValueBit';
        if (cppFieldType == 'bool') {
          buffer.writeln('  if (packed.mask & $maskConst) {');
          buffer.writeln('    style.${field.snakeName} = (packed.mask & $valBit) != 0;');
          buffer.writeln('  }');
        } else {
          buffer.writeln('  if (packed.mask & $maskConst) {');
          buffer.writeln(
            '    style.${field.snakeName} = static_cast<$cppFieldType>((packed.mask & $valBit) != 0 ? 1 : 0);',
          );
          buffer.writeln('  }');
        }
      } else if (field.spec.kind == StorageKind.primitive64 ||
          field.spec.kind == StorageKind.primitive32) {
        buffer.writeln('  if (packed.mask & $maskConst) {');
        if (cppFieldType != field.spec.cppPackedType) {
          buffer.writeln(
            '    style.${field.snakeName} = static_cast<$cppFieldType>(packed.${field.snakeName});',
          );
        } else {
          buffer.writeln('    style.${field.snakeName} = packed.${field.snakeName};');
        }
        buffer.writeln('  }');
      }
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  buffer.writeln('}  // namespace flutter');
  buffer.writeln();
  buffer.writeln('#endif  // FLUTTER_LIB_UI_TEXT_TEXT_STYLE_GEN_H_');
  return buffer.toString();
}

/// Generates the Dart encoding helper for each style class.
String generateDartCode(List<StyleClassSpec> specs) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT BY HAND.')
    ..writeln('// Generated from //flutter/lib/ui/text.dart by generate_text_styles.dart.')
    ..writeln()
    ..writeln('part of dart.ui;')
    ..writeln();

  for (final spec in specs) {
    final String cls = spec.className;
    buffer.writeln(
      '// ============================================================================',
    );
    buffer.writeln('// $cls Generated Encoder (${spec.totalByteSize} bytes)');
    buffer.writeln(
      '// ============================================================================',
    );
    buffer.writeln();
    buffer.writeln('ByteData _encode${cls}Primitives(');
    for (final StyleField field in spec.fields) {
      buffer.writeln('  ${field.dartType} ${field.name},');
    }
    buffer.writeln(') {');
    buffer.writeln('  final data = ByteData(${spec.totalByteSize});');
    buffer.writeln('  var mask = 0;');

    for (final StyleField field in spec.fields) {
      final String name = field.name;
      if (field.isNullable) {
        buffer.writeln('  if ($name != null) {');
      } else {
        buffer.writeln('  {');
      }
      buffer.writeln('    mask |= 1 << ${field.presenceBitIndex};');
      if (field.spec.kind == StorageKind.bitFlag) {
        final bitExpr = field.spec.dartValueExpr != null
            ? '${field.spec.dartValueExpr!.replaceAll('{name}', name)} != 0'
            : name;
        buffer.writeln('    if ($bitExpr) {');
        buffer.writeln('      mask |= 1 << ${field.valueBitIndex};');
        buffer.writeln('    }');
      } else if (field.byteOffset != null) {
        final String valExpr = field.spec.dartValueExpr!.replaceAll('{name}', name);
        buffer.writeln(
          '    data.${field.spec.dartByteDataSetter}(${field.byteOffset}, $valExpr, _kFakeHostEndian);',
        );
      }
      buffer.writeln('  }');
    }
    buffer.writeln('  data.setUint64(0, mask, _kFakeHostEndian);');
    buffer.writeln('  return data;');
    buffer.writeln('}');
    buffer.writeln();
  }

  return buffer.toString();
}

/// Result of parsing `dart:ui` style classes and enum/extension-type metadata.
class ParsedStyleBundle {
  /// Creates a [ParsedStyleBundle].
  ParsedStyleBundle({required this.specs, required this.enums});

  /// The ordered list of style class layout specifications.
  final List<StyleClassSpec> specs;

  /// All closed `enum` declarations discovered in `dart:ui`.
  final Map<String, List<String>> enums;
}

/// Parses `dart:ui` starting from [uiRoot] (or extra test source) and returns
/// the computed [ParsedStyleBundle].
ParsedStyleBundle parseAndBuildSpecs({
  required String uiRoot,
  List<String> targetClasses = const <String>['StrutStyle', 'TextStyle', 'ParagraphStyle'],
  String? extraDartSourceForTest,
}) {
  final featureSet = FeatureSet.latestLanguageVersion();
  final ParseStringResult uiResult = parseFile(path: '$uiRoot/ui.dart', featureSet: featureSet);

  final units = <CompilationUnit>[uiResult.unit];
  for (final PartDirective part in uiResult.unit.directives.whereType<PartDirective>()) {
    final String partPath = part.uri.stringValue!;
    final ParseStringResult partResult = parseFile(
      path: '$uiRoot/$partPath',
      featureSet: featureSet,
    );
    units.add(partResult.unit);
  }

  if (extraDartSourceForTest != null) {
    units.add(parseString(content: extraDartSourceForTest, featureSet: featureSet).unit);
  }

  // Pass 1: Collect all closed `enum` types, `static const` fields, and `@_CppType`
  // extension types across `dart:ui`.
  final metadataVisitor = _MetadataCollectorVisitor();
  for (final unit in units) {
    for (final CompilationUnitMember member in unit.declarations) {
      member.accept(metadataVisitor);
    }
  }

  // Pass 2: Visit style classes and validate all field types.
  final styleVisitor = _StyleClassVisitor(
    targetClasses: targetClasses.toSet(),
    metadata: metadataVisitor,
  );
  for (final unit in units) {
    for (final CompilationUnitMember member in unit.declarations) {
      member.accept(styleVisitor);
    }
  }

  final List<StyleClassSpec> specs = targetClasses
      .where(styleVisitor.extractedClasses.containsKey)
      .map((String cls) => computeOptimalLayout(cls, styleVisitor.extractedClasses[cls]!))
      .toList();

  return ParsedStyleBundle(specs: specs, enums: metadataVisitor.enums);
}

void _runSelfTest(String uiRoot) {
  // 1. Verify existing StrutStyle, TextStyle, and ParagraphStyle succeed via extension types.
  final ParsedStyleBundle bundle = parseAndBuildSpecs(uiRoot: uiRoot);
  assert(bundle.specs.length == 3, 'Expected 3 style classes, got ${bundle.specs.length}');

  // Verify @_Default annotations were resolved from Dart AST constants.
  final StyleClassSpec textStyle = bundle.specs.firstWhere(
    (StyleClassSpec s) => s.className == 'TextStyle',
  );
  final StyleField colorField = textStyle.fields.firstWhere((StyleField f) => f.name == 'color');
  assert(colorField.cppDefaultInitializer == '0xFFFFFFFF');
  assert(colorField.spec.dartValueExpr == '_ColorFfiEncoder({name}).encode()');

  final StyleField weightField = textStyle.fields.firstWhere(
    (StyleField f) => f.name == 'fontWeight',
  );
  assert(weightField.cppDefaultInitializer == '400');

  // 2. Verify that adding a custom non-enum class field without an extension type throws.
  var threwOnCustomClass = false;
  try {
    parseAndBuildSpecs(
      uiRoot: uiRoot,
      targetClasses: const <String>['BadTextStyle'],
      extraDartSourceForTest: '''
class CustomOpenClass {
  final int x;
  CustomOpenClass(this.x);
}
class BadTextStyle {
  BadTextStyle({this.fontSize, this.customField});
  final double? fontSize;
  final CustomOpenClass? customField;
}
''',
    );
  } on UnsupportedError catch (e) {
    threwOnCustomClass = true;
    stderr.writeln('[PASS] Caught expected error for unmapped custom class field:\n  $e');
  }
  if (!threwOnCustomClass) {
    throw StateError('Expected UnsupportedError for CustomOpenClass field!');
  }

  // 3. Verify that adding a closed `enum` type is automatically accepted and packed.
  final ParsedStyleBundle enumBundle = parseAndBuildSpecs(
    uiRoot: uiRoot,
    targetClasses: const <String>['ExtendedTextStyle'],
    extraDartSourceForTest: '''
enum TextHyphenation { none, normal, full }
class ExtendedTextStyle {
  ExtendedTextStyle({
    this.fontSize,
    @_Default(TextHyphenation.normal) this.hyphenation,
  });
  final double? fontSize;
  final TextHyphenation? hyphenation;
}
''',
  );
  assert(enumBundle.specs.single.fields.length == 2);
  assert(enumBundle.specs.single.fields[1].cppDefaultInitializer == 'TextHyphenation::normal');
  stderr.writeln(
    '[PASS] Closed enum `TextHyphenation` automatically accepted with default '
    '`${enumBundle.specs.single.fields[1].cppDefaultInitializer}` at offset '
    '${enumBundle.specs.single.fields[1].byteOffset}.',
  );
}

void main(List<String> args) {
  final bool selfTest = args.contains('--self-test');
  final List<String> positional = args.where((String a) => !a.startsWith('--')).toList();
  final String uiRoot = positional.isNotEmpty
      ? positional[0]
      : '${Directory.current.path}/engine/src/flutter/lib/ui';

  if (selfTest) {
    _runSelfTest(uiRoot);
    return;
  }

  final ParsedStyleBundle bundle = parseAndBuildSpecs(uiRoot: uiRoot);
  stdout.writeln(generateCppHeader(bundle.specs, bundle.enums));
  stdout.writeln(generateDartCode(bundle.specs));
}
