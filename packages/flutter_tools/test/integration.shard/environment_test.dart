// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/migrate_project.dart';
import 'test_utils.dart';

void main() {
  late Directory projectDir;

  setUpAll(() async {
    projectDir = createResolvedTempDirectorySync('run_test.');
    final MigrateProject migrateProject = MigrateProject('version:1.22.6_stable');
    await migrateProject.setUpIn(projectDir);
  });

  tearDown(() async {
    tryToDelete(projectDir);
  });

  testUsingContext('environment produces expected values', () async {
    final ProcessResult result = await globals.processManager.run(<String>['flutter', 'environment'], workingDirectory: projectDir.path);

    expect(result.stdout is String, true);
    expect((result.stdout as String).startsWith('{'), true);
    expect(result.stdout, contains('"FlutterProject.directory": "')); // We dont verify path as it is a temp path that changes
    expect(result.stdout, contains('"FlutterProject.metadataFile": "')); // We dont verify path as it is a temp path that changes
    expect(result.stdout, contains('"FlutterProject.android.exists": true,'));
    expect(result.stdout, contains('"FlutterProject.ios.exists": true,'));
    expect(result.stdout, contains('"FlutterProject.web.exists": false,'));
    expect(result.stdout, contains('"FlutterProject.macos.exists": false,'));
    expect(result.stdout, contains('"FlutterProject.linux.exists": false,'));
    expect(result.stdout, contains('"FlutterProject.windows.exists": false,'));
    expect(result.stdout, contains('"FlutterProject.fuchsia.exists": false,'));
    expect(result.stdout, contains('"FlutterProject.android.isKotlin": true,'));
    expect(result.stdout, contains('"FlutterProject.ios.isSwift": true,'));
    expect(result.stdout, contains('"FlutterProject.isModule": false,'));
    expect(result.stdout, contains('"FlutterProject.isPlugin": false,'));
    expect(result.stdout, contains('"FlutterProject.manifest.appname": "vanilla_app_1_22_6_stable",'));
    expect(result.stdout, contains('"FlutterVersion.frameworkRevision": "",'));
    expect(result.stdout, contains('"Platform.operatingSystem": "macos",'));
    expect(result.stdout, contains('"Platform.isAndroid": false,'));
    expect(result.stdout, contains('"Platform.isIOS": false,'));
    expect(result.stdout, contains('"Platform.isWindows": false,'));
    expect(result.stdout, contains('"Platform.isMacOS": true,'));
    expect(result.stdout, contains('"Platform.isFuchsia": false,'));
    expect(result.stdout, contains('"Platform.pathSeparator": "/",'));
    expect(result.stdout, contains('"Cache.flutterRoot": "'));  // We dont verify path as it is a temp path that changes
    expect((result.stdout as String).endsWith('}\n'), true);
  }, overrides: <Type, Generator>{});
}
