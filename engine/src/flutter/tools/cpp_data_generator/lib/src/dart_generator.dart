// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;

import 'parser.dart';

/// Emits the `part of` Dart file containing `_Packed<Type>`,
/// `_encode<Type>Ffi`, and `_<type>ToString`.
Future<String> generateDartEncoders(
  Iterable<NativeData> definitions, {
  required String partOfFile,
  String? libraryName,
}) async {
  final String sections = <String>[
    for (final NativeData definition in definitions)
      <String>[
        _generatePackedStruct(definition),
        _generateEncoder(definition),
        _generateToString(definition),
      ].join('\n'),
  ].join('\n');

  final String partOfTarget = (libraryName != null && libraryName.isNotEmpty)
      ? libraryName
      : "'$partOfFile'";
  final unformatted =
      '''
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT EDIT BY HAND.
// ignore_for_file: unused_element

part of $partOfTarget;

$sections''';

  return _formatDart(unformatted, partOfFile: partOfFile);
}

// TODO(LongCatIsLooong): Share formatting logic with //flutter/ci/bin/format.dart.
Future<String> _formatDart(String code, {required String partOfFile}) async {
  final String flutterRoot = Engine.findWithin().flutterDir.path;
  final String dartBin = path.join(
    flutterRoot,
    'third_party',
    'dart',
    'tools',
    'sdks',
    'dart-sdk',
    'bin',
    Platform.isWindows ? 'dart.exe' : 'dart',
  );
  final Process process = await Process.start(dartBin, <String>[
    '--suppress-analytics',
    'format',
    '--stdin-name=$partOfFile',
  ], workingDirectory: flutterRoot);
  process.stdin.write(code);
  await process.stdin.close();
  final Future<String> stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final Future<String> stderrFuture = process.stderr.transform(utf8.decoder).join();
  final int exitCode = await process.exitCode;
  final String stdout = await stdoutFuture;
  final String stderr = await stderrFuture;
  if (exitCode != 0) {
    throw StateError('dart format failed (exit code $exitCode):\n$stderr');
  }
  return stdout;
}

String _generatePackedStruct(NativeData definition) {
  final String structName = definition._packedDartStructName;
  final String encodedName = definition._encodedDartTypeName;
  final String fields = <String>[
    for (final NativeDataField field in definition.packedFields) field._dartPackedFieldDeclaration,
  ].join('\n\n');
  final fieldNames = <String>[
    for (final NativeDataField field in definition.packedFields) field.dartName,
  ];
  final equalsConditions = <String>[
    'other is $structName',
    ...fieldNames.map((String name) => '$name == other.$name'),
  ];
  final String hashBody = switch (fieldNames.length) {
    1 => '  int get hashCode => ${fieldNames.single}.hashCode;',
    <= 20 => '  int get hashCode => Object.hash(${fieldNames.join(', ')});',
    _ => '  int get hashCode => Object.hashAll(<Object?>[${fieldNames.join(', ')}]);',
  };
  return '''
final class $structName extends Struct {
$fields

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return ${equalsConditions.join(' && ')};
  }

  @override
$hashBody
}

extension type const $encodedName(List<Object?> _data) implements Object {
  $structName get packed => _data[0]! as $structName;
}
''';
}

String _generateEncoder(NativeData definition) {
  final String structName = definition._packedDartStructName;
  final String encodedName = definition._encodedDartTypeName;
  final String parameters = <String>[
    for (final NativeDataField field in definition.fields) '  ${field._dartParameterDeclaration}',
  ].join('\n');
  final String encodeBlocks = <String>[
    for (final NativeDataField field in definition.fields) ?field._dartEncodeBlock,
  ].join('\n');
  final returnElements = <String>[
    'packed',
    'bytes',
    for (final NativeDataField field in definition.handleFields)
      field.resolvedType.dartEncode(field.dartName),
  ];
  final String bodyLines = <String>[
    '  final bytes = Uint8List(sizeOf<$structName>());',
    '  final $structName packed = Struct.create<$structName>(bytes);',
    if (definition.hasNullableFields) '  var mask = 0;',
    if (encodeBlocks.isNotEmpty) encodeBlocks,
    if (definition.hasNullableFields) '  packed.presentMask = mask;',
    '  return $encodedName(<Object?>[${returnElements.join(', ')}]);',
  ].join('\n');
  return '''
$encodedName _encode${definition.typeName}Ffi({
$parameters
}) {
$bodyLines
}
''';
}

String _generateToString(NativeData definition) {
  final int fieldCount = definition.fields.length;
  final bool needsPacked = definition.packedFields.isNotEmpty;
  final preambleLines = <String>[
    if (needsPacked) '  final ${definition._packedDartStructName} packed = s._encoded.packed;',
    if (definition.hasNullableFields) '  final int mask = packed.presentMask;',
  ];
  final preamble = preambleLines.isEmpty ? '' : '${preambleLines.join('\n')}\n';
  final String lowerCamelName = definition.typeName.isEmpty
      ? definition.typeName
      : '${definition.typeName[0].toLowerCase()}${definition.typeName.substring(1)}';
  final String segments = definition.fields.indexed
      .map(
        ((int, NativeDataField) entry) =>
            '      ${entry.$2._dartToStringSegment(isLast: entry.$1 + 1 == fieldCount)}',
      )
      .join('\n');
  return '''
@pragma('vm:prefer-inline')
String _${lowerCamelName}ToString(${definition.typeName} s) {
$preamble  return '${definition.typeName}('
$segments
      ')';
}
''';
}

extension on NativeData {
  String get _packedDartStructName => '_Packed$typeName';

  String get _encodedDartTypeName => '_Encoded$typeName';
}

extension on NativeDataField {
  String get _dartPackedFieldDeclaration {
    final FfiPrimitive primitive = resolvedType.primitive!;
    return '''
  @${primitive.annotation}()
  external ${primitive.dartFieldType} $dartName;''';
  }

  String get _dartParameterDeclaration =>
      'required ${parameterType!.getDisplayString()} $dartName,';

  String? get _dartEncodeBlock => switch ((isPacked, bitIndex)) {
    (true, final int bitIndex) =>
      '''
  if ($dartName != null) {
    mask |= 1 << $bitIndex;
  } else {
    $dartName = $defaultValueCode;
  }
  packed.$dartName = ${resolvedType.dartEncode(dartName)};''',
    (false, final int bitIndex) =>
      '''
  if ($dartName != null) {
    mask |= 1 << $bitIndex;
  }''',
    (true, null) => '  packed.$dartName = ${resolvedType.dartEncode(dartName)};',
    (false, null) => null,
  };

  String get _dartDecodedExpression =>
      isPacked ? resolvedType.dartDecode('packed.$dartName') : 's._$dartName';

  String _dartToStringSegment({required bool isLast}) {
    final suffix = isLast ? '' : ', ';
    return switch (bitIndex) {
      final int bitIndex =>
        "'$dartName: \${(mask & (1 << $bitIndex)) != 0 ? $_dartDecodedExpression : \"unspecified\"}$suffix'",
      null => "'$dartName: \${$_dartDecodedExpression}$suffix'",
    };
  }
}
