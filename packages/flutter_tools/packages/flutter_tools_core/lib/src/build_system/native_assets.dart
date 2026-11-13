// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../json_utils.dart';

/// C compiler toolchain configuration for running Dart build and link hooks
/// (`native_assets`) on an extension build target.
///
/// Groups the archiver ([ar]), C compiler ([cc]), and linker ([ld]) executable
/// URIs together so partial compiler configurations cannot be constructed.
@immutable
class ExtensionCCompilerConfig {
  ExtensionCCompilerConfig({
    required this.ar,
    required this.cc,
    required this.ld,
    this.envScript,
    this.envScriptArgs = const <String>[],
  }) : assert(ar.isValidFileUri, 'ar must be an absolute file: URI: $ar'),
       assert(cc.isValidFileUri, 'cc must be an absolute file: URI: $cc'),
       assert(ld.isValidFileUri, 'ld must be an absolute file: URI: $ld'),
       assert(
         envScript == null || envScript.isValidFileUri,
         'envScript must be an absolute file: URI: $envScript',
       ),
       assert(
         envScript != null || envScriptArgs.isEmpty,
         'Cannot provide envScriptArgs without envScript.',
       );

  /// Deserializes an [ExtensionCCompilerConfig] from a JSON-serializable map.
  factory ExtensionCCompilerConfig.fromJson(Map<String, Object?> json) {
    final String? rawEnvScript = json.nullableField<String>(envScriptKey);
    final List<String> envScriptArgs = json.stringIterable(envScriptArgsKey).toList();
    if (rawEnvScript == null && envScriptArgs.isNotEmpty) {
      throw const FormatException(
        'Cannot specify "$envScriptArgsKey" without "$envScriptKey" in ExtensionCCompilerConfig.',
      );
    }
    return ExtensionCCompilerConfig(
      ar: _parseFileUri(json.requiredField<String>(arKey), arKey),
      cc: _parseFileUri(json.requiredField<String>(ccKey), ccKey),
      ld: _parseFileUri(json.requiredField<String>(ldKey), ldKey),
      envScript: rawEnvScript != null ? _parseFileUri(rawEnvScript, envScriptKey) : null,
      envScriptArgs: envScriptArgs,
    );
  }

  /// Map key for [ar].
  @visibleForTesting
  static const String arKey = 'ar';

  /// Map key for [cc].
  @visibleForTesting
  static const String ccKey = 'cc';

  /// Map key for [envScriptArgs].
  @visibleForTesting
  static const String envScriptArgsKey = 'envScriptArgs';

  /// Map key for [envScript].
  @visibleForTesting
  static const String envScriptKey = 'envScript';

  /// Map key for [ld].
  @visibleForTesting
  static const String ldKey = 'ld';

  /// Absolute `file:` URI to the archiver (`ar`) executable.
  final Uri ar;

  /// Absolute `file:` URI to the C compiler (`cc`) executable.
  final Uri cc;

  /// Absolute `file:` URI to the linker (`ld`) executable.
  final Uri ld;

  /// Optional absolute `file:` URI to a Windows developer command prompt
  /// environment setup script for the compiler toolchain.
  final Uri? envScript;

  /// Arguments passed to [envScript] on Windows.
  final List<String> envScriptArgs;

  static Uri _parseFileUri(String rawValue, String fieldName) {
    final Uri? uri = Uri.tryParse(rawValue);
    if (uri != null && uri.isValidFileUri) {
      return uri;
    }
    throw FormatException(
      'Invalid "$fieldName" in ExtensionCCompilerConfig: expected an absolute file: URI.',
    );
  }

  /// Serializes the compiler configuration to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    arKey: ar.toString(),
    ccKey: cc.toString(),
    ldKey: ld.toString(),
    if (envScript != null) envScriptKey: envScript.toString(),
    if (envScriptArgs.isNotEmpty) envScriptArgsKey: envScriptArgs,
  };

  @override
  String toString() =>
      'ExtensionCCompilerConfig(cc: $cc, ar: $ar, ld: $ld, '
      'envScript: $envScript, envScriptArgs: $envScriptArgs)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionCCompilerConfig &&
            other.ar == ar &&
            other.cc == cc &&
            other.ld == ld &&
            other.envScript == envScript &&
            const ListEquality<String>().equals(other.envScriptArgs, envScriptArgs));
  }

  @override
  int get hashCode =>
      Object.hash(ar, cc, ld, envScript, const ListEquality<String>().hash(envScriptArgs));
}

/// Configuration for running Dart build and link hooks (`package:code_assets`)
/// for an extension build target.
@immutable
class ExtensionNativeAssetsConfig {
  ExtensionNativeAssetsConfig({
    required this.targetArchitecture,
    required this.targetOs,
    this.cCompilerConfig,
  }) : assert(
         isValidTargetArchitecture(targetArchitecture),
         'Invalid targetArchitecture "$targetArchitecture": $_invalidTargetArchitectureMessage',
       ),
       assert(isValidTargetOs(targetOs), 'Invalid targetOs "$targetOs": $_invalidTargetOsMessage');

