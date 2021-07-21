// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../../bin/xcode_backend.dart';
import '../src/common.dart';

void main() {
  late MemoryFileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem();
  });

  group('build', () {
    test('able to build', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds')..createSync(recursive: true);
      final Directory flutterRoot = fileSystem.directory('/path/to/flutter')..createSync(recursive: true);
      final TestContext context = TestContext(
        <String>['build'],
        <String, String>{
          'CONFIGURATION': 'Debug',
          'BUILT_PRODUCTS_DIR': buildDir.path,
          'INFOPLIST_PATH': 'Info.plist',
          'FLUTTER_ROOT': flutterRoot.path,
        },
        fileSystem: fileSystem,
      )..run();
      expect(
        context.stdout,
        contains('Info.plist does not exist. Skipping _dartobservatory._tcp NSBonjourServices insertion.'),
      );
    });
  });

  group('test_observatory_bonjour_service', () {
    test('handles when the Info.plist is missing', () {
      final Directory buildDir = fileSystem.directory('/path/to/builds');
      buildDir.createSync(recursive: true);
      final TestContext context = TestContext(
          <String>['test_observatory_bonjour_service'],
          <String, String>{
            'CONFIGURATION': 'Debug',
            'BUILT_PRODUCTS_DIR': buildDir.path,
            'INFOPLIST_PATH': 'Info.plist',
          },
          fileSystem: fileSystem,
      )..run();
      expect(
          context.stdout,
          contains('Info.plist does not exist. Skipping _dartobservatory._tcp NSBonjourServices insertion.'),
      );
    });

  });
}

class TestContext extends Context {
  TestContext(
    List<String> arguments,
    Map<String, String> environment, {
    required this.fileSystem,
  }) : super(arguments: arguments, environment: environment);

  final FileSystem fileSystem;

  String stdout = '';
  String stderr = '';

  @override
  bool existsDir(String path) {
    return fileSystem.directory(path).existsSync();
  }

  @override
  bool existsFile(String path) {
    return fileSystem.file(path).existsSync();
  }

  @override
  ProcessResult runSync(
    String bin,
    List<String> args, {
    bool verbose = false,
    bool allowFail = false,
    String? workingDirectory,
  }) {
    throw Exception('Unimplemented!');
  }

  @override
  void echoError(String message) {
    stderr += '$message\n';
  }

  @override
  void echo(String message) {
    stdout += '$message\n';
  }

  @override
  Never exitApp(int code) {
    throw Exception('App exited with code $code');
  }
}
