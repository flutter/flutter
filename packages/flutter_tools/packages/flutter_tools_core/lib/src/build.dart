// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'build_system/native_assets.dart';

export 'build_system/native_assets.dart';

final _upperRegex = RegExp(r'[A-Z]');

/// Convert `fooBar` to `foo_bar`.
String _snakeCase(String str) {
  return str.replaceAllMapped(
    _upperRegex,
    (Match m) => '${m.start == 0 ? '' : '_'}${m[0]!.toLowerCase()}',
  );
}

/// Converts `fooBar` to `FooBar`.
String _sentenceCase(String str) =>
    str.isEmpty ? str : '${str[0].toUpperCase()}${str.substring(1)}';

/// A summary of the compilation strategy used for Dart.
enum BuildMode {
  /// Built in JIT mode with no optimizations, enabled asserts, and a VM service.
  debug,

  /// Built in AOT mode with some optimizations and a VM service.
  profile,

  /// Built in AOT mode with all optimizations and no VM service.
  release,

  /// Built in JIT mode with all optimizations and no VM service.
  jitRelease;

  factory BuildMode.fromCliName(String value) => values.singleWhere(
    (BuildMode element) => element.cliName == value,
    orElse: () => throw ArgumentError('$value is not a supported build mode'),
  );

  static const releaseModes = <BuildMode>{release, jitRelease};
  static const jitModes = <BuildMode>{debug, jitRelease};

  /// Whether this mode is considered release.
  ///
  /// Useful for determining whether we should enable/disable asserts or
  /// other development features.
  bool get isRelease => releaseModes.contains(this);

  /// Whether this mode is using the JIT runtime.
  bool get isJit => jitModes.contains(this);

  /// Whether this mode is using the precompiled runtime.
  bool get isPrecompiled => !isJit;

  /// [name] formatted in snake case.
  ///
  /// (e.g. debug, profile, release, jit_release)
  String get cliName => _snakeCase(name);

  /// [cliName] formatted in sentence case.
  ///
  /// (e.g. Debug, Profile, Release, Jit_release)
  String get uppercaseName => _sentenceCase(cliName);

  /// [cliName] with `_` replaced with a space.
  ///
  /// (e.g. debug, profile, release, jit release)
  String get friendlyName => cliName.replaceAll('_', ' ');

  /// [friendlyName] formatted in sentence case.
  ///
  /// (e.g. Debug, Profile, Release, Jit release)
  String get uppercaseFriendlyName => _sentenceCase(friendlyName);

  @override
  String toString() => cliName;
}

/// Representation of a Flutter plugin resolved for an extension target platform.
@immutable
class ExtensionPlugin {
  const ExtensionPlugin({
    required this.name,
    required this.path,
    this.configuration = const <String, Object?>{},
  });

  /// Deserializes an [ExtensionPlugin] from a JSON-serializable map.
  factory ExtensionPlugin.fromJson(Map<String, Object?> json) {
    final String name = switch (json[nameKey]) {
      final String value when value.isNotEmpty => value,
      final Object? invalid => throw ArgumentError(
        'Missing or invalid "$nameKey" for ExtensionPlugin: $invalid',
      ),
    };
    final Uri path = switch (json[pathKey]) {
      final String value when value.isNotEmpty => _parseDirectoryUri(value, pathKey),
      final Object? invalid => throw ArgumentError(
        'Missing or invalid "$pathKey" for ExtensionPlugin: $invalid',
      ),
    };
    final Map<String, Object?> configuration = switch (json[configurationKey]) {
      final Map<String, Object?> value => value,
      null => const <String, Object?>{},
      final Object? invalid => throw ArgumentError(
        'Invalid "$configurationKey" for ExtensionPlugin: $invalid',
      ),
    };
    return ExtensionPlugin(name: name, path: path, configuration: configuration);
  }

  /// Map key for [configuration].
  static const String configurationKey = 'configuration';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [path].
  static const String pathKey = 'path';

  static Uri _parseDirectoryUri(String rawUri, String fieldName) {
    final Uri? uri = Uri.tryParse(rawUri);
    if (uri == null || !uri.hasAbsolutePath || !uri.path.endsWith('/')) {
      throw ArgumentError(
        '"$fieldName" must be an absolute directory URI ending with "/": $rawUri',
      );
    }
    return uri;
  }

  /// Deserializes a list of [ExtensionPlugin] objects from RPC parameter data.
  static List<ExtensionPlugin> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ExtensionPlugin>[
        for (final Object? item in list)
          switch (item) {
            final Map<String, Object?> map => ExtensionPlugin.fromJson(map),
            final Object? invalid => throw ArgumentError(
              'Invalid entry in ExtensionPlugin list: $invalid',
            ),
          },
      ];
    }
    throw ArgumentError('Invalid ExtensionPlugin list: $rpcResult');
  }

  /// The package name of the plugin.
  final String name;

  /// The absolute, trailing-slash terminated directory URI of the plugin root on disk.
  final Uri path;

  /// The raw platform-specific configuration map from `pubspec.yaml` under
  /// `flutter.plugin.platforms.<platformKey>`.
  final Map<String, Object?> configuration;

  /// Serializes the plugin to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    pathKey: path.toString(),
    configurationKey: configuration,
  };

  @override
  String toString() => 'ExtensionPlugin(name: $name, path: $path, configuration: $configuration)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionPlugin &&
            other.name == name &&
            other.path == path &&
            _deepEquals(other.configuration, configuration));
  }

  @override
  int get hashCode => Object.hash(name, path, _deepHash(configuration));
}

