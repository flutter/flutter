// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Static metadata parsed from an extension package's
/// `extension/flutter_tools/config.yaml` manifest.
@immutable
final class ExtensionPackageConfig {
  ExtensionPackageConfig({
    required this.name,
    required Iterable<String> services,
    Iterable<String> buildTargets = const <String>{},
    String? entrypoint,
    Iterable<String> platforms = const <String>{},
    this.protocolVersion = currentProtocolVersion,
    Iterable<String> supportedPlatforms = defaultSupportedPlatforms,
    Iterable<String> templates = const <String>{},
  }) : buildTargets = Set<String>.unmodifiable(buildTargets),
       entrypoint = _validateEntrypoint(entrypoint ?? 'bin/$name.dart'),
       platforms = Set<String>.unmodifiable(platforms),
       services = Set<String>.unmodifiable(services),
       supportedPlatforms = Set<String>.unmodifiable(
         supportedPlatforms.map((String p) => p.toLowerCase()),
       ),
       templates = Set<String>.unmodifiable(templates);

  /// Deserializes an [ExtensionPackageConfig] from a decoded manifest [json] map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ExtensionPackageConfig.fromJson(Map<String, Object?> json, {String? packageName}) {
    final String rawName = json
        .optionalField<String>(nameKey, defaultValue: packageName ?? '')
        .trim();
    if (rawName.isEmpty) {
      throw const FormatException(
        'Extension config.yaml must specify a non-empty string for "$nameKey".',
      );
    }
    if (packageName != null && rawName != packageName) {
      throw FormatException(
        'Extension config.yaml "$nameKey" ("$rawName") must match package name ("$packageName").',
      );
    }

    final int protocolVersion = json.optionalField<int>(
      protocolVersionKey,
      defaultValue: currentProtocolVersion,
    );

    final String? entrypoint = json.nullableField<String>(entrypointKey);

    final List<String> parsedServices = json.stringIterable(servicesKey).toList();
    if (parsedServices.isEmpty) {
      throw const FormatException(
        'Extension config.yaml must specify a non-empty list of services for "$servicesKey".',
      );
    }

    final List<String> parsedPlatforms = json.stringIterable(supportedPlatformsKey).toList();

    return ExtensionPackageConfig(
      buildTargets: json.stringIterable(buildTargetsKey),
      entrypoint: entrypoint,
      name: rawName,
      platforms: json.stringIterable(platformsKey),
      protocolVersion: protocolVersion,
      services: parsedServices,
      supportedPlatforms: parsedPlatforms.isEmpty ? defaultSupportedPlatforms : parsedPlatforms,
      templates: json.stringIterable(templatesKey),
    );
  }

  /// Current supported extension protocol version.
  static const int currentProtocolVersion = 1;

  /// Relative path from the extension package root to the manifest file.
  static const String manifestRelativePath = 'extension/flutter_tools/config.yaml';

  /// Default host operating system platforms supported when omitted.
  static const defaultSupportedPlatforms = <String>{'linux', 'macos', 'windows'};

  /// Manifest key for [name].
  static const String nameKey = 'name';

  /// Manifest key for [protocolVersion].
  static const String protocolVersionKey = 'protocolVersion';

  /// Manifest key for [entrypoint].
  static const String entrypointKey = 'entrypoint';

  /// Manifest key for [supportedPlatforms].
  static const String supportedPlatformsKey = 'supportedPlatforms';

  /// Manifest key for [services].
  static const String servicesKey = 'services';

  /// Manifest key for [buildTargets].
  static const String buildTargetsKey = 'buildTargets';

  /// Manifest key for [templates].
  static const String templatesKey = 'templates';

  /// Manifest key for [platforms].
  static const String platformsKey = 'platforms';

  /// The Dart package name of the extension.
  final String name;

  /// The extension protocol version targeted by this package.
  final int protocolVersion;

  /// Relative POSIX path from the extension package root to the isolate entrypoint script.
  final String entrypoint;

  /// Host platforms supported by this extension in lowercase (e.g. `{'linux', 'macos', 'windows'}`).
  final Set<String> supportedPlatforms;

  /// Service namespaces provided by this extension (e.g. `{'diagnostics', 'config', 'build'}`).
  final Set<String> services;

  /// Custom `flutter build` target names provided by this extension.
  final Set<String> buildTargets;

  /// Custom `flutter create` project template names provided by this extension.
  final Set<String> templates;

  /// Custom target platform names provided by this extension for `--platforms`.
  final Set<String> platforms;

  /// Serializes this [ExtensionPackageConfig] to a JSON-compatible map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    protocolVersionKey: protocolVersion,
    entrypointKey: entrypoint,
    supportedPlatformsKey: supportedPlatforms.toList(),
    servicesKey: services.toList(),
    buildTargetsKey: buildTargets.toList(),
    templatesKey: templates.toList(),
    platformsKey: platforms.toList(),
  };

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

  static bool _setEquals(Set<String> a, Set<String> b) {
    return identical(a, b) || (a.length == b.length && a.containsAll(b));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionPackageConfig &&
            other.name == name &&
            other.protocolVersion == protocolVersion &&
            other.entrypoint == entrypoint &&
            _setEquals(other.supportedPlatforms, supportedPlatforms) &&
            _setEquals(other.services, services) &&
            _setEquals(other.buildTargets, buildTargets) &&
            _setEquals(other.templates, templates) &&
            _setEquals(other.platforms, platforms));
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
