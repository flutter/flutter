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
/// - `name` (`String`, required): The Dart package name of the extension. If
///   `packageName` is provided to [ExtensionPackageConfig.fromMap], `name` must
///   match `packageName`.
/// - `entrypoint` (`String`, optional): Relative POSIX path within the package
///   to the `.dart` isolate entrypoint script (must not be absolute, contain
///   `\`, include `.` or `..` segments, or specify a URI scheme, authority,
///   query, or fragment). Defaults to `'bin/<name>.dart'`.
/// - `host_platforms` (`List<String>`, optional): Host operating systems on
///   which the extension can run (normalized to lowercase, e.g., `'linux'`,
///   `'macos'`, `'windows'`). Platform-agnostic extensions omit this field to
///   run on all host platforms (when omitted or empty, [supportsHostPlatform]
///   imposes no static host platform filter before spawning). Extensions with
///   host-specific native tools or dependencies must explicitly declare their
///   supported host operating systems.
/// - `services` (`List<String>`, optional): RPC service namespaces implemented
///   by the extension (e.g., `'diagnostics'`, `'config'`, `'template'`,
///   `'device'`, `'build'`). Defaults to empty. Entries must be non-empty
///   lowercase service namespace identifiers matching known tool services
///   (`'build'`, `'device'`, `'template'`, `'config'`, `'diagnostics'`,
///   `'clean'`, `'artifacts'`).
/// - `build_targets` (`List<String>`, optional): Lowercase kebab-case
///   subcommand target names contributed to `flutter build` (e.g.
///   `'custom-target'`).
/// - `templates` (`List<String>`, optional): Lowercase kebab-case template
///   names contributed to `flutter create -t` (e.g. `'custom-app'`).
/// - `target_platforms` (`List<String>`, optional): Custom target platform
///   identifiers supported for `flutter create --platforms=<platform>`. Each
///   entry must be a lowercase snake_case identifier starting with a letter and
///   containing only lowercase letters, digits, and underscores (e.g.
///   `'custom_os'`).
///
/// ### Example `extension/flutter_tools/config.yaml`
///
/// ```yaml
/// name: my_custom_extension
/// entrypoint: bin/my_custom_extension.dart
/// host_platforms:
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
/// target_platforms:
///   - custom_os
/// ```
@immutable
final class ExtensionPackageConfig {
  ExtensionPackageConfig({
    required this.name,
    Iterable<String> buildTargets = const <String>{},
    String? entrypoint,
    Iterable<String> hostPlatforms = const <String>{},
    Iterable<String> services = const <String>{},
    Iterable<String> targetPlatforms = const <String>{},
    Iterable<String> templates = const <String>{},
  }) : entrypoint = _validateEntrypoint(entrypoint ?? 'bin/$name.dart'),
       hostPlatforms = Set<String>.unmodifiable(
         hostPlatforms.map((String p) => p.trim().toLowerCase()),
       ),
       services = Set<String>.unmodifiable(services.map((String s) => s.trim())),
       buildTargets = Set<String>.unmodifiable(buildTargets.map((String t) => t.trim())),
       templates = Set<String>.unmodifiable(templates.map((String t) => t.trim())),
       targetPlatforms = _validateTargetPlatforms(targetPlatforms);

  /// Parses an [ExtensionPackageConfig] from a decoded YAML or JSON [json] map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ExtensionPackageConfig.fromMap(Map<String, Object?> json, {String? packageName}) {
    final String name = json.requiredField<String>(nameKey).trim();
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

