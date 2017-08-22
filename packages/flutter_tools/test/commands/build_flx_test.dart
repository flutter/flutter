// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:test/test.dart';
import '../src/context.dart';


void main() {
  group('build snapshot', () {
    Directory temp;
    Directory projectDir;

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_build_flx');
      projectDir = temp.childDirectory('flutter_project');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    testUsingContext('rebuilds if target changes', () async {
      final String flutterPath = fs.path.absolute(fs.path.join('..', '..', 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter'));
      await runAsync(<String>[flutterPath, 'create', projectDir.path], allowReentrantFlutter: true);
      final String main = fs.path.join(projectDir.path, 'lib', 'main.dart');
      final String blue = fs.path.join(projectDir.path, 'lib', 'blue.dart');
      final String red = fs.path.join(projectDir.path, 'lib', 'red.dart');
      final String snapshot = fs.path.join(projectDir.path, 'build', 'snapshot_blob.bin');
      fs.file(main).renameSync(blue);
      fs.file(blue).copySync(red);
      fs.file(red).writeAsStringSync(fs.file(red).readAsStringSync().replaceFirst('Colors.blue', 'Colors.red'));
      runSync(<String>[flutterPath, 'build', 'flx', '--target', 'lib/blue.dart'], workingDirectory: projectDir.path, allowReentrantFlutter: true);
      final DateTime timestampBlue = fs.file(snapshot).statSync().changed;
      runSync(<String>[flutterPath, 'build', 'flx', '--target', 'lib/red.dart'], workingDirectory: projectDir.path, allowReentrantFlutter: true);
      final DateTime timestampRed = fs.file(snapshot).statSync().changed;
      expect(timestampBlue == timestampRed, isFalse);
    });
  });
}