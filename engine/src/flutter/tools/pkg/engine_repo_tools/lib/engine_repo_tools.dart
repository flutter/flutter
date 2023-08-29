// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A minimal library for discovering and probing a local engine repository.
///
/// This library is intended to be used by tools that need to interact with a
/// local engine repository, such as `clang_tidy` or `githooks`. For example,
/// finding the `compile_commands.json` file for the most recently built output:
///
/// ```dart
/// final Engine engine = Engine.findWithin();
/// final Output? output = engine.latestOutput();
/// if (output == null) {
///   print('No output targets found.');
/// } else {
///   final io.File? compileCommandsJson = output.compileCommandsJson;
///   if (compileCommandsJson == null) {
///     print('No compile_commands.json file found.');
///   } else {
///     print('Found compile_commands.json file at ${compileCommandsJson.path}');
///   }
/// }
/// ```
library;

import 'dart:io' as io;

import 'package:path/path.dart' as p;

/// Represents the `$ENGINE` directory (i.e. a checked-out Flutter engine).
///
/// If you have a path to the `$ENGINE/src` directory, use [Engine.fromSrcPath].
///
/// If you have a path to a directory within the `$ENGINE/src` directory, or
/// want to use the current working directory, use [Engine.findWithin].
final class Engine {
  /// Creates an [Engine] from a path such as `/Users/.../flutter/engine/src`.
  ///
  /// ```dart
  /// final Engine engine = Engine.findWithin('/Users/.../engine/src');
  /// print(engine.srcDir.path); // /Users/.../engine/src
  /// ```
  ///
  /// Throws a [InvalidEngineException] if the path is not a valid engine root.
  factory Engine.fromSrcPath(String srcPath) {
    // If the path does not end in `/src`, fail.
    if (p.basename(srcPath) != 'src') {
      throw InvalidEngineException.doesNotEndWithSrc(srcPath);
    }

    // If the directory does not exist, or is not a directory, fail.
    final io.Directory srcDir = io.Directory(srcPath);
    if (!srcDir.existsSync()) {
      throw InvalidEngineException.notADirectory(srcPath);
    }

    // Check for the existence of a `flutter` directory within `src`.
    final io.Directory flutterDir = io.Directory(p.join(srcPath, 'flutter'));
    if (!flutterDir.existsSync()) {
      throw InvalidEngineException.missingFlutterDirectory(srcPath);
    }

    // We do **NOT** check for the existence of a `out` directory within `src`,
    // it's not required to exist (i.e. a new checkout of the engine), and we
    // don't want to fail if it doesn't exist.
    final io.Directory outDir = io.Directory(p.join(srcPath, 'out'));

    return Engine._(srcDir, flutterDir, outDir);
  }

  /// Creates an [Engine] by looking for a `src/` directory in the given path.
  ///
  /// ```dart
  /// // Use the current working directory.
  /// final Engine engine = Engine.findWithin();
  /// print(engine.srcDir.path); // /Users/.../engine/src
  ///
  /// // Use a specific directory.
  /// final Engine engine = Engine.findWithin('/Users/.../engine/src/foo/bar/baz');
  /// print(engine.srcDir.path); // /Users/.../engine/src
  /// ```
  ///
  /// If a path is not provided, the current working directory is used.
  ///
  /// Throws a [StateError] if the path is not within a valid engine.
  factory Engine.findWithin([String? path]) {
    path ??= p.current;

    // Search parent directories for a `src` directory.
    io.Directory maybeSrcDir = io.Directory(path);

    if (!maybeSrcDir.existsSync()) {
      throw StateError(
        'The path "$path" does not exist or is not a directory.'
      );
    }

    do {
      try {
        return Engine.fromSrcPath(maybeSrcDir.path);
      } on InvalidEngineException {
        // Ignore, we'll keep searching.
      }
      maybeSrcDir = maybeSrcDir.parent;
    } while (maybeSrcDir.parent.path != maybeSrcDir.path /* at root */);

    throw StateError(
      'The path "$path" is not within a Flutter engine source directory.'
    );
  }

  const Engine._(
    this.srcDir,
    this.flutterDir,
    this.outDir,
  );

  /// The path to the `$ENGINE/src` directory.
  final io.Directory srcDir;

  /// The path to the `$ENGINE/src/flutter` directory.
  final io.Directory flutterDir;

  /// The path to the `$ENGINE/src/out` directory.
  ///
  /// **NOTE**: This directory may not exist.
  final io.Directory outDir;

  /// Returns a list of all output targets in [outDir].
  List<Output> outputs() {
    return outDir
      .listSync()
      .whereType<io.Directory>()
      .map<Output>(Output._)
      .toList();
  }

  /// Returns the most recently modified output target in [outDir].
  ///
  /// If there are no output targets, returns `null`.
  Output? latestOutput() {
    final List<Output> outputs = this.outputs();
    if (outputs.isEmpty) {
      return null;
    }
    outputs.sort((Output a, Output b) {
      return b.dir.statSync().modified.compareTo(a.dir.statSync().modified);
    });
    return outputs.first;
  }
}

/// Thrown when an [Engine] could not be created from a path.
sealed class InvalidEngineException implements Exception {
  /// Thrown when an [Engine] was created from a path not ending in `src`.
  factory InvalidEngineException.doesNotEndWithSrc(String path) {
    return InvalidEngineSrcPathException._(path);
  }

  /// Thrown when an [Engine] was created from a directory that does not exist.
  factory InvalidEngineException.notADirectory(String path) {
    return InvalidEngineNotADirectoryException._(path);
  }

  /// Thrown when an [Engine] was created from a path not containing `flutter/`.
  factory InvalidEngineException.missingFlutterDirectory(String path) {
    return InvalidEngineMissingFlutterDirectoryException._(path);
  }
}

/// Thrown when an [Engine] was created from a path not ending in `src`.
final class InvalidEngineSrcPathException implements InvalidEngineException {
  InvalidEngineSrcPathException._(this.path);

  /// The path that was used to create the [Engine].
  final String path;

  @override
  String toString() {
    return 'The path $path does not end in `${p.separator}src`.';
  }
}

/// Thrown when an [Engine] was created from a path that is not a directory.
final class InvalidEngineNotADirectoryException implements InvalidEngineException {
  InvalidEngineNotADirectoryException._(this.path);

  /// The path that was used to create the [Engine].
  final String path;

  @override
  String toString() {
    return 'The path "$path" does not exist or is not a directory.';
  }
}

/// Thrown when an [Engine] was created from a path not containing `flutter/`.
final class InvalidEngineMissingFlutterDirectoryException implements InvalidEngineException {
  InvalidEngineMissingFlutterDirectoryException._(this.path);

  /// The path that was used to create the [Engine].
  final String path;

  @override
  String toString() {
    return 'The path "$path" does not contain a "flutter" directory.';
  }
}

/// Represents a single output target in the `$ENGINE/src/out` directory.
final class Output {
  const Output._(this.dir);

  /// The directory containing the output target.
  final io.Directory dir;

  /// The `compile_commands.json` file for this output target.
  ///
  /// Returns `null` if the file does not exist.
  io.File? get compileCommandsJson {
    final io.File file = io.File(p.join(dir.path, 'compile_commands.json'));
    if (!file.existsSync()) {
      return null;
    }
    return file;
  }
}