    return ExtensionPackageConfig(
      name: name,
      entrypoint: entrypoint,
      hostPlatforms: json.stringSet(hostPlatformsKey, rejectEmpty: true, trim: true),
      services: json.stringSet(servicesKey, rejectEmpty: true, trim: true),
      buildTargets: json.stringSet(buildTargetsKey, rejectEmpty: true, trim: true),
      templates: json.stringSet(templatesKey, rejectEmpty: true, trim: true),
      targetPlatforms: json.stringSet(targetPlatformsKey, rejectEmpty: true, trim: true),
    );
  }

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [entrypoint].
  static const String entrypointKey = 'entrypoint';

  /// Map key for [hostPlatforms].
  static const String hostPlatformsKey = 'host_platforms';

  /// Map key for [services].
  static const String servicesKey = 'services';

  /// Map key for [buildTargets].
  static const String buildTargetsKey = 'build_targets';

  /// Map key for [templates].
  static const String templatesKey = 'templates';

  /// Map key for [targetPlatforms].
  static const String targetPlatformsKey = 'target_platforms';

  static final RegExp _platformIdentifierPattern = RegExp(r'^[a-z][a-z0-9_]*$');

  /// The Dart package name of the extension.
  final String name;

  /// Relative path from the extension package root to the isolate entrypoint script.
  final String entrypoint;

  /// Host platforms supported by this extension (e.g. `{'linux', 'macos', 'windows'}`).
  ///
  /// If empty, the extension is assumed to support all host platforms.
  final Set<String> hostPlatforms;

  /// Service namespaces provided by this extension (e.g. `{'diagnostics', 'config', 'build'}`).
  final Set<String> services;

  /// Custom build target names provided by this extension.
  final Set<String> buildTargets;

  /// Custom project template names provided by this extension.
  final Set<String> templates;

  /// Custom target platform names provided by this extension for `--platforms`.
  final Set<String> targetPlatforms;

  /// Whether this extension supports the given [hostPlatform] (case-insensitive).
  bool supportsHostPlatform(String hostPlatform) {
    if (hostPlatforms.isEmpty) {
      return true;
    }
    return hostPlatforms.contains(hostPlatform.toLowerCase());
  }

  /// Serializes this [ExtensionPackageConfig] to a JSON-compatible map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      nameKey: name,
      entrypointKey: entrypoint,
      hostPlatformsKey: hostPlatforms.toList(),
      servicesKey: services.toList(),
      buildTargetsKey: buildTargets.toList(),
      templatesKey: templates.toList(),
      targetPlatformsKey: targetPlatforms.toList(),
    };
  }

  static String _validateEntrypoint(String entrypoint) {
    final String trimmed = entrypoint.trim();
    final Uri? parsedUri = Uri.tryParse(trimmed);
    if (trimmed.isEmpty ||
        trimmed.startsWith('/') ||
        trimmed.contains(r'\') ||
        !trimmed.endsWith('.dart') ||
        parsedUri == null ||
        parsedUri.hasScheme ||
        parsedUri.hasAuthority ||
        parsedUri.hasQuery ||
        parsedUri.hasFragment ||
        parsedUri.path != trimmed ||
        parsedUri.pathSegments.isEmpty ||
        parsedUri.pathSegments.contains('') ||
        parsedUri.pathSegments.contains('.') ||
        parsedUri.pathSegments.contains('..') ||
        parsedUri.pathSegments.last == '.dart') {
      throw FormatException(
        'Extension config.yaml "$entrypointKey" must be a relative path to a ".dart" file '
        'within the package, got: "$entrypoint".',
      );
    }
    return trimmed;
  }

  static Set<String> _validateTargetPlatforms(Iterable<String> targetPlatforms) {
    final validated = <String>{};
    for (final platform in targetPlatforms) {
      final String trimmed = platform.trim();
      if (!_platformIdentifierPattern.hasMatch(trimmed)) {
        throw FormatException(
          'Extension config.yaml "$targetPlatformsKey" entries must be lowercase snake_case '
          'identifiers starting with a letter (e.g. "custom_os"), got: "$platform".',
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
        _stringSetEquality.equals(other.hostPlatforms, hostPlatforms) &&
        _stringSetEquality.equals(other.services, services) &&
        _stringSetEquality.equals(other.buildTargets, buildTargets) &&
        _stringSetEquality.equals(other.templates, templates) &&
        _stringSetEquality.equals(other.targetPlatforms, targetPlatforms);
  }

  @override
  int get hashCode => Object.hash(
    name,
    entrypoint,
    _stringSetEquality.hash(hostPlatforms),
    _stringSetEquality.hash(services),
    _stringSetEquality.hash(buildTargets),
    _stringSetEquality.hash(templates),
    _stringSetEquality.hash(targetPlatforms),
  );

  @override
  String toString() =>
      'ExtensionPackageConfig('
      'name: $name, '
      'entrypoint: $entrypoint, '
      'hostPlatforms: $hostPlatforms, '
      'services: $services, '
      'buildTargets: $buildTargets, '
      'templates: $templates, '
      'targetPlatforms: $targetPlatforms)';
}
