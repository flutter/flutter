// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Relative path to the asset graph from the root package dir.
final String assetGraphPath = assetGraphPathFor(_scriptPath);

/// Relative path to the asset graph for a build script at [path]
String assetGraphPathFor(String path) =>
    '$cacheDir/${_scriptHashFor(path)}/asset_graph.json';

/// Relative path to the directory which holds serialized versions of errors
/// reported during previous builds.
final errorCachePath =
    p.join(cacheDir, _scriptHashFor(_scriptPath), 'error_cache');

final String _scriptPath = Platform.script.scheme == 'file'
    ? p.url.joinAll(
        p.split(p.relative(Platform.script.toFilePath(), from: p.current)))
    : Platform.script.path;

/// Directory containing automatically generated build entrypoints.
///
/// Files in this directory must be read to do build script invalidation.
const entryPointDir = '$cacheDir/entrypoint';

/// The directory to which hidden assets will be written.
String get generatedOutputDirectory => '$cacheDir/$_generatedOutputDirectory';

/// Locks the generated directory name for the duration of this process.
///
/// This should be invoked before any builds start.
void lockGeneratedOutputDirectory() => _generatedOutputDirectoryIsLocked = true;

/// The default generated dir name. Can be modified with
/// [overrideGeneratedOutputDirectory].
String _generatedOutputDirectory = 'generated';

/// Whether or not the [generatedOutputDirectory] is locked. This must be `true`
/// before you can access [generatedOutputDirectory];
bool _generatedOutputDirectoryIsLocked = false;

/// Overrides the generated directory name.
///
/// This is interpreted as a relative path under the [cacheDir].
void overrideGeneratedOutputDirectory(String path) {
  if (_generatedOutputDirectory != 'generated') {
    throw StateError('You can only override the generated dir once.');
  } else if (_generatedOutputDirectoryIsLocked) {
    throw StateError(
        'Attempted to override the generated dir after it was locked.');
  } else if (!p.isRelative(path)) {
    throw StateError('Only relative paths are accepted for the generated dir '
        'but got `$path`.');
  }
  _generatedOutputDirectory = path;
}

/// Relative path to the cache directory from the root package dir.
const String cacheDir = '.dart_tool/build';

/// Returns a hash for a given Dart script path.
///
/// Normalizes between snapshot and Dart source file paths so they give the same
/// hash.
String _scriptHashFor(String path) => md5
    .convert(utf8.encode(
        path.endsWith('.snapshot') ? path.substring(0, path.length - 9) : path))
    .toString();

/// The name of the pub binary on the current platform.
final pubBinary = p.join(sdkBin, Platform.isWindows ? 'pub.bat' : 'pub');

/// The path to the sdk bin directory on the current platform.
final sdkBin = p.join(sdkPath, 'bin');

/// The path to the sdk on the current platform.
final sdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));

/// The maximum number of concurrent actions to run per build phase.
const buildPhasePoolSize = 16;
