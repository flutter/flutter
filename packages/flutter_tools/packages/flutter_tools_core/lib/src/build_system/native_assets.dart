// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Configuration for running Dart build and link hooks (`native_assets`) for an
/// extension build target.
///
/// Allows custom extension targets whose `targetPlatform` is not a built-in
/// Flutter `TargetPlatform` (or that use a custom cross-compiler toolchain) to
/// specify the target OS, architecture, and C compiler configuration passed to
/// `HookConfig` when building `CodeAsset`s and `DataAsset`s.
@immutable
class ExtensionNativeAssetsConfig {
  const ExtensionNativeAssetsConfig({
    required this.targetArchitecture,
    required this.targetOs,
    this.ar,
    this.cc,
    this.envScript,
    this.envScriptArgs,
    this.ld,
  });

  /// Deserializes an [ExtensionNativeAssetsConfig] from a JSON-serializable map.
  factory ExtensionNativeAssetsConfig.fromJson(Map<String, Object?> json) {
    return ExtensionNativeAssetsConfig(
      targetArchitecture: switch (json[targetArchitectureKey]) {
        final String value => value,
        _ => throw ArgumentError(
          'Missing or invalid "$targetArchitectureKey" for ExtensionNativeAssetsConfig.',
        ),
      },
      targetOs: switch (json[targetOsKey]) {
        final String value => value,
        _ => throw ArgumentError(
          'Missing or invalid "$targetOsKey" for ExtensionNativeAssetsConfig.',
        ),
      },
      ar: switch (json[arKey]) {
        final String value => value,
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$arKey": $invalid'),
      },
      cc: switch (json[ccKey]) {
        final String value => value,
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$ccKey": $invalid'),
      },
      envScript: switch (json[envScriptKey]) {
        final String value => value,
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
      ld: switch (json[ldKey]) {
        final String value => value,
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$ldKey": $invalid'),
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

  /// Map key for [targetArchitecture].
  static const String targetArchitectureKey = 'targetArchitecture';

  /// Map key for [targetOs].
  static const String targetOsKey = 'targetOs';

  /// The target operating system for `CodeAsset` hooks (e.g. `'linux'`,
  /// `'macos'`, `'windows'`, `'android'`, `'ios'`).
  final String targetOs;

  /// The target CPU architecture for `CodeAsset` hooks (e.g. `'x64'`,
  /// `'arm64'`, `'arm'`, `'ia32'`, `'riscv64'`).
  final String targetArchitecture;

  /// Optional path to the C compiler (`cc`) executable.
  final String? cc;

  /// Optional path to the archiver (`ar`) executable.
  final String? ar;

  /// Optional path to the linker (`ld`) executable.
  final String? ld;

  /// Optional path to an environment setup script for the compiler toolchain.
  final String? envScript;

  /// Optional arguments passed to [envScript].
  final List<String>? envScriptArgs;

  /// Serializes the configuration to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    targetOsKey: targetOs,
    targetArchitectureKey: targetArchitecture,
    ccKey: ?cc,
    arKey: ?ar,
    ldKey: ?ld,
    envScriptKey: ?envScript,
    envScriptArgsKey: ?envScriptArgs,
  };

  @override
  String toString() =>
      'ExtensionNativeAssetsConfig(targetOs: $targetOs, '
      'targetArchitecture: $targetArchitecture, cc: $cc, ar: $ar, ld: $ld, '
      'envScript: $envScript, envScriptArgs: $envScriptArgs)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionNativeAssetsConfig &&
            other.targetOs == targetOs &&
            other.targetArchitecture == targetArchitecture &&
            other.cc == cc &&
            other.ar == ar &&
            other.ld == ld &&
            other.envScript == envScript &&
            _nullableListEquals(other.envScriptArgs, envScriptArgs));
  }

  @override
  int get hashCode => Object.hash(
    targetOs,
    targetArchitecture,
    cc,
    ar,
    ld,
    envScript,
    envScriptArgs == null ? null : Object.hashAll(envScriptArgs!),
  );
}

bool _nullableListEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
