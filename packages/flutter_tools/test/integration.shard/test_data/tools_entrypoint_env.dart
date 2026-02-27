// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart';

/// Update `packages/flutter_tools/pubpsec.yaml` to be newer than `pubspec.lock`.
///
/// See also:
/// - [packagesFlutterToolsPubspecYaml]
/// - [packagesFlutterToolsPubspecLock]
void setupToolsEntrypointNewerPubpsec() {
  final now = DateTime.now();
  packagesFlutterToolsPubspecYaml.setLastModifiedSync(now);

  final DateTime before = now.subtract(const Duration(hours: 1));
  packagesFlutterToolsPubspecLock.setLastModifiedSync(before);
}

final Directory _flutterRoot = fileSystem.directory(getFlutterRoot());

File _packagesFlutterToolsPubspec(String extension) {
  return _flutterRoot
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childFile('pubspec.$extension');
}

/// `packages/flutter_tools/pubspec.yaml`.
File get packagesFlutterToolsPubspecYaml => _packagesFlutterToolsPubspec('yaml');

/// `packages/flutter_tools/pubspec.lock`.
File get packagesFlutterToolsPubspecLock => _packagesFlutterToolsPubspec('lock');
