// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'enums.dart';

/// Visitor interface to resolve [Source] objects into files in the host.
abstract class SourceVisitor {
  void visitPattern(String pattern, bool optional);
  void visitArtifact(Artifact artifact, String? platform, BuildMode? mode);
  void visitHostArtifact(HostArtifact artifact);
}

/// A description of an input or output of a Target.
@immutable
abstract class Source {
  const Source();

  /// This source is a file URL which contains some references to magic
  /// environment variables defined in Environment.
  const factory Source.pattern(String pattern, {bool optional}) = _PatternSource;

  /// The source is provided by an [Artifact].
  const factory Source.artifact(Artifact artifact, {BuildMode? mode, String? platform}) =
      _ArtifactSource;

  /// The source is provided by a [HostArtifact].
  const factory Source.hostArtifact(HostArtifact artifact) = _HostArtifactSource;

  /// Deserializes a [Source] from a JSON-serializable map.
  factory Source.fromJson(Map<String, Object?> json) {
    return switch (json[typeKey]) {
      patternType => Source.pattern(
        switch (json[valueKey]) {
          final String value => value,
          _ => throw ArgumentError('Missing or invalid "$valueKey" for $patternType Source.'),
        },
        optional: switch (json[optionalKey]) {
          final bool optional => optional,
          _ => false,
        },
      ),
      artifactType => Source.artifact(
        Artifact(switch (json[artifactKey]) {
          final String artifact => artifact,
          _ => throw ArgumentError('Missing or invalid "$artifactKey" for $artifactType Source.'),
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
      hostArtifactType => Source.hostArtifact(
        HostArtifact(switch (json[artifactKey]) {
          final String artifact => artifact,
          _ => throw ArgumentError(
            'Missing or invalid "$artifactKey" for $hostArtifactType Source.',
          ),
        }),
      ),
      final Object? type => throw ArgumentError('Unknown Source type in JSON: $type'),
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

  /// Type discriminator value for [Source.pattern].
  static const String patternType = 'pattern';

  /// Type discriminator value for [Source.artifact].
  static const String artifactType = 'artifact';

  /// Type discriminator value for [Source.hostArtifact].
  static const String hostArtifactType = 'host_artifact';

  /// Visit the particular source type.
  void accept(SourceVisitor visitor);

  /// Whether the output source provided can be known before executing the rule.
  bool get implicit;

  /// Serializes the source to a JSON-serializable map.
  Map<String, Object?> toMap();
}

@immutable
class _PatternSource extends Source {
  const _PatternSource(this.value, {this.optional = false});

  final String value;
  final bool optional;

  @override
  void accept(SourceVisitor visitor) => visitor.visitPattern(value, optional);

  @override
  bool get implicit => value.contains('*');

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    Source.typeKey: Source.patternType,
    Source.valueKey: value,
    Source.optionalKey: optional,
  };

  @override
  String toString() => 'Source.pattern($value, optional: $optional)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _PatternSource && other.value == value && other.optional == optional);

  @override
  int get hashCode => Object.hash(value, optional);
}

@immutable
class _ArtifactSource extends Source {
  const _ArtifactSource(this.artifact, {this.mode, this.platform});

  final Artifact artifact;
  final BuildMode? mode;
  final String? platform;

  @override
  void accept(SourceVisitor visitor) => visitor.visitArtifact(artifact, platform, mode);

  @override
  bool get implicit => false;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    Source.typeKey: Source.artifactType,
    Source.artifactKey: artifact.name,
    Source.platformKey: ?platform,
    Source.modeKey: ?mode?.cliName,
  };

  @override
  String toString() => 'Source.artifact($artifact, mode: $mode, platform: $platform)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ArtifactSource &&
          other.artifact == artifact &&
          other.platform == platform &&
          other.mode == mode);

  @override
  int get hashCode => Object.hash(artifact, platform, mode);
}

@immutable
class _HostArtifactSource extends Source {
  const _HostArtifactSource(this.artifact);

  final HostArtifact artifact;

  @override
  void accept(SourceVisitor visitor) => visitor.visitHostArtifact(artifact);

  @override
  bool get implicit => false;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    Source.typeKey: Source.hostArtifactType,
    Source.artifactKey: artifact.name,
  };

  @override
  String toString() => 'Source.hostArtifact($artifact)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _HostArtifactSource && other.artifact == artifact);

  @override
  int get hashCode => artifact.hashCode;
}
