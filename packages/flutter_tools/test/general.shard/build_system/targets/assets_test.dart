// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../../src/common.dart';
import '../../../src/testbed.dart';

void main() {
  const BuildSystem buildSystem = BuildSystem();
  Environment environment;
  Testbed testbed;

  setUp(() {
    testbed = Testbed(setup: () {
      environment = Environment(
        outputDir: globals.fs.currentDirectory,
        projectDir: globals.fs.currentDirectory,
      );
      globals.fs.file(globals.fs.path.join('packages', 'flutter_tools', 'lib', 'src',
          'build_system', 'targets', 'assets.dart'))
        ..createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.png'))
        ..createSync(recursive: true);
      globals.fs.file('.packages')
        ..createSync();
      globals.fs.file('pubspec.yaml')
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

    expect(globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'flutter_assets', 'AssetManifest.json')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'flutter_assets', 'FontManifest.json')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'flutter_assets', 'LICENSE')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'flutter_assets', 'assets', 'foo', 'bar.png')).existsSync(), true);
  }));

  test('Does not leave stale files in build directory', () => testbed.run(() async {
    await buildSystem.build(const CopyAssets(), environment);
    final File assetFile = globals.fs.file(globals.fs.path.join(environment.buildDir.path, 'flutter_assets', 'assets', 'foo', 'bar.png'));

    expect(assetFile.existsSync(), true);
    // Modify manifest to remove asset.
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example

flutter:
''');
    await buildSystem.build(const CopyAssets(), environment);

    expect(assetFile.existsSync(), false);
  }));

  test('FlutterPlugins updates required files as needed', () => testbed.run(() async {
    globals.fs.file('pubspec.yaml')
      ..writeAsStringSync('name: foo\ndependencies:\n  foo: any\n');

    await const FlutterPlugins().build(Environment(
      outputDir: globals.fs.currentDirectory,
      projectDir: globals.fs.currentDirectory,
    ));

    expect(globals.fs.file('.flutter-plugins').existsSync(), true);
  }));
}
