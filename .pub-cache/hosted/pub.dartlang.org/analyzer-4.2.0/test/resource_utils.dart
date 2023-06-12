// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

bool get isWindows => path.Style.platform == path.Style.windows;

/// Assert that the given path is posix and absolute.
void expectAbsolutePosixPath(String posixPath) {
  expect(posixPath, startsWith('/'),
      reason: 'Expected absolute posix path, but found $posixPath');
}

/// Assert that the given path is posix.
void expectPosixPath(String posixPath) {
  expect(posixPath.indexOf('\\'), -1,
      reason: 'Expected posix path, but found $posixPath');
}

/// Translate the given posixPath to a file URI appropriate for the
/// platform on which the tests are executing.
String posixToOSFileUri(String posixPath) {
  expectPosixPath(posixPath);
  return isWindows ? 'file:///C:$posixPath' : 'file://$posixPath';
}

/// Translate the given posixPath to a path appropriate for the
/// platform on which the tests are executing.
String posixToOSPath(String posixPath) {
  expectPosixPath(posixPath);
  if (isWindows) {
    String windowsPath = posixPath.replaceAll('/', '\\');
    if (posixPath.startsWith('/')) {
      return 'C:$windowsPath';
    }
    return windowsPath;
  }
  return posixPath;
}

/// A convenience utility for setting up a test [MemoryResourceProvider].
/// All supplied paths are assumed to be in [path.posix] format
/// and are automatically translated to [path.context].
///
/// This class intentionally does not implement [ResourceProvider]
/// directly or indirectly so that it cannot be used as a resource provider.
/// We do not want functionality under test to interact with a resource provider
/// that automatically translates paths.
class TestPathTranslator {
  final MemoryResourceProvider _provider;

  TestPathTranslator(this._provider);

  Resource getResource(String posixPath) =>
      _provider.getResource(posixToOSPath(posixPath));

  File newFile(String posixPath, String content) =>
      _provider.newFile(posixToOSPath(posixPath), content);

  File newFileWithBytes(String posixPath, Uint8List bytes) =>
      _provider.newFileWithBytes(posixToOSPath(posixPath), bytes);

  Folder newFolder(String posixPath) =>
      _provider.newFolder(posixToOSPath(posixPath));
}

/// A resource provider for testing that asserts that any supplied paths
/// are appropriate for the OS platform on which the tests are running.
class TestResourceProvider implements ResourceProvider {
  final ResourceProvider _provider;

  TestResourceProvider(this._provider);

  @override
  path.Context get pathContext => _provider.pathContext;

  @override
  File getFile(String path) => _provider.getFile(_assertPath(path));

  @override
  Folder getFolder(String path) => _provider.getFolder(_assertPath(path));

  @override
  Resource getResource(String path) => _provider.getResource(_assertPath(path));

  @override
  Folder getStateLocation(String pluginId) =>
      _provider.getStateLocation(pluginId)!;

  /// Assert that the given path is valid for the OS platform on which the
  /// tests are running.
  String _assertPath(String path) {
    if (isWindows) {
      if (path.contains('/')) {
        fail('Expected windows path, but found: $path');
      }
    } else {
      if (path.contains('\\')) {
        fail('Expected posix path, but found: $path');
      }
    }
    return path;
  }
}
