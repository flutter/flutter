// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

typedef _InvocationExpressionString = String Function(String);

/// Metadata for a `dart:ffi` `SizedNativeType` primitive field in a `Struct`.
enum FfiPrimitive {
  /// A `dart:ffi` `Bool` (`bool`).
  boolean(annotation: 'Bool', dartFieldType: 'bool', cppType: 'bool', byteSize: 1),

  /// A `dart:ffi` `Int8` (`int8_t`).
  int8(annotation: 'Int8', dartFieldType: 'int', cppType: 'int8_t', byteSize: 1),

  /// A `dart:ffi` `Uint8` (`uint8_t`).
  uint8(annotation: 'Uint8', dartFieldType: 'int', cppType: 'uint8_t', byteSize: 1),

  /// A `dart:ffi` `Int16` (`int16_t`).
  int16(annotation: 'Int16', dartFieldType: 'int', cppType: 'int16_t', byteSize: 2),

  /// A `dart:ffi` `Uint16` (`uint16_t`).
  uint16(annotation: 'Uint16', dartFieldType: 'int', cppType: 'uint16_t', byteSize: 2),

  /// A `dart:ffi` `Int32` (`int32_t`).
  int32(annotation: 'Int32', dartFieldType: 'int', cppType: 'int32_t', byteSize: 4),

  /// A `dart:ffi` `Uint32` (`uint32_t`).
  uint32(annotation: 'Uint32', dartFieldType: 'int', cppType: 'uint32_t', byteSize: 4),

  /// A `dart:ffi` `Int64` (`int64_t`).
  int64(annotation: 'Int64', dartFieldType: 'int', cppType: 'int64_t', byteSize: 8),

  /// A `dart:ffi` `Uint64` (`uint64_t`).
  uint64(annotation: 'Uint64', dartFieldType: 'int', cppType: 'uint64_t', byteSize: 8),

  /// A `dart:ffi` `Float` (`float`).
  float(annotation: 'Float', dartFieldType: 'double', cppType: 'float', byteSize: 4),

  /// A `dart:ffi` `Double` (`double`).
  doublePrecision(annotation: 'Double', dartFieldType: 'double', cppType: 'double', byteSize: 8);

  const FfiPrimitive({
    required this.annotation,
    required this.dartFieldType,
    required this.cppType,
    required this.byteSize,
  });

  /// The `dart:ffi` annotation class name (e.g., `'Uint32'`, `'Double'`).
  final String annotation;

  /// The Dart field type on a `dart:ffi` `Struct` (`'bool'`, `'int'`, or `'double'`).
  final String dartFieldType;

  /// The C++ primitive type name (e.g., `'uint32_t'`, `'double'`).
  final String cppType;

  /// The size of this primitive in bytes.
  final int byteSize;

  /// Looks up the [FfiPrimitive] with the given [annotation] name, or `null` if none matches.
  static FfiPrimitive? tryParse(String annotation) =>
      values.where((FfiPrimitive value) => value.annotation == annotation).firstOrNull;
}

/// A qualified C++ symbol of the form `namespace::name` (e.g., `flutter::TextStyle`).
extension type const CppSymbol._(({String namespace, String name}) _parts) {
  /// Creates a [CppSymbol] with the given [namespace] and [name].
  const CppSymbol({required String namespace, required String name})
    : _parts = (namespace: namespace, name: name);

  /// Parses a qualified C++ symbol of the form `namespace::name`.
  factory CppSymbol.parse(String raw) {
    final int separator = raw.lastIndexOf('::');
    assert(
      separator > 0 && separator + 2 < raw.length,
      'Invalid C++ symbol `$raw`: expected `namespace::ClassName`.',
    );
    return CppSymbol(namespace: raw.substring(0, separator), name: raw.substring(separator + 2));
  }

  /// The C++ namespace (e.g., `'flutter'` or `'flutter::txt'`).
  String get namespace => _parts.namespace;

