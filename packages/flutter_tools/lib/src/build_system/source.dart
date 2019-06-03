// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../build_info.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// An input function produces a list of additional input files for an
/// environment.
typedef InputFunction = List<FileSystemEntity> Function(
    Environment environment);

/// Collects sources for a [Target] into a single list of [FileSystemEntities].
class SourceVisitor {
  /// Create a new [SourceVisitor] from an [Environment].
  SourceVisitor(this.environment, [this.inputs = true]);

  static const String _kProjectDirectory = '{PROJECT_DIR}';
  static const String _kBuildDirectory = '{BUILD_DIR}';
  static const String _kCacheDirectory = '{CACHE_DIR}';
  static const String _kPlatform = '{platform}';
  static const String _kMode = '{mode}';
  static const String _kFlavor = '{flavor}';

  /// The current environment.
  final Environment environment;

  /// Whether we are visiting inputs or outputs.
  ///
  /// Defaults to `true`.
  final bool inputs;

  /// The entities are populated after visiting each source.
  final List<FileSystemEntity> sources = <FileSystemEntity>[];

  /// Visit a source which contains a file uri with some magic environment
  /// variables.
  void visitFunction(InputFunction function) {
    sources.addAll(function(environment));
  }

  /// Visit a source which contains a function.
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
    final bool isDirectory = pattern.endsWith('/');
    // If the pattern does not start with an env variable, then we have nothing
    // to resolve it to, error out.
    switch (rawParts.first) {
      case _kProjectDirectory:
        segments.addAll(fs.path.split(environment.projectDir.absolute.path));
        break;
      case _kBuildDirectory:
        segments.addAll(fs.path.split(environment.buildDir.absolute.path));
        break;
      case _kCacheDirectory:
        segments.addAll(fs.path.split(environment.cacheDir.absolute.path));
        break;
      default:
        throw InvalidPatternException(pattern);
    }
    for (String rawPart in rawParts.skip(1)) {
      final String value = rawPart
          .replaceAll(_kMode, getNameForBuildMode(environment.buildMode))
          .replaceAll(_kPlatform, getNameForTargetPlatform(environment.targetPlatform))
          .replaceAll(_kFlavor, environment.flavor);
      segments.add(value);
    }
    final String filePath = fs.path.joinAll(segments);
    if (isDirectory) {
      sources.add(fs.directory(fs.path.normalize(filePath)));
    } else if (hasWildcard) {
      // Perform a simple match by splitting the wildcard containing file on
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
        print('$filePath does not exist!');
      }
      for (FileSystemEntity entity in fs.directory(filePath).listSync()) {
        final String filename = fs.path.basename(entity.path);
        if (segments.isEmpty) {
          sources.add(entity.absolute);
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

  /// Visit a source which contains a behavior delegate.
  void visitBehavior(SourceBehavior sourceBehavior) {
    if (inputs) {
      sources.addAll(sourceBehavior.inputs(environment));
    } else {
      sources.addAll(sourceBehavior.outputs(environment));
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

  /// Visit the particular source type.
  void accept(SourceVisitor visitor);
}

/// An interface for describing input and output copies together.
abstract class SourceBehavior {
  const SourceBehavior();

  /// The inputs for a particular target.
  List<FileSystemEntity> inputs(Environment environment);

  /// The outputs for a particular target.
  List<FileSystemEntity> outputs(Environment environment);
}

class _SourceBehavior implements Source {
  const _SourceBehavior(this.value);

  final SourceBehavior value;

  @override
  void accept(SourceVisitor visitor) => visitor.visitBehavior(value);
}

class _FunctionSource implements Source {
  const _FunctionSource(this.value);

  final InputFunction value;

  @override
  void accept(SourceVisitor visitor) => visitor.visitFunction(value);
}

class _PatternSource implements Source {
  const _PatternSource(this.value);

  final String value;

  @override
  void accept(SourceVisitor visitor) => visitor.visitPattern(value);
}
