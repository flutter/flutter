// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';

import '../../../src/common.dart';
import '../../../src/testbed.dart';

void main() {
  const BuildSystem buildSystem = BuildSystem();
  Environment environment;
  Testbed testbed;

  setUp(() {
    testbed = Testbed(setup: () {
      environment = Environment(
        outputDir: fs.currentDirectory,
        projectDir: fs.currentDirectory,
      );
      fs.file(fs.path.join('packages', 'flutter_tools', 'lib', 'src',
          'build_system', 'targets', 'assets.dart'))
        ..createSync(recursive: true);
      fs.file(fs.path.join('assets', 'foo', 'bar.png'))
        ..createSync(recursive: true);
      fs.file('.packages')
        ..createSync();
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: example

flutter:
  assets:
    - assets/foo/bar.png
''');
    });
  });

  test('Copies files to correct asset directory', () => testbed.run(() async {
    await buildSystem.build(const CopyAssets(), environment);

    expect(fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', 'AssetManifest.json')).existsSync(), true);
    expect(fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', 'FontManifest.json')).existsSync(), true);
    expect(fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', 'LICENSE')).existsSync(), true);
    // See https://github.com/flutter/flutter/issues/35293
    expect(fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', 'assets/foo/bar.png')).existsSync(), true);
  }));

  test('Does not leave stale files in build directory', () => testbed.run(() async {
    await buildSystem.build(const CopyAssets(), environment);

    expect(fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', 'assets/foo/bar.png')).existsSync(), true);
    // Modify manifest to remove asset.
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example

flutter:
''');
    await buildSystem.build(const CopyAssets(), environment);

    // See https://github.com/flutter/flutter/issues/35293
    expect(fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', 'assets/foo/bar.png')).existsSync(), false);
  }));

  test('FlutterPlugins updates required files as needed', () => testbed.run(() async {
    fs.file('pubspec.yaml')
      ..writeAsStringSync('name: foo\ndependencies:\n  foo: any\n');

    await const FlutterPlugins().build(Environment(
      outputDir: fs.currentDirectory,
      projectDir: fs.currentDirectory,
    ));

    expect(fs.file('.flutter-plugins').existsSync(), true);
  }));
}