  /// The unqualified C++ struct/class name (e.g., `'TextStyle'`).
  String get name => _parts.name;

  /// The fully-qualified C++ symbol (e.g., `'flutter::TextStyle'`).
  String get qualifiedName => '$namespace::$name';
}

String _identity(String expression) => expression;

/// Resolved type mapping for a constructor parameter.
final class ResolvedType {
  /// Creates a [ResolvedType] with the given encode/decode callbacks and optional [primitive].
  const ResolvedType({
    this.dartType,
    this.dartEncode = _identity,
    this.dartDecode = _identity,
    this.primitive,
  });

  /// Parses a [ResolvedType] from the resolved analyzer types of a parameter.
  factory ResolvedType.parse({
    required InterfaceType extensionType,
    required DartType nativeType,
    required DartType dartType,
  }) {
    final String extensionTypeName = extensionType.element.name!;
    // Enums are special since we know how to encode them efficiently at compile time.
    if (dartType.element case final EnumElement enumElement) {
      assert(
        extensionTypeName == '_NativeEnum' &&
            extensionType.element.getMethod('encode') == null &&
            extensionType.element.getMethod('decode') == null,
        'Enum parameter ${dartType.getDisplayString()} must use _NativeEnum without custom encode/decode, got $extensionTypeName.',
      );
      return ResolvedType.fromEnum(enumElement);
    }

    final String nativeName = nativeType.element!.name!;

    final FfiPrimitive? primitive = FfiPrimitive.tryParse(nativeName);
    final isNullable = extensionType.nullabilitySuffix == NullabilitySuffix.question;
    final _InvocationExpressionString? suppliedEncode =
        extensionType.element.getMethod('encode') != null
        ? (primitive == null && isNullable
              ? (String expression) => '$expression?.encode()'
              : (String expression) => '$expression.encode()')
        : null;
    final _InvocationExpressionString? suppliedDecode =
        extensionType.element.getMethod('decode') != null
        ? (String expression) => '$extensionTypeName.decode($expression)'
        : null;
    assert(
      primitive == null || ((suppliedEncode == null) == (suppliedDecode == null)),
      "Primitive $extensionTypeName's must define a decode() method if and only if it defines an encode method.",
    );

    String defaultEncoder(String expression) => '$expression.value';
    final _InvocationExpressionString encode =
        suppliedEncode ?? (primitive != null ? defaultEncoder : _identity);
    // Non-primitive types typically don't need a decoder because they are stored.
    final _InvocationExpressionString decode = suppliedDecode ?? _identity;

    return ResolvedType(
      dartType: dartType,
      primitive: primitive,
      dartEncode: encode,
      dartDecode: decode,
    );
  }

  /// Creates a [ResolvedType] for a Dart enum backed by an unsigned integer FFI field.
  factory ResolvedType.fromEnum(EnumElement enumElement) {
    final int caseCount = enumElement.constants.length;
    final String enumName = enumElement.name!;
    final FfiPrimitive enumPrimitive = switch (caseCount) {
      <= 0xFF => .uint8,
      <= 0xFFFF => .uint16,
      _ => .uint32,
    };
    return ResolvedType(
      dartType: enumElement.thisType,
      primitive: enumPrimitive,
      dartEncode: (String expression) => '$expression.value.index',
      dartDecode: (String raw) => '$enumName.values[$raw]',
    );
  }

  /// The unwrapped Dart value type (e.g., `Color`, `double`, or `List<String>`),
  /// or `null` for synthesized fields like [NativeDataField._presentMask].
  final DartType? dartType;

  /// The underlying FFI primitive type, or `null` if passed as a `Dart_Handle`.
  final FfiPrimitive? primitive;

  /// Formats a Dart expression that encodes a wrapper value into its FFI representation.
  final String Function(String expression) dartEncode;

  /// Formats a Dart expression that decodes an FFI representation back into its Dart value.
  final String Function(String expression) dartDecode;

