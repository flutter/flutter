// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Static metadata parsed from an extension package's
/// `extension/flutter_tools/config.yaml` file.
///
/// Tool extension packages publish this manifest at
/// `<package_root>/extension/flutter_tools/config.yaml` so `flutter_tools` can
/// discover extension capabilities via `package:extension_discovery` without
/// compiling or spawning extension isolates up front.
///
/// ### Schema
///
/// - `name` (`String`, optional when the hosting package name is supplied to
///   [ExtensionPackageConfig.fromMap], otherwise required): The Dart package
///   name of the extension. If both `name` in `config.yaml` and `packageName`
///   are provided, they must match.
/// - `entrypoint` (`String`, optional): Relative POSIX path within the package
///   to the isolate entrypoint script (must not be absolute, contain `\`,
///   include `..` segments, or specify a URI scheme). Defaults to
///   `'bin/<name>.dart'`.
/// - `supported_platforms` (`List<String>`, optional): Host operating systems on
///   which the extension can run (normalized to lowercase, e.g., `'linux'`,
///   `'macos'`, `'windows'`). Platform-agnostic extensions omit this field to
///   run on all host platforms (when omitted or empty, [supportsHostPlatform]
///   imposes no static host platform filter before spawning). Extensions with
///   host-specific native tools or dependencies must explicitly declare their
///   supported host operating systems.
/// - `services` (`List<String>`, required): RPC service namespaces implemented
///   by the extension (e.g., `'diagnostics'`, `'config'`, `'template'`,
///   `'device'`, `'build'`). Required, non-empty. Entries are lowercase service
///   namespace identifiers matching known tool services (`'build'`,
///   `'device'`, `'template'`, `'config'`, `'diagnostics'`, `'clean'`,
///   `'artifacts'`).
/// - `build_targets` (`List<String>`, optional): Lowercase kebab-case
///   subcommand target names contributed to `flutter build` (e.g.
///   `'custom-target'`).
/// - `templates` (`List<String>`, optional): Lowercase kebab-case template
///   names contributed to `flutter create -t` (e.g. `'custom-app'`).
/// - `platforms` (`List<String>`, optional): Custom target platform identifiers
///   supported for `flutter create --platforms=<platform>`. Each entry must be
///   a lowercase snake_case identifier starting with a letter and containing
///   only lowercase letters, digits, and underscores (e.g. `'custom_os'`).
///
/// ### Example `extension/flutter_tools/config.yaml`
///
/// ```yaml
/// name: my_custom_extension
/// entrypoint: bin/my_custom_extension.dart
/// supported_platforms:
///   - linux
///   - macos
/// services:
///   - diagnostics
///   - config
///   - template
///   - device
///   - build
/// build_targets:
///   - custom-target
/// templates:
///   - custom-app
/// platforms:
///   - custom_os
/// ```
@immutable
final class ExtensionPackageConfig {
  ExtensionPackageConfig({
    required this.name,
    Iterable<String> buildTargets = const <String>{},
    String? entrypoint,
    Iterable<String> platforms = const <String>{},
    required Iterable<String> services,
    Iterable<String> supportedPlatforms = const <String>{},
    Iterable<String> templates = const <String>{},
  }) : assert(services.isNotEmpty),
       entrypoint = _validateEntrypoint(entrypoint ?? 'bin/$name.dart'),
       supportedPlatforms = Set<String>.unmodifiable(
         supportedPlatforms.map((String p) => p.toLowerCase()),
       ),
       services = Set<String>.unmodifiable(services),
       buildTargets = Set<String>.unmodifiable(buildTargets),
       templates = Set<String>.unmodifiable(templates),
       platforms = _validatePlatforms(platforms);

  /// Parses an [ExtensionPackageConfig] from a decoded YAML or JSON [json] map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ExtensionPackageConfig.fromMap(Map<String, Object?> json, {String? packageName}) {
    final String rawName = packageName != null && json[nameKey] == null
        ? packageName
        : json.requiredField<String>(nameKey);
    final String name = rawName.trim();
    if (name.isEmpty) {
      throw const FormatException(
        'Extension config.yaml must specify a non-empty string for "$nameKey".',
      );
    }

    if (packageName != null && name != packageName) {
      throw FormatException(
        'Extension config.yaml "$nameKey" ("$name") must match package name ("$packageName").',
      );
    }

    final String? rawEntrypoint = json.nullableField<String>(entrypointKey);
    final String entrypoint = _validateEntrypoint(rawEntrypoint ?? 'bin/$name.dart');

    final Set<String> services = json.stringSet(servicesKey, rejectEmpty: true);
    if (services.isEmpty) {
      throw const FormatException(
        'Extension config.yaml must specify a non-empty list of services for "$servicesKey".',
      );
    }

    return ExtensionPackageConfig(
      name: name,
      entrypoint: entrypoint,
      supportedPlatforms: json.stringSet(supportedPlatformsKey, rejectEmpty: true),
      services: services,
      buildTargets: json.stringSet(buildTargetsKey, rejectEmpty: true),
      templates: json.stringSet(templatesKey, rejectEmpty: true),
      platforms: json.stringSet(platformsKey, rejectEmpty: true),
    );
  }

  /// Map key for [name].
  static const String nameKey = 'name';

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
          'Extension config.yaml "$platformsKey" entries must be lowercase snake_case identifiers '
          'starting with a letter (e.g. "custom_os"), got: "$platform".',
        );
      }
      validated.add(trimmed);
    }
    return Set<String>.unmodifiable(validated);
  }

  static const SetEquality<String> _stringSetEquality = SetEquality<String>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ExtensionPackageConfig &&
        other.name == name &&
        other.entrypoint == entrypoint &&
        _stringSetEquality.equals(other.supportedPlatforms, supportedPlatforms) &&
        _stringSetEquality.equals(other.services, services) &&
        _stringSetEquality.equals(other.buildTargets, buildTargets) &&
        _stringSetEquality.equals(other.templates, templates) &&
        _stringSetEquality.equals(other.platforms, platforms);
  }

  @override
  int get hashCode => Object.hash(
    name,
    entrypoint,
    _stringSetEquality.hash(supportedPlatforms),
    _stringSetEquality.hash(services),
    _stringSetEquality.hash(buildTargets),
    _stringSetEquality.hash(templates),
    _stringSetEquality.hash(platforms),
  );

  @override
  String toString() =>
      'ExtensionPackageConfig('
      'name: $name, '
      'entrypoint: $entrypoint, '
      'supportedPlatforms: $supportedPlatforms, '
      'services: $services, '
      'buildTargets: $buildTargets, '
      'templates: $templates, '
      'platforms: $platforms)';
}
