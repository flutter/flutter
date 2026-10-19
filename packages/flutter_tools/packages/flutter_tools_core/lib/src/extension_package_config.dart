// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Static metadata parsed from an extension package's
/// `extension/flutter_tools/config.yaml` file.
@immutable
final class ExtensionPackageConfig {
  ExtensionPackageConfig({
    required this.name,
    Iterable<String> buildTargets = const <String>{},
    String? entrypoint,
    Iterable<String> platforms = const <String>{},
    this.protocolVersion = currentProtocolVersion,
    Iterable<String> services = const <String>{},
    Iterable<String> supportedPlatforms = const <String>{},
    Iterable<String> templates = const <String>{},
  }) : entrypoint = _validateEntrypoint(entrypoint ?? 'bin/$name.dart'),
       supportedPlatforms = Set<String>.unmodifiable(
         supportedPlatforms.map((String p) => p.toLowerCase()),
       ),
       services = Set<String>.unmodifiable(services),
       buildTargets = Set<String>.unmodifiable(buildTargets),
       templates = Set<String>.unmodifiable(templates),
       platforms = _validatePlatforms(platforms);

  /// Parses an [ExtensionPackageConfig] from a decoded YAML or JSON [map].
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ExtensionPackageConfig.fromMap(Map<Object?, Object?> map, {String? packageName}) {
    final Object? rawName = map[nameKey] ?? packageName;
    if (rawName is! String || rawName.trim().isEmpty) {
      throw const FormatException(
        'Extension config.yaml must specify a non-empty string for "$nameKey".',
      );
    }
    final String name = rawName.trim();

    if (packageName != null && name != packageName) {
      throw FormatException(
        'Extension config.yaml "$nameKey" ("$name") must match package name ("$packageName").',
      );
    }

    final Object? rawProtocolVersion = map[protocolVersionKey];
    final int protocolVersion = switch (rawProtocolVersion) {
      final int v => v,
      null => currentProtocolVersion,
      final Object? other => throw FormatException(
        'Extension config.yaml "$protocolVersionKey" must be an int, got: $other.',
      ),
    };

    final String entrypoint = switch (map[entrypointKey]) {
      final String e when e.trim().isNotEmpty => _validateEntrypoint(e),
      null => _validateEntrypoint('bin/$name.dart'),
      final Object? other => throw FormatException(
        'Extension config.yaml "$entrypointKey" must be a non-empty string, got: $other.',
      ),
    };

    return ExtensionPackageConfig(
      name: name,
      protocolVersion: protocolVersion,
      entrypoint: entrypoint,
      supportedPlatforms: _parseStringSet(map[supportedPlatformsKey], supportedPlatformsKey),
      services: _parseStringSet(map[servicesKey], servicesKey),
      buildTargets: _parseStringSet(map[buildTargetsKey], buildTargetsKey),
      templates: _parseStringSet(map[templatesKey], templatesKey),
      platforms: _parseStringSet(map[platformsKey], platformsKey),
    );
  }

  /// Current supported extension protocol version.
  static const int currentProtocolVersion = 1;

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [protocolVersion].
  static const String protocolVersionKey = 'protocol_version';

  /// Map key for [entrypoint].
  static const String entrypointKey = 'entrypoint';

  /// Map key for [supportedPlatforms].
  static const String supportedPlatformsKey = 'supported_platforms';

  /// Map key for [services].
  static const String servicesKey = 'services';

  /// Map key for [buildTargets].
  static const String buildTargetsKey = 'build_targets';

  /// Map key for [templates].
  static const String templatesKey = 'templates';

  /// Map key for [platforms].
  static const String platformsKey = 'platforms';

  static final RegExp _platformIdentifierPattern = RegExp(r'^[a-z][a-z0-9_]*$');

  /// The Dart package name of the extension.
  final String name;

  /// The extension protocol version targeted by this package.
  final int protocolVersion;

  /// Relative path from the extension package root to the isolate entrypoint script.
  final String entrypoint;