  /// Deserializes an [ExtensionNativeAssetsConfig] from a JSON-serializable map.
  factory ExtensionNativeAssetsConfig.fromJson(Map<String, Object?> json) {
    final String targetArchitecture = json.requiredField<String>(targetArchitectureKey);
    if (!isValidTargetArchitecture(targetArchitecture)) {
      throw FormatException(
        'Missing or invalid "$targetArchitectureKey" ("$targetArchitecture") for '
        'ExtensionNativeAssetsConfig: $_invalidTargetArchitectureMessage',
      );
    }
    final String targetOs = json.requiredField<String>(targetOsKey);
    if (!isValidTargetOs(targetOs)) {
      throw FormatException(
        'Missing or invalid "$targetOsKey" ("$targetOs") for '
        'ExtensionNativeAssetsConfig: $_invalidTargetOsMessage',
      );
    }
    final Map<String, Object?>? rawCompilerConfig = json.nullableField<Map<String, Object?>>(
      cCompilerConfigKey,
    );
    return ExtensionNativeAssetsConfig(
      targetArchitecture: targetArchitecture,
      targetOs: targetOs,
      cCompilerConfig: rawCompilerConfig != null
          ? ExtensionCCompilerConfig.fromJson(rawCompilerConfig)
          : null,
    );
  }

  // Matches package:code_assets's known OS.values names.
  static const _supportedTargetOperatingSystems = <String>{
    'android',
    'fuchsia',
    'ios',
    'linux',
    'macos',
    'windows',
  };

  // Matches package:code_assets's known Architecture.values names.
  static const _supportedTargetArchitectures = <String>{
    'arm',
    'arm64',
    'arm64e',
    'ia32',
    'riscv32',
    'riscv64',
    'x64',
  };

  static const String _invalidTargetOsMessage =
      'Supported target operating systems are: android, fuchsia, ios, linux, macos, windows.';
  static const String _invalidTargetArchitectureMessage =
      'Supported target architectures are: arm, arm64, arm64e, ia32, riscv32, riscv64, x64.';

  /// Returns whether [value] is a supported `package:code_assets` target OS
  /// (`android`, `fuchsia`, `ios`, `linux`, `macos`, or `windows`).
  static bool isValidTargetOs(String value) => _supportedTargetOperatingSystems.contains(value);

  /// Returns whether [value] is a supported `package:code_assets` target CPU
  /// architecture (`arm`, `arm64`, `arm64e`, `ia32`, `riscv32`, `riscv64`, or `x64`).
  static bool isValidTargetArchitecture(String value) =>
      _supportedTargetArchitectures.contains(value);

  /// Map key for [cCompilerConfig].
  @visibleForTesting
  static const String cCompilerConfigKey = 'cCompilerConfig';

  /// Map key for [targetArchitecture].
  @visibleForTesting
  static const String targetArchitectureKey = 'targetArchitecture';

  /// Map key for [targetOs].
  @visibleForTesting
  static const String targetOsKey = 'targetOs';

  /// Target operating system for `CodeAsset` hooks (`'android'`, `'fuchsia'`,
  /// `'ios'`, `'linux'`, `'macos'`, or `'windows'`).
  ///
  /// Custom extension targets currently support `'linux'`, `'windows'`, and
  /// `'fuchsia'` directly; `'android'`, `'ios'`, and `'macos'` require platform
  /// SDK version configuration and must use built-in target platforms.
  final String targetOs;

  /// Target CPU architecture for `CodeAsset` hooks (`'arm'`, `'arm64'`,
  /// `'arm64e'`, `'ia32'`, `'riscv32'`, `'riscv64'`, or `'x64'`).
  final String targetArchitecture;

  /// Optional C compiler toolchain configuration for `CodeAsset` hooks.
  final ExtensionCCompilerConfig? cCompilerConfig;

  /// Serializes the configuration to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    targetOsKey: targetOs,
    targetArchitectureKey: targetArchitecture,
    cCompilerConfigKey: ?cCompilerConfig?.toMap(),
  };

  @override
  String toString() =>
      'ExtensionNativeAssetsConfig(targetOs: $targetOs, '
      'targetArchitecture: $targetArchitecture, '
      'cCompilerConfig: $cCompilerConfig)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionNativeAssetsConfig &&
            other.targetOs == targetOs &&
            other.targetArchitecture == targetArchitecture &&
            other.cCompilerConfig == cCompilerConfig);
  }

  @override
  int get hashCode => Object.hash(targetOs, targetArchitecture, cCompilerConfig);
}
