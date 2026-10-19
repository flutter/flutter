// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../build.dart';

const _validLeadingDirectoryPlaceholders = <String>{
  BuiltInPlaceholders.projectDir,
  BuiltInPlaceholders.workspaceDir,
  BuiltInPlaceholders.buildDir,
  BuiltInPlaceholders.cacheDir,
  BuiltInPlaceholders.flutterRootDir,
  BuiltInPlaceholders.outputDir,
};

/// Represents an artifact downloaded from the Flutter cache (e.g. engine binaries, frameworks).
///
/// Extensions can reference these artifacts in their target inputs/outputs,
/// and the host will resolve them to physical paths on the host before build execution.
///
/// See also:
///
/// * [BuiltInArtifacts], commonly used artifacts.
extension type const ExtensionArtifact(String name) {}

/// Represents an artifact used by the host build system (e.g. compilers, tools).
///
/// Extensions can reference these host-side artifacts in their target inputs/outputs,
/// and the host will resolve them to physical paths on the host before build execution.
///
/// See also:
///
/// * [BuiltInHostArtifacts], commonly used host artifacts.
extension type const ExtensionHostArtifact(String name) {}

/// A description of an input or output of an [ExtensionAssembleTarget].
@immutable
sealed class ExtensionSource {
  const ExtensionSource();

  /// A file pattern that must begin with a directory placeholder such as
  /// [BuiltInPlaceholders.projectDir], [BuiltInPlaceholders.buildDir], or
  /// [BuiltInPlaceholders.outputDir] (for example, `'{PROJECT_DIR}/pubspec.yaml'`).
  ///
  /// See also:
  ///
  /// * [BuiltInPlaceholders], the available directory placeholders.
  const factory ExtensionSource.pattern(String pattern, {bool optional}) = ExtensionPatternSource;

  /// An [ExtensionSource] representing a target-platform or build-mode specific
  /// engine artifact downloaded from the Flutter cache (for example, `icudtl.dat`
  /// or `gen_snapshot`).
  ///
  /// See also:
  ///
  /// * [ExtensionArtifact], the identifier for an engine artifact.
  /// * [BuiltInArtifacts], commonly used artifacts.
  const factory ExtensionSource.artifact(
    ExtensionArtifact artifact, {
    BuildMode? mode,
    String? platform,
  }) = ExtensionArtifactSource;

  /// An [ExtensionSource] representing a host-platform tool or library from the
  /// Flutter cache used by the build system (for example, `impellerc` or
  /// `libtessellator`).
  ///
  /// See also:
  ///
  /// * [ExtensionHostArtifact], the identifier for a host artifact.
  /// * [BuiltInHostArtifacts], commonly used host artifacts.
  const factory ExtensionSource.hostArtifact(ExtensionHostArtifact artifact) =
      ExtensionHostArtifactSource;

  /// Deserializes an [ExtensionSource] from a JSON-serializable map.
  factory ExtensionSource.fromJson(Map<String, Object?> json) {
    return switch (json[typeKey]) {
      patternType => ExtensionSource.pattern(
        switch (json[valueKey]) {
          final String value => ExtensionPatternSource.parse(value),
          _ => throw ArgumentError(
            'Missing or invalid "$valueKey" for $patternType ExtensionSource.',
          ),
        },
        optional: switch (json[optionalKey]) {
          final bool optional => optional,
          _ => false,
        },
      ),
      artifactType => ExtensionSource.artifact(
        ExtensionArtifact(switch (json[artifactKey]) {
          final String artifact => artifact,
          _ => throw ArgumentError(
            'Missing or invalid "$artifactKey" for $artifactType ExtensionSource.',
          ),
        }),
        mode: switch (json[modeKey]) {
          final String mode => BuildMode.fromCliName(mode),
          _ => null,
        },
        platform: switch (json[platformKey]) {
          final String platform => platform,
          _ => null,
        },
      ),
      hostArtifactType => ExtensionSource.hostArtifact(
        ExtensionHostArtifact(switch (json[artifactKey]) {
          final String artifact => artifact,
          _ => throw ArgumentError(
            'Missing or invalid "$artifactKey" for $hostArtifactType ExtensionSource.',
          ),
        }),
      ),
      final Object? type => throw ArgumentError('Unknown ExtensionSource type in JSON: $type'),
    };
  }

  /// Map key for the source type discriminator.
  static const String typeKey = 'type';

