// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';

import 'common.dart';

/// A Flutter source tree.
///
/// See also:
/// * [hostFlutterTree], an instance of this class representing
///   the Flutter source tree that the running program is part of.
/// * [TestFlutterTree], a subclass providing a temporary Flutter tree
///   which can be freely mutated for testing.
class FlutterTree {
  FlutterTree(this.root) : assert(root.isAbsolute);

  /// The root of the tree.
  ///
  /// This must be absolute.
  final Directory root;

  // When adding more file and subdirectory getters,
  // include their full relative paths as comments.
  // This helps make them discoverable as references to these files/directories.

  Directory get binDir => root.childDirectory('bin'); // bin/
  File get binDart => binDir.childFile('dart'); // bin/dart
  File get binFlutter => binDir.childFile('flutter'); // bin/flutter

  Directory get binInternalDir => binDir.childDirectory('internal'); // bin/internal/
  File get engineVersionFile => binInternalDir.childFile('engine.version'); // bin/internal/engine.version

  Directory get examplesDir => root.childDirectory('examples'); // examples/
  Directory get helloWorldDir => examplesDir.childDirectory('hello_world'); // examples/hello_world/

  Directory get packagesDir => root.childDirectory('packages'); // packages/
  Directory get frameworkDir => packagesDir.childDirectory('flutter'); // packages/flutter/
  Directory get toolsPackageDir => packagesDir.childDirectory('flutter_tools'); // packages/flutter_tools/
}

/// The Flutter source tree that this program is part of.
///
/// The tree is the one located by [getFlutterRoot].
final FlutterTree hostFlutterTree = FlutterTree(
  const LocalFileSystem().directory(getFlutterRoot()).absolute);