  /// Whether this type is packed into the `dart:ffi` `Struct` rather than stored as a handle.
  bool get isPrimitive => primitive != null;
}

/// Represents a single field on a `@_NativeData` type.
///
/// For example, given the `@_NativeData` constructor and field declarations:
/// ```dart
/// class TextStyle {
///   @_NativeData(symbol: 'flutter::TextStyle')
///   TextStyle._({
///     _NativeColor? decorationColor = const .new(.new(0x00000000)),
///     this._fontFamilyFallback,
///   });
///
///   final _NativeHandle<List<String>>? _fontFamilyFallback;
/// }
/// ```
final class NativeDataField {
  /// Creates a [NativeDataField].
  const NativeDataField({
    required this.dartName,
    required this.parameterType,
    required this.resolvedType,
    required this.bitIndex,
    required this.defaultValueCode,
  });

  /// Parses a [NativeDataField] from a constructor [parameter].
  factory NativeDataField.parse(FormalParameterElement parameter, {required int? bitIndex}) {
    final String rawName = parameter.name ?? '';
    final String fieldName = rawName.startsWith('_') ? rawName.substring(1) : rawName;
    assert(
      parameter.type is InterfaceType,
      'Parameter $fieldName must be a `_NativeType` extension type.',
    );
    final parameterType = parameter.type as InterfaceType;

    final InterfaceType? baseExtensionType = parameterType.element.name == '_NativeType'
        ? parameterType
        : parameterType.allSupertypes
              .where((InterfaceType supertype) => supertype.element.name == '_NativeType')
              .firstOrNull;
    assert(baseExtensionType != null, 'Parameter $fieldName must use a _NativeType subtype.');

    final [DartType dartType, DartType nativeType] = baseExtensionType!.typeArguments;

    final resolved = ResolvedType.parse(
      extensionType: parameterType,
      nativeType: nativeType,
      dartType: dartType,
    );

    final isNullable = bitIndex != null;
    assert(
      (resolved.isPrimitive && isNullable) == parameter.hasDefaultValue,
      'Nullable primitive parameter $fieldName must specify a default value, '
      'and non-nullable or Handle parameters must not.',
    );

    return NativeDataField(
      dartName: fieldName,
      parameterType: parameterType,
      resolvedType: resolved,
      bitIndex: bitIndex,
      defaultValueCode: parameter.defaultValueCode,
    );
  }

  /// Synthesized bitmask field tracking which nullable fields are present.
  factory NativeDataField._presentMask(int nullableFieldCount) {
    final FfiPrimitive primitive = switch (nullableFieldCount) {
      <= 8 => .uint8,
      <= 16 => .uint16,
      <= 32 => .uint32,
      <= 64 => .uint64,
      _ => throw ArgumentError.value(
        nullableFieldCount,
        'nullableFieldCount',
        'Cannot exceed 64 nullable fields.',
      ),
    };
    return NativeDataField(
      dartName: 'presentMask',
      parameterType: null,
      resolvedType: ResolvedType(primitive: primitive),
      bitIndex: null,
      defaultValueCode: null,
    );
  }

  /// The Dart field/parameter name without a leading underscore
  /// (e.g., `'decorationColor'` or `'fontFamilyFallback'`).
  final String dartName;

  /// The Dart wrapper extension type from the parameter or field
  /// declaration (e.g., `'_NativeColor?'`, `'_NativeColor'`, or
  /// `'_NativeHandle<List<String>>?'`), or `null` for synthesized fields like
  /// [NativeDataField._presentMask].
  final InterfaceType? parameterType;

  /// The resolved FFI/C++ type and Dart encode/decode expressions for the
  /// wrapper type (e.g., `uint32_t` / `FfiPrimitive.uint32` for `_NativeColor`,
  /// or `Dart_Handle` for `_NativeHandle<List<String>>`).
  final ResolvedType resolvedType;

  /// The bit position in `presentMask` for a nullable parameter, or `null` if
  /// the parameter is non-nullable and always present.
  final int? bitIndex;

