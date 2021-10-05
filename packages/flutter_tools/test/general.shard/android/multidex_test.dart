// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/multidex.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {

  testUsingContext('ensureMultidexUtilsExists returns when exists', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File utilsFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('java')
      .childDirectory('io')
      .childDirectory('flutter')
      .childDirectory('app')
      .childFile('FlutterMultidexSupportUtils.java');
    utilsFile.createSync(recursive: true);
    utilsFile.writeAsStringSync('hello', flush: true);
    expect(utilsFile.readAsStringSync(), 'hello');

    ensureMultidexUtilsExists(directory);

    // File should remain untouched
    expect(utilsFile.readAsStringSync(), 'hello');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ensureMultidexUtilsExists generates when does not exist', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File utilsFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('java')
      .childDirectory('io')
      .childDirectory('flutter')
      .childDirectory('app')
      .childFile('FlutterMultidexSupportUtils.java');

    ensureMultidexUtilsExists(directory);

    expect(utilsFile.readAsStringSync().contains('FlutterMultidexSupportUtils'), true);
    expect(utilsFile.readAsStringSync().contains('public static void installMultidexSupport(Context context)'), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('multidexUtilsExists false when does not exist', () async {
    final Directory directory = globals.fs.currentDirectory;
    expect(multidexUtilsExists(directory), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ensureMultidexUtilsExists true when does exist', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File utilsFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('java')
      .childDirectory('io')
      .childDirectory('flutter')
      .childDirectory('app')
      .childFile('FlutterMultidexSupportUtils.java');
    utilsFile.createSync(recursive: true);

    expect(multidexUtilsExists(directory), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}
