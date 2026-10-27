// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonEncode;

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
  const ExtensionCCompilerConfig({
    required this.ar,
    required this.cc,
    required this.ld,
    this.envScript,
    this.envScriptArgs,
  });

  /// Deserializes an [ExtensionCCompilerConfig] from a JSON-serializable map.
  factory ExtensionCCompilerConfig.fromJson(Map<String, Object?> json) {
    final String? rawEnvScript = json.nullableField<String>(envScriptKey);
    return ExtensionCCompilerConfig(
      ar: _parseAbsoluteUri(json.requiredField<String>(arKey), arKey),
      cc: _parseAbsoluteUri(json.requiredField<String>(ccKey), ccKey),
      ld: _parseAbsoluteUri(json.requiredField<String>(ldKey), ldKey),
      envScript: rawEnvScript != null ? _parseAbsoluteUri(rawEnvScript, envScriptKey) : null,
      envScriptArgs: json[envScriptArgsKey] != null
          ? json.stringIterable(envScriptArgsKey).toList()
          : null,
    );
  }

  /// Map key for [ar].
  static const String arKey = 'ar';

  /// Map key for [cc].
  static const String ccKey = 'cc';

  /// Map key for [envScriptArgs].
  static const String envScriptArgsKey = 'envScriptArgs';

  /// Map key for [envScript].
  static const String envScriptKey = 'envScript';

  /// Map key for [ld].
  static const String ldKey = 'ld';

  /// Absolute URI to the archiver (`ar`) executable.
  final Uri ar;

  /// Absolute URI to the C compiler (`cc`) executable.
  final Uri cc;

  /// Absolute URI to the linker (`ld`) executable.
  final Uri ld;

  /// Optional absolute `file:` URI to a Windows developer command prompt
  /// environment setup script for the compiler toolchain.
  final Uri? envScript;

  /// Optional arguments passed to [envScript] on Windows.
  final List<String>? envScriptArgs;

  static Uri _parseAbsoluteUri(String rawValue, String fieldName) {
    if (rawValue.isEmpty) {
      throw FormatException(
        'Missing or invalid "$fieldName" for ExtensionCCompilerConfig: $rawValue',
      );
    }
    final Uri? uri = Uri.tryParse(rawValue);
    if (uri == null || !uri.isScheme('file') || !uri.hasAbsolutePath) {
      throw FormatException('"$fieldName" must be an absolute file:// URI: $rawValue');
    }
    return uri;
  }

  /// Serializes the compiler configuration to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    arKey: ar.toString(),
    ccKey: cc.toString(),
    ldKey: ld.toString(),
    if (envScript != null) envScriptKey: envScript.toString(),
    envScriptArgsKey: ?envScriptArgs,
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

/// Configuration for running Dart build and link hooks (`native_assets`) for an
/// extension build target.
///
/// Allows custom extension targets whose `targetPlatform` is not a built-in
/// Flutter `TargetPlatform` (or that use a custom cross-compiler toolchain) to
/// specify the target OS, architecture, and C compiler configuration passed to
/// `HookConfig` when building `CodeAsset`s and `DataAsset`s.
///
/// Both built-in operating systems (such as `'linux'` for Linux-based custom
/// embedders) and custom operating system identifiers are supported via
/// `package:code_assets`'s `OS.fromString` and `Architecture.fromString`.
@immutable
class ExtensionNativeAssetsConfig {
  const ExtensionNativeAssetsConfig({
    required this.targetArchitecture,
    required this.targetOs,
    this.cCompilerConfig,
  });

  /// Deserializes an [ExtensionNativeAssetsConfig] from a JSON-serializable map.
  factory ExtensionNativeAssetsConfig.fromJson(Map<String, Object?> json) {
    final String targetArchitecture = json.requiredField<String>(targetArchitectureKey);
    if (targetArchitecture.isEmpty) {
      throw const FormatException(
        'Missing or invalid "$targetArchitectureKey" for ExtensionNativeAssetsConfig.',
      );
    }
    final String targetOs = json.requiredField<String>(targetOsKey);
    if (targetOs.isEmpty) {
      throw const FormatException(
        'Missing or invalid "$targetOsKey" for ExtensionNativeAssetsConfig.',
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

  /// Map key for [cCompilerConfig].
  static const String cCompilerConfigKey = 'cCompilerConfig';

  /// Map key for [targetArchitecture].
  static const String targetArchitectureKey = 'targetArchitecture';

  /// Map key for [targetOs].
  static const String targetOsKey = 'targetOs';

  /// Environment define key (`-dExtensionTargetOs=...`) for [targetOs].
  static const String targetOsDefine = 'ExtensionTargetOs';

  /// Environment define key (`-dExtensionTargetArch=...`) for [targetArchitecture].
  static const String targetArchDefine = 'ExtensionTargetArch';

  /// Environment define key (`-dExtensionCCompilerCc=...`) for [ExtensionCCompilerConfig.cc].
  static const String cCompilerCcDefine = 'ExtensionCCompilerCc';

  /// Environment define key (`-dExtensionCCompilerAr=...`) for [ExtensionCCompilerConfig.ar].
  static const String cCompilerArDefine = 'ExtensionCCompilerAr';

  /// Environment define key (`-dExtensionCCompilerLd=...`) for [ExtensionCCompilerConfig.ld].
  static const String cCompilerLdDefine = 'ExtensionCCompilerLd';

  /// Environment define key (`-dExtensionCCompilerEnvScript=...`) for [ExtensionCCompilerConfig.envScript].
  static const String cCompilerEnvScriptDefine = 'ExtensionCCompilerEnvScript';

  /// Environment define key (`-dExtensionCCompilerEnvScriptArgs=...`) for [ExtensionCCompilerConfig.envScriptArgs].
  static const String cCompilerEnvScriptArgsDefine = 'ExtensionCCompilerEnvScriptArgs';

  /// The target operating system for `CodeAsset` hooks (e.g. `'linux'`,
  /// `'macos'`, `'windows'`, `'android'`, `'ios'`, or a custom OS identifier).
  final String targetOs;

  /// The target CPU architecture for `CodeAsset` hooks (e.g. `'x64'`,
  /// `'arm64'`, `'arm'`, `'ia32'`, `'riscv64'`).
  final String targetArchitecture;

  /// Optional C compiler toolchain configuration for `CodeAsset` hooks.
  final ExtensionCCompilerConfig? cCompilerConfig;

  /// Converts this configuration into `flutter assemble` environment defines
  /// (`-d<Key>=<Value>`) consumed by `BuildHooks`, `LinkHooks`,
  /// `InstallCodeAssets`, and `KernelSnapshot`.
  Map<String, String> toEnvironmentDefines() {
    final ExtensionCCompilerConfig? compiler = cCompilerConfig;
    return <String, String>{
      targetOsDefine: targetOs,
      targetArchDefine: targetArchitecture,
      if (compiler != null) ...<String, String>{
        cCompilerCcDefine: compiler.cc.toFilePath(),
        cCompilerArDefine: compiler.ar.toFilePath(),
        cCompilerLdDefine: compiler.ld.toFilePath(),
        if (compiler.envScript case final Uri envScript)
          cCompilerEnvScriptDefine: envScript.toFilePath(),
        if (compiler.envScriptArgs case final List<String> args when args.isNotEmpty)
          cCompilerEnvScriptArgsDefine: jsonEncode(args),
      },
    };
  }

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