  /// Map key for a pattern source's value.
  static const String valueKey = 'value';

  /// Map key for whether a pattern source is optional.
  static const String optionalKey = 'optional';

  /// Map key for an artifact or host artifact name.
  static const String artifactKey = 'artifact';

  /// Map key for an artifact source's target platform.
  static const String platformKey = 'platform';

  /// Map key for an artifact source's build mode.
  static const String modeKey = 'mode';

  /// Type discriminator value for [ExtensionSource.pattern].
  static const String patternType = 'pattern';

  /// Type discriminator value for [ExtensionSource.artifact].
  static const String artifactType = 'artifact';

  /// Type discriminator value for [ExtensionSource.hostArtifact].
  static const String hostArtifactType = 'host_artifact';

  /// Serializes the source to a JSON-serializable map.
  Map<String, Object?> toMap();
}

/// An [ExtensionSource] defined by a file pattern with a leading directory placeholder.
///
/// See also:
///
/// * [BuiltInPlaceholders], the available directory placeholders.
@immutable
final class ExtensionPatternSource extends ExtensionSource {
  const ExtensionPatternSource(this.value, {this.optional = false});

  /// Parses and validates a pattern string starting with a directory placeholder.
  ///
  /// A valid placeholder must either equal [value] or be followed immediately by
  /// `/` (e.g. `'{PROJECT_DIR}/lib/main.dart'`).
  ///
  /// Throws a [FormatException] if [value] does not begin with a valid directory
  /// placeholder.
  static String parse(String value) {
    for (final String placeholder in _validLeadingDirectoryPlaceholders) {
      if (value == placeholder || value.startsWith('$placeholder/')) {
        return value;
      }
    }
    throw FormatException(
      'Invalid pattern "$value": must start with a directory placeholder followed by "/".',
      value,
    );
  }

  /// The file path pattern beginning with a directory placeholder.
  final String value;

  /// Whether the file is optional when resolving inputs.
  final bool optional;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ExtensionSource.typeKey: ExtensionSource.patternType,
    ExtensionSource.valueKey: value,
    ExtensionSource.optionalKey: optional,
  };

  @override
  String toString() => 'ExtensionSource.pattern($value, optional: $optional)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtensionPatternSource && other.value == value && other.optional == optional);

  @override
  int get hashCode => Object.hash(value, optional);
}

/// An [ExtensionSource] representing a target-platform or build-mode specific
/// engine artifact downloaded from the Flutter cache (for example, `icudtl.dat`
/// or `gen_snapshot`).
///
/// See also:
///
/// * [ExtensionArtifact], the identifier for an engine artifact.
/// * [BuiltInArtifacts], commonly used artifacts.
@immutable
final class ExtensionArtifactSource extends ExtensionSource {
  const ExtensionArtifactSource(this.artifact, {this.mode, this.platform});

  /// The requested engine artifact.
  final ExtensionArtifact artifact;

  /// Optional build mode override for resolving the artifact.
  final BuildMode? mode;

  /// Optional target platform name override for resolving the artifact.
  final String? platform;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ExtensionSource.typeKey: ExtensionSource.artifactType,
    ExtensionSource.artifactKey: artifact.name,
    ExtensionSource.platformKey: ?platform,
    ExtensionSource.modeKey: ?mode?.cliName,
  };

  @override
  String toString() => 'ExtensionSource.artifact($artifact, mode: $mode, platform: $platform)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtensionArtifactSource &&
          other.artifact == artifact &&
          other.platform == platform &&
          other.mode == mode);

  @override
  int get hashCode => Object.hash(artifact, platform, mode);
}

/// An [ExtensionSource] representing a host-platform tool or library from the
/// Flutter cache used by the build system (for example, `impellerc` or
/// `libtessellator`).
///
/// See also:
///
/// * [ExtensionHostArtifact], the identifier for a host artifact.
/// * [BuiltInHostArtifacts], commonly used host artifacts.
@immutable
final class ExtensionHostArtifactSource extends ExtensionSource {
  const ExtensionHostArtifactSource(this.artifact);

  /// The requested host artifact.
  final ExtensionHostArtifact artifact;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ExtensionSource.typeKey: ExtensionSource.hostArtifactType,
    ExtensionSource.artifactKey: artifact.name,
  };

  @override
  String toString() => 'ExtensionSource.hostArtifact($artifact)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtensionHostArtifactSource && other.artifact == artifact);

  @override
  int get hashCode => artifact.hashCode;
}
