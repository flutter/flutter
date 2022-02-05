// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(seconds: 600))

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../../src/common.dart';
import '../test_utils.dart';
import 'project.dart';


class MigrateProject extends Project {
  MigrateProject(this.version);

  @override
  Future<void> setUpIn(Directory dir, {
    bool useDeferredLoading = false,
    bool useSyntheticPackage = false,
  }) async {
    this.dir = dir;
    if (androidLocalProperties != null) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'local.properties'), androidLocalProperties);
    }
    _appPath = fileSystem.path.join(getFlutterRoot(), 'packages', 'flutter_tools', 'test', 'integration.shard', 'test_data', 'full_apps', version);
    final ProcessResult result = await processManager.run(<String>[
      'cp',
      '-r',
      _appPath + fileSystem.path.separator,
      dir.path,
    ], workingDirectory: dir.path);
    return super.setUpIn(dir);
  }

  final String version;
  late String _appPath;

  // Maintain the same pubspec as the configured app.
  @override
  String get pubspec => fileSystem.file(fileSystem.path.join(_appPath, 'pubspec.yaml')).readAsStringSync();

  String get androidLocalProperties => '''
  flutter.sdk=${getFlutterRoot()}
  ''';
}