  /// The Dart default value expression from the constructor parameter
  /// (e.g., `'const .new(.new(0x00000000))'`), or `null` for non-nullable or
  /// handle fields.
  final String? defaultValueCode;

  /// Whether this field is nullable and tracked by a bit in `presentMask`.
  bool get isNullable => bitIndex != null;

  /// Whether this field is packed into the `dart:ffi` `Struct`.
  bool get isPacked => resolvedType.isPrimitive;
}

/// Resolved definition for a `@_NativeData` type.
final class NativeData {
  /// Creates a [NativeData].
  NativeData({required this.typeName, required this.symbol, required this.fields})
    : assert(
        fields.where((NativeDataField field) => field.isNullable).length <= 64,
        '$typeName has more than 64 nullable fields, exceeding the 64-bit present_mask limit.',
      );

  /// Parses a [NativeData] from a `@_NativeData`-annotated [constructor].
  factory NativeData.parse(
    InterfaceElement typeElement,
    ConstructorElement constructor,
    CppSymbol symbol,
  ) {
    var nextBitIndex = 0;
    return NativeData(
      typeName: typeElement.name!,
      symbol: symbol,
      fields: <NativeDataField>[
        for (final FormalParameterElement parameter in constructor.formalParameters)
          NativeDataField.parse(
            parameter,
            bitIndex: parameter.type.nullabilitySuffix == .question ? nextBitIndex++ : null,
          ),
      ],
    );
  }

  /// Parses all `@_NativeData`-annotated types in `libraryElement`.
  static List<NativeData> parseLibrary(LibraryElement libraryElement) {
    return <NativeData>[
      for (final InterfaceElement typeElement
          in libraryElement.children.whereType<InterfaceElement>())
        for (final ConstructorElement constructor in typeElement.constructors)
          if (_extractNativeDataSymbol(constructor) case final CppSymbol symbol)
            NativeData.parse(typeElement, constructor, symbol),
    ];
  }

  static CppSymbol? _extractNativeDataSymbol(Element element) {
    final ElementAnnotation? annotation = element.metadata.annotations
        .where(
          (ElementAnnotation annotation) =>
              annotation.element?.enclosingElement?.name == '_NativeData',
        )
        .firstOrNull;
    if (annotation == null) {
      return null;
    }

    final String? symbol = annotation.computeConstantValue()?.toStringValue();
    assert(
      symbol != null,
      '@_NativeData on ${element.displayName} must specify a non-empty symbol.',
    );
    return CppSymbol.parse(symbol!);
  }

  /// The Dart type name (e.g., `'TextStyle'`).
  final String typeName;

  /// The C++ symbol generated from `@_NativeData(symbol: '...')` (e.g., `flutter::TextStyle`).
  final CppSymbol symbol;

  /// The list of fields in the `@_NativeData` constructor, in declaration order.
  final List<NativeDataField> fields;

  int get _nullableFieldCount => fields.where((NativeDataField field) => field.isNullable).length;

  /// Whether any field in [fields] is nullable and uses `presentMask`.
  bool get hasNullableFields => _nullableFieldCount > 0;

  /// The fields packed into the `dart:ffi` `Struct` (including `presentMask`
  /// when [hasNullableFields] is true), sorted by descending size/alignment to
  /// eliminate internal alignment padding.
  late final List<NativeDataField> packedFields =
      <NativeDataField>[
        for (final NativeDataField field in fields)
          if (field.isPacked) field,
        if (_nullableFieldCount > 0) NativeDataField._presentMask(_nullableFieldCount),
      ]..sort(
        (NativeDataField a, NativeDataField b) =>
            b.resolvedType.primitive!.byteSize.compareTo(a.resolvedType.primitive!.byteSize),
      );

  /// The subset of [fields] passed as `Dart_Handle`s.
  Iterable<NativeDataField> get handleFields =>
      fields.where((NativeDataField field) => !field.isPacked);
}
