// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// An input function produces a list of additional input files for an
/// [Environment].
typedef InputFunction = List<SourceFile> Function(Environment environment);

/// A wrapped for a [FileSystemEntity] that abstracts version logic.
class SourceFile {
  const SourceFile(this._fileSystemEntity, [this._versionFile]);

  final FileSystemEntity _fileSystemEntity;
  final File _versionFile;

  /// Whether the source exists on disk.
  bool existsSync() => _fileSystemEntity.existsSync();

  /// The path to the file or directory.
  String get path => _fileSystemEntity.resolveSymbolicLinksSync();

  /// The unresolved path to the file or directory.
  String get unresolvedPath => _fileSystemEntity.path;

  /// Return the bytes used to compute a version hash for the file.
  List<int> bytesForVersion() {
    if (_versionFile != null) {
      return _versionFile.readAsBytesSync();
    }
    if (_fileSystemEntity is File) {
      final File file = _fileSystemEntity;
      return file.readAsBytesSync();
    }
    return _fileSystemEntity.statSync().modified.toIso8601String().codeUnits;
  }
}

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
  final List<SourceFile> sources = <SourceFile>[];

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
    final bool isDirectory = pattern.endsWith('/');
    if (hasWildcard && isDirectory) {
      throw Exception('wildcard patterns are not supported with directories.');
    }
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
        segments.addAll(
            fs.path.split(environment.cacheDir.resolveSymbolicLinksSync()));
        break;
      default:
        throw InvalidPatternException(pattern);
    }
    rawParts.skip(1).forEach(segments.add);
    final String filePath = fs.path.joinAll(segments);
    if (isDirectory) {
      sources.add(SourceFile(fs.directory(fs.path.normalize(filePath))));
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
        throw Exception('$filePath does not exist!');
      }
      for (FileSystemEntity entity in fs.directory(filePath).listSync()) {
        final String filename = fs.path.basename(entity.path);
        if (segments.isEmpty) {
          sources.add(SourceFile(entity.absolute));
        } else if (segments.length == 1) {
          if (filename.startsWith(segments[0]) ||
              filename.endsWith(segments[0])) {
            sources.add(SourceFile(entity.absolute));
          }
        } else if (filename.startsWith(segments[0])) {
          if (filename.substring(segments[0].length).endsWith(segments[1])) {
            sources.add(SourceFile(entity.absolute));
          }
        }
      }
    } else {
      sources.add(SourceFile(fs.file(fs.path.normalize(filePath))));
    }
  }

  /// Visit a [Source] which contains a [SourceBehavior].
  void visitBehavior(SourceBehavior sourceBehavior) {
    if (inputs) {
      sources.addAll(
          sourceBehavior.inputs(environment).map((FileSystemEntity entity) {
        return SourceFile(entity);
      }));
    } else {
      sources.addAll(
          sourceBehavior.outputs(environment).map((FileSystemEntity entity) {
        return SourceFile(entity);
      }));
    }
  }

  /// Visit a [Source] which has a separate version file.
  // TODO(jonahwilliams): implement correctly with tool depenendencies.
  void visitVersion(String pattern, String version) {}
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

  /// This source is versioned via a separate vile.
  const factory Source.version(String pattern, {@required String version}) =
      _VersionSource;

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

class _VersionSource implements Source {
  const _VersionSource(this.value, {@required this.version});

  final String value;
  final String version;

  @override
  void accept(SourceVisitor visitor) => visitor.visitVersion(value, version);
}
