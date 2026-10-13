// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../build.dart';

/// Represents an artifact downloaded from the Flutter cache (e.g. engine binaries, frameworks).
///
/// Extensions can reference these artifacts in their target inputs/outputs,
/// and the host will resolve them to physical paths on the host before build execution.
@immutable
class ExtensionArtifact {
  const ExtensionArtifact(this.name);

  /// The unique identifying name of this artifact.
  final String name;

  @override
  bool operator ==(Object other) => other is ExtensionArtifact && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// Represents an artifact used by the host build system (e.g. compilers, tools).
///
/// Extensions can reference these host-side artifacts in their target inputs/outputs,
/// and the host will resolve them to physical paths on the host before build execution.
@immutable
class ExtensionHostArtifact {
  const ExtensionHostArtifact(this.name);

  /// The unique identifying name of this host artifact.
  final String name;

  @override
  bool operator ==(Object other) => other is ExtensionHostArtifact && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// A description of an input or output of an [ExtensionBuildTarget].
@immutable
sealed class ExtensionSource {
  const ExtensionSource();

  /// A file pattern that must begin with a directory placeholder such as
  /// [kProjectDirPlaceholder], [kBuildDirPlaceholder], or [kOutputDirPlaceholder]
  /// (for example, `'{PROJECT_DIR}/pubspec.yaml'`).
  const factory ExtensionSource.pattern(String pattern, {bool optional}) = ExtensionPatternSource;

  /// A source provided by an [ExtensionArtifact].
  const factory ExtensionSource.artifact(
    ExtensionArtifact artifact, {
    BuildMode? mode,
    String? platform,
  }) = ExtensionArtifactSource;

  /// A source provided by an [ExtensionHostArtifact].
  const factory ExtensionSource.hostArtifact(ExtensionHostArtifact artifact) =
      ExtensionHostArtifactSource;

  /// Deserializes an [ExtensionSource] from a JSON-serializable map.
  factory ExtensionSource.fromJson(Map<String, Object?> json) {
    return switch (json[typeKey]) {
      patternType => ExtensionSource.pattern(
        switch (json[valueKey]) {
          final String value => value,
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
@immutable
final class ExtensionPatternSource extends ExtensionSource {
  const ExtensionPatternSource(this.value, {this.optional = false});

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

/// An [ExtensionSource] provided by an [ExtensionArtifact].
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

/// An [ExtensionSource] provided by an [ExtensionHostArtifact].
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