  /// Host platforms supported by this extension (e.g. `{'linux', 'macos', 'windows'}`).
  ///
  /// If empty, the extension is assumed to support all host platforms.
  final Set<String> supportedPlatforms;

  /// Service namespaces provided by this extension (e.g. `{'diagnostics', 'config', 'build'}`).
  final Set<String> services;

  /// Custom build target names provided by this extension.
  final Set<String> buildTargets;

  /// Custom project template names provided by this extension.
  final Set<String> templates;

  /// Custom target platform names provided by this extension for `--platforms`.
  final Set<String> platforms;

  /// Whether this extension supports the given [hostPlatform] (case-insensitive).
  bool supportsHostPlatform(String hostPlatform) {
    if (supportedPlatforms.isEmpty) {
      return true;
    }
    return supportedPlatforms.contains(hostPlatform.toLowerCase());
  }

  /// Serializes this [ExtensionPackageConfig] to a JSON-compatible map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      nameKey: name,
      protocolVersionKey: protocolVersion,
      entrypointKey: entrypoint,
      supportedPlatformsKey: supportedPlatforms.toList(),
      servicesKey: services.toList(),
      buildTargetsKey: buildTargets.toList(),
      templatesKey: templates.toList(),
      platformsKey: platforms.toList(),
    };
  }

  static String _validateEntrypoint(String entrypoint) {
    final String trimmed = entrypoint.trim();
    final Uri? parsedUri = Uri.tryParse(trimmed);
    if (trimmed.isEmpty ||
        trimmed.startsWith('/') ||
        trimmed.contains(r'\') ||
        trimmed.split('/').contains('..') ||
        parsedUri == null ||
        parsedUri.hasScheme) {
      throw FormatException(
        'Extension config.yaml "$entrypointKey" must be a relative path within the package, '
        'got: "$entrypoint".',
      );
    }
    return trimmed;
  }

  static Set<String> _validatePlatforms(Iterable<String> platforms) {
    final validated = <String>{};
    for (final platform in platforms) {
      final String trimmed = platform.trim();
      if (!_platformIdentifierPattern.hasMatch(trimmed)) {
        throw FormatException(
          'Extension config.yaml "$platformsKey" entries must be valid lowercase identifiers, '
          'got: "$platform".',
        );
      }
      validated.add(trimmed);
    }
    return Set<String>.unmodifiable(validated);
  }

  static Set<String> _parseStringSet(Object? raw, String fieldName) {
    return switch (raw) {
      null => const <String>{},
      final List<Object?> list => <String>{
        for (final Object? item in list)
          if (item is String && item.trim().isNotEmpty)
            item.trim()
          else
            throw FormatException(
              'Extension config.yaml "$fieldName" entries must be non-empty strings, got: $item.',
            ),
      },
      final Object other => throw FormatException(
        'Extension config.yaml "$fieldName" must be a list of strings, got: $other.',
      ),
    };
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) {
      return true;
    }
    return a.length == b.length && a.containsAll(b);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ExtensionPackageConfig &&
        other.name == name &&
        other.protocolVersion == protocolVersion &&
        other.entrypoint == entrypoint &&
        _setEquals(other.supportedPlatforms, supportedPlatforms) &&
        _setEquals(other.services, services) &&
        _setEquals(other.buildTargets, buildTargets) &&
        _setEquals(other.templates, templates) &&
        _setEquals(other.platforms, platforms);
  }

  @override
  int get hashCode => Object.hash(
    name,
    protocolVersion,
    entrypoint,
    Object.hashAllUnordered(supportedPlatforms),
    Object.hashAllUnordered(services),
    Object.hashAllUnordered(buildTargets),
    Object.hashAllUnordered(templates),
    Object.hashAllUnordered(platforms),
  );

  @override
  String toString() =>
      'ExtensionPackageConfig('
      'name: $name, '
      'protocolVersion: $protocolVersion, '
      'entrypoint: $entrypoint, '
      'supportedPlatforms: $supportedPlatforms, '
      'services: $services, '
      'buildTargets: $buildTargets, '
      'templates: $templates, '
      'platforms: $platforms)';
}
