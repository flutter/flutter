// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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
    return ExtensionCCompilerConfig(
      ar: _parseAbsoluteUri(json[arKey], arKey),
      cc: _parseAbsoluteUri(json[ccKey], ccKey),
      ld: _parseAbsoluteUri(json[ldKey], ldKey),
      envScript: switch (json[envScriptKey]) {
        final String value => _parseAbsoluteUri(value, envScriptKey),
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$envScriptKey": $invalid'),
      },
      envScriptArgs: switch (json[envScriptArgsKey]) {
        final List<Object?> rawArgs => <String>[
          for (final Object? item in rawArgs)
            switch (item) {
              final String arg => arg,
              _ => throw ArgumentError('Invalid entry in "$envScriptArgsKey": $item'),
            },
        ],
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$envScriptArgsKey": $invalid'),
      },
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

  static Uri _parseAbsoluteUri(Object? rawValue, String fieldName) {
    if (rawValue is! String || rawValue.isEmpty) {
      throw ArgumentError(
        'Missing or invalid "$fieldName" for ExtensionCCompilerConfig: $rawValue',
      );
    }
    final Uri? uri = Uri.tryParse(rawValue);
    if (uri == null || !uri.isScheme('file') || !uri.hasAbsolutePath) {
      throw ArgumentError('"$fieldName" must be an absolute file:// URI: $rawValue');
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
/// embedders like LG webOS or Raspberry Pi) and custom operating system
/// identifiers (such as `'ohos'` for HarmonyOS or `'webos'`) are supported via
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
    return ExtensionNativeAssetsConfig(
      targetArchitecture: switch (json[targetArchitectureKey]) {
        final String value when value.isNotEmpty => value,
        _ => throw ArgumentError(
          'Missing or invalid "$targetArchitectureKey" for ExtensionNativeAssetsConfig.',
        ),
      },
      targetOs: switch (json[targetOsKey]) {
        final String value when value.isNotEmpty => value,
        _ => throw ArgumentError(
          'Missing or invalid "$targetOsKey" for ExtensionNativeAssetsConfig.',
        ),
      },
      cCompilerConfig: switch (json[cCompilerConfigKey]) {
        final Map<String, Object?> map => ExtensionCCompilerConfig.fromJson(map),
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$cCompilerConfigKey": $invalid'),
      },
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
  /// `'macos'`, `'windows'`, `'android'`, `'ios'`, or a custom OS identifier
  /// such as `'ohos'` or `'webos'`).
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
