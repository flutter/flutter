// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;

import 'parser.dart';

/// Emits the C++ header containing `@_NativeData` FFI structs.
Future<String> generateCppHeader(
  Iterable<NativeData> definitions, {
  required String headerGuard,
}) async {
  if (definitions.isEmpty) {
    throw ArgumentError.value(definitions, 'definitions', 'Must not be empty.');
  }
  final String namespace = definitions.first.symbol.namespace;
  for (final definition in definitions) {
    if (definition.symbol.namespace != namespace) {
      throw UnsupportedError(
        'All @_NativeData definitions in a header must share the same namespace '
        '($namespace vs ${definition.symbol.namespace}).',
      );
    }
  }
  final String structs = <String>[
    for (final NativeData definition in definitions) _generateCppStruct(definition),
  ].join('\n');
  final String converters = <String>[
    for (final NativeData definition in definitions) _generateTonicConverter(definition),
  ].join('\n');

  final unformatted =
      '''
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT EDIT BY HAND.

#ifndef $headerGuard
#define $headerGuard

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <type_traits>

#include "third_party/tonic/converter/dart_converter.h"

namespace $namespace {

$structs
}  // namespace $namespace

namespace tonic {

$converters
}  // namespace tonic

#endif  // $headerGuard
''';

  return _formatCpp(unformatted);
}

// TODO(LongCatIsLooong): Share formatting logic with //flutter/ci/bin/format.dart.
Future<String> _formatCpp(String code) async {
  final String flutterRoot = Engine.findWithin().flutterDir.path;
  final String clangOs = switch (Abi.current()) {
    Abi.linuxArm64 => 'linux-arm64',
    Abi.linuxX64 => 'linux-x64',
    Abi.macosArm64 => 'mac-arm64',
    Abi.macosX64 => 'mac-x64',
    Abi.windowsX64 => 'windows-x64',
    (_) => throw UnsupportedError(
      "Unknown operating system: don't know how to run clang-format here.",
    ),
  };
  final String clangFormat = path.join(
    flutterRoot,
    'buildtools',
    clangOs,
    'clang',
    'bin',
    'clang-format',
  );
  final Process process = await Process.start(clangFormat, <String>[
    '--style=file',
  ], workingDirectory: flutterRoot);
  process.stdin.write(code);
  await process.stdin.close();
  final Future<String> stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final Future<String> stderrFuture = process.stderr.transform(utf8.decoder).join();
  final int exitCode = await process.exitCode;
  final String stdout = await stdoutFuture;
  final String stderr = await stderrFuture;
  if (exitCode != 0) {
    throw StateError('clang-format failed (exit code $exitCode):\n$stderr');
  }
  return stdout;
}

String _generateCppStruct(NativeData definition) {
  final String structName = definition.symbol.name;
  final String fields = <String>[
    for (final NativeDataField field in definition.packedFields) '  ${field._cppFieldDeclaration}',
    for (final NativeDataField field in definition.handleFields) '  ${field._cppFieldDeclaration}',
  ].join('\n');
  final String presenceGetters = <String>[
    for (final NativeDataField field in definition.fields)
      if (field._cppPresenceGetter case final String getter) '  $getter',
  ].join('\n');
  final presenceBlock = presenceGetters.isEmpty ? '' : '\n$presenceGetters\n';

  return '''
class $structName {
 public:
$fields
$presenceBlock};
static_assert(std::is_standard_layout_v<$structName>);
static_assert(std::is_trivially_copyable_v<$structName>);
''';
}

String _generateTonicConverter(NativeData definition) {
  final String cppType = definition.symbol.qualifiedName;
  final String lastPackedMember = definition.packedFields.last._cppName;
  final List<NativeDataField> handleFields = definition.handleFields.toList();
  final int handleCount = handleFields.length;
  final listGetBlock = handleCount == 0
      ? '    Dart_Handle bytes_handle = Dart_ListGetAt(handle, 1);'
      : '''
    Dart_Handle handles[${handleCount + 1}];
    Dart_ListGetRange(handle, 1, ${handleCount + 1}, handles);
    Dart_Handle bytes_handle = handles[0];''';
  final String handleAssignments = <String>[
    for (final (int index, NativeDataField field) in handleFields.indexed)
      '    result.${field._cppName} = handles[${index + 1}];',
  ].join('\n');
  final handleAssignmentBlock = handleAssignments.isEmpty ? '' : '$handleAssignments\n';

  return '''
template <>
struct DartConverter<$cppType> {
  using FfiType = Dart_Handle;
  static constexpr const char* kFfiRepresentation = "Handle";
  static constexpr const char* kDartRepresentation = "Object";
  static constexpr bool kAllowedInLeafCall = false;

  static $cppType FromDart(Dart_Handle handle) {
    if (Dart_IsNull(handle)) {
      return {};
    }
    $cppType result;
$listGetBlock
    Dart_TypedData_Type type;
    void* data = nullptr;
    intptr_t length = 0;
    Dart_TypedDataAcquireData(bytes_handle, &type, &data, &length);
    std::memcpy(&result, data,
                offsetof($cppType, $lastPackedMember) + sizeof(result.$lastPackedMember));
    Dart_TypedDataReleaseData(bytes_handle);
$handleAssignmentBlock    return result;
  }

  static $cppType FromFfi(FfiType val) { return FromDart(val); }
  static const char* GetFfiRepresentation() { return kFfiRepresentation; }
  static const char* GetDartRepresentation() { return kDartRepresentation; }
  static bool AllowedInLeafCall() { return kAllowedInLeafCall; }
};
''';
}

extension on NativeDataField {
  // Dart identifiers are strictly ASCII (`[a-zA-Z_$][a-zA-Z0-9_$]*`), so
  // operating on UTF-16 code units and `[A-Z]` is safe.
  static final RegExp _upperCaseAsciiLetter = RegExp(r'[A-Z]');

  String get _cppName => dartName.replaceAllMapped(
    _upperCaseAsciiLetter,
    (Match match) => '${match.start > 0 ? '_' : ''}${match[0]!.toLowerCase()}',
  );

  String get _cppType => resolvedType.primitive?.cppType ?? 'Dart_Handle';

  String get _cppFieldDeclaration => '$_cppType $_cppName;';

  String? get _cppPresenceGetter => switch (bitIndex) {
    final int bitIndex =>
      'bool has_$_cppName() const { return (present_mask & (${bitIndex >= 32 ? '1ull' : '1u'} << $bitIndex)) != 0; }',
    null => null,
  };
}