/// Representation of a custom build target provided by a tool extension.
@immutable
class ExtensionBuildTarget {
  const ExtensionBuildTarget({
    required this.description,
    required this.name,
    this.nativeAssetsConfig,
    this.pluginPlatformKey,
  });

  /// Deserializes an [ExtensionBuildTarget] from a JSON-serializable map.
  factory ExtensionBuildTarget.fromJson(Map<String, Object?> json) {
    return ExtensionBuildTarget(
      description: switch (json[descriptionKey]) {
        final String value => value,
        _ => '',
      },
      name: switch (json[nameKey]) {
        final String value => value,
        _ => '',
      },
      nativeAssetsConfig: switch (json[nativeAssetsConfigKey]) {
        final Map<String, Object?> map => ExtensionNativeAssetsConfig.fromJson(map),
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$nativeAssetsConfigKey": $invalid'),
      },
      pluginPlatformKey: switch (json[pluginPlatformKeyKey]) {
        final String value => value,
        null => null,
        final Object? invalid => throw ArgumentError('Invalid "$pluginPlatformKeyKey": $invalid'),
      },
    );
  }

  /// Map key for [description].
  static const String descriptionKey = 'description';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [nativeAssetsConfig].
  static const String nativeAssetsConfigKey = 'nativeAssetsConfig';

  /// Map key for [pluginPlatformKey].
  static const String pluginPlatformKeyKey = 'pluginPlatformKey';

  /// Deserializes a list of [ExtensionBuildTarget] objects from RPC response data.
  static List<ExtensionBuildTarget> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <ExtensionBuildTarget>[
        for (final item in list)
          if (item case final Map<String, Object?> map) ExtensionBuildTarget.fromJson(map),
      ];
    }
    return const <ExtensionBuildTarget>[];
  }

  /// Description of what this target builds.
  final String description;

  /// The name of this build target (e.g. `'custom-apk'`).
  final String name;

  /// Optional Dart hooks (`native_assets`) target OS, architecture, and compiler
  /// configuration for custom targets.
  final ExtensionNativeAssetsConfig? nativeAssetsConfig;

  /// Optional platform key under `flutter.plugin.platforms.<key>` in `pubspec.yaml`
  /// used to resolve plugins for this target (e.g. `'linux'`, `'custom_platform'`).
  final String? pluginPlatformKey;

  /// Serializes the build target to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    descriptionKey: description,
    nameKey: name,
    nativeAssetsConfigKey: ?nativeAssetsConfig?.toMap(),
    pluginPlatformKeyKey: ?pluginPlatformKey,
  };

  @override
  String toString() =>
      'ExtensionBuildTarget(name: $name, description: $description, '
      'nativeAssetsConfig: $nativeAssetsConfig, '
      'pluginPlatformKey: $pluginPlatformKey)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildTarget &&
            other.description == description &&
            other.name == name &&
            other.nativeAssetsConfig == nativeAssetsConfig &&
            other.pluginPlatformKey == pluginPlatformKey);
  }

  @override
  int get hashCode => Object.hash(description, name, nativeAssetsConfig, pluginPlatformKey);
}

/// Representation of a build result returned by a tool extension.
@immutable
class ExtensionBuildResult {
  const ExtensionBuildResult({required this.success, this.errorMessage});

  /// Deserializes an [ExtensionBuildResult] from a JSON-serializable map.
  factory ExtensionBuildResult.fromJson(Map<String, Object?> json) {
    return ExtensionBuildResult(
      success: switch (json[successKey]) {
        final bool value => value,
        _ => false,
      },
      errorMessage: switch (json[errorMessageKey]) {
        final String value => value,
        _ => null,
      },
    );
  }

  /// Map key for [errorMessage].
  static const String errorMessageKey = 'errorMessage';

  /// Map key for [success].
  static const String successKey = 'success';

  /// Whether the build succeeded.
  final bool success;

  /// Optional error message if the build failed.
  final String? errorMessage;

  /// Serializes the build result to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    successKey: success,
    errorMessageKey: ?errorMessage,
  };

  @override
  String toString() => 'ExtensionBuildResult(success: $success, errorMessage: $errorMessage)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionBuildResult &&
            other.success == success &&
            other.errorMessage == errorMessage);
  }

  @override
  int get hashCode => Object.hash(success, errorMessage);
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a is Map<Object?, Object?> && b is Map<Object?, Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (final MapEntry(:Object? key, :Object? value) in a.entries) {
      if (!b.containsKey(key) || !_deepEquals(value, b[key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

int _deepHash(Object? value) {
  return switch (value) {
    final Map<Object?, Object?> map => Object.hashAllUnordered(<int>[
      for (final MapEntry(:Object? key, :Object? value) in map.entries)
        Object.hash(_deepHash(key), _deepHash(value)),
    ]),
    final List<Object?> list => Object.hashAll(<int>[
      for (final Object? item in list) _deepHash(item),
    ]),
    _ => value.hashCode,
  };
}
