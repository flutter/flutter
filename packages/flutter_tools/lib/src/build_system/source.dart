// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// An input function produces a list of additional input files for an
/// [Environment].
typedef InputFunction = List<File> Function(Environment environment);

/// Collects sources for a [Target] into a single list of [FileSystemEntities].
class SourceVisitor {
  /// Create a new [SourceVisitor] from an [Environment].
  SourceVisitor(this.environment, [this.inputs = true]);

  /// The current environment.
  final Environment environment;

  /// Whether we are visiting inputs or outputs.
  ///
  /// Defaults to `true`.
  final bool inputs;

  /// The entities are populated after visiting each source.
  final List<File> sources = <File>[];

  /// Visit a [Source] which contains a function.
  ///
  /// The function is expected to produce a list of [FileSystemEntities]s.
  void visitFunction(InputFunction function) {
    sources.addAll(function(environment));
  }

  /// Visit a [Source] which contains a file uri.
  ///
  /// The uri may that may include constants defined in an [Environment].
  void visitPattern(String pattern) {
    // perform substitution of the environmental values and then
    // of the local values.
    final List<String> segments = <String>[];
    final List<String> rawParts = pattern.split('/');
    final bool hasWildcard = rawParts.last.contains('*');
    String wildcardFile;
    if (hasWildcard) {
      wildcardFile = rawParts.removeLast();
    }
    // If the pattern does not start with an env variable, then we have nothing
    // to resolve it to, error out.
    switch (rawParts.first) {
      case Environment.kProjectDirectory:
        segments.addAll(
            fs.path.split(environment.projectDir.resolveSymbolicLinksSync()));
        break;
      case Environment.kBuildDirectory:
        segments.addAll(fs.path.split(
            environment.buildDir.resolveSymbolicLinksSync()));
        break;
      case Environment.kCacheDirectory:
        segments.addAll(
            fs.path.split(environment.cacheDir.resolveSymbolicLinksSync()));
        break;
      case Environment.kFlutterRootDirectory:
        // flutter root will not contain a symbolic link.
        segments.addAll(
            fs.path.split(environment.flutterRootDir.absolute.path));
        break;
      default:
        throw InvalidPatternException(pattern);
    }
    rawParts.skip(1).forEach(segments.add);
    final String filePath = fs.path.joinAll(segments);
    if (hasWildcard) {
      // Perform a simple match by splitting the wildcard containing file one
      // the `*`. For example, for `/*.dart`, we get [.dart]. We then check
      // that part of the file matches. If there are values before and after
      // the `*` we need to check that both match without overlapping. For
      // example, `foo_*_.dart`. We want to match `foo_b_.dart` but not
      // `foo_.dart`. To do so, we first subtract the first section from the
      // string if the first segment matches.
      final List<String> segments = wildcardFile.split('*');
      if (segments.length > 2) {
        throw InvalidPatternException(pattern);
      }
      if (!fs.directory(filePath).existsSync()) {
        throw Exception('$filePath does not exist!');
      }
      for (FileSystemEntity entity in fs.directory(filePath).listSync()) {
        final String filename = fs.path.basename(entity.path);
        if (segments.isEmpty) {
          sources.add(fs.file(entity.absolute));
        } else if (segments.length == 1) {
          if (filename.startsWith(segments[0]) ||
              filename.endsWith(segments[0])) {
            sources.add(entity.absolute);
          }
        } else if (filename.startsWith(segments[0])) {
          if (filename.substring(segments[0].length).endsWith(segments[1])) {
            sources.add(entity.absolute);
          }
        }
      }
    } else {
      sources.add(fs.file(fs.path.normalize(filePath)));
    }
  }

  /// Visit a [Source] which contains a [SourceBehavior].
  void visitBehavior(SourceBehavior sourceBehavior) {
    if (inputs) {
      sources.addAll(sourceBehavior.inputs(environment));
    } else {
      sources.addAll(sourceBehavior.outputs(environment));
    }
  }

  /// Visit a [Source] which is defined by an [Artifact] from the flutter cache.
  ///
  /// If the [Artifact] points to a directory then all child files are included.
  void visitArtifact(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String path = artifacts.getArtifactPath(artifact, platform: platform, mode: mode);
    if (fs.isDirectorySync(path)) {
      sources.addAll(<File>[
        for (FileSystemEntity entity in fs.directory(path).listSync(recursive: true))
          if (entity is File)
            entity
      ]);
    } else {
      sources.add(fs.file(path));
    }
  }
}

/// A description of an input or output of a [Target].
abstract class Source {
  /// This source is a file-uri which contains some references to magic
  /// environment variables.
  const factory Source.pattern(String pattern) = _PatternSource;

  /// This source is produced by invoking the provided function.
  const factory Source.function(InputFunction function) = _FunctionSource;

  /// This source is produced by the [SourceBehavior] class.
  const factory Source.behavior(SourceBehavior behavior) = _SourceBehavior;

  /// The source is provided by an [Artifact].
  ///
  /// If [artifact] points to a directory then all child files are included.
  const factory Source.artifact(Artifact artifact, {TargetPlatform platform,
      BuildMode mode}) = _ArtifactSource;

  /// Visit the particular source type.
  void accept(SourceVisitor visitor);

  /// Whether the output source provided can be known before executing the rule.
  ///
  /// This does not apply to inputs, which are always explicit and must be
  /// evaluated before the build.
  ///
  /// For example, [Source.pattern] and [Source.version] are not implicit
  /// provided they do not use any wildcards. [Source.behavior] and
  /// [Source.function] are always implicit.
  bool get implicit;
}

/// An interface for describing input and output copies together.
abstract class SourceBehavior {
  const SourceBehavior();

  /// The inputs for a particular target.
  List<File> inputs(Environment environment);

  /// The outputs for a particular target.
  List<File> outputs(Environment environment);
}

class _SourceBehavior implements Source {
  const _SourceBehavior(this.value);

  final SourceBehavior value;

  @override
  void accept(SourceVisitor visitor) => visitor.visitBehavior(value);

  @override
  bool get implicit => true;
}

class _FunctionSource implements Source {
  const _FunctionSource(this.value);

  final InputFunction value;

  @override
  void accept(SourceVisitor visitor) => visitor.visitFunction(value);

  @override
  bool get implicit => true;
}

class _PatternSource implements Source {
  const _PatternSource(this.value);

  final String value;

  @override
  void accept(SourceVisitor visitor) => visitor.visitPattern(value);

  @override
  bool get implicit => value.contains('*');
}

class _ArtifactSource implements Source {
  const _ArtifactSource(this.artifact, { this.platform, this.mode });

  final Artifact artifact;
  final TargetPlatform platform;
  final BuildMode mode;

  @override
  void accept(SourceVisitor visitor) => visitor.visitArtifact(artifact, platform, mode);

  @override
  bool get implicit => false;
}
