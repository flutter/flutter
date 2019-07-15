// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/doctor.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('Create --plugin', () {
    Testbed testbed;
    String realFlutterRoot;
    MemoryFileSystem fileSystem;

    setUpAll(() {
      realFlutterRoot = getFlutterRoot();
      Cache.disableLocking();
      Cache.flutterRoot = 'flutter';
      // Load templates into memory a single time.
      fileSystem = populateTemplates('flutter', realFlutterRoot);
    });

    setUp(() {
      testbed = Testbed(setup: () {
        final List<String> paths = <String>[
          fs.path.join('flutter', 'packages', 'flutter', 'pubspec.yaml'),
          fs.path.join('flutter', 'packages', 'flutter_driver', 'pubspec.yaml'),
          fs.path.join('flutter', 'packages', 'flutter_test', 'pubspec.yaml'),
          fs.path.join('flutter', 'bin', 'cache', 'artifacts', 'gradle_wrapper', 'wrapper'),
          fs.path.join('usr', 'local', 'bin', 'adb'),
          fs.path.join('Android', 'platform-tools', 'adb.exe'),
        ];
        for (String path in paths) {
          fs.file(path).createSync(recursive: true);
        }
        populateTemplates('flutter', realFlutterRoot);
      }, overrides: <Type, Generator>{
        DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
        FileSystem: () => fileSystem,
      });
    });

    tearDown(() {
      if (fileSystem.directory('flutter_project').existsSync()) {
        fileSystem.directory('flutter_project').deleteSync(recursive: true);
      }
    });

    test('kotlin/swift plugin project', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'create',
        '--no-pub',
        '--suppress-analytics',
        '--flutter-root=flutter',
        '--template=plugin',
        '-a',
        'kotlin',
        '--ios-language',
        'swift',
        '--flutter-root=flutter',
        'flutter_project'
      ]);

      const List<String> expectedPaths = <String>[
        'android/src/main/kotlin/com/example/flutter_project/FlutterProjectPlugin.kt',
        'example/android/app/src/main/kotlin/com/example/flutter_project_example/MainActivity.kt',
        'example/ios/Runner/AppDelegate.swift',
        'example/ios/Runner/Runner-Bridging-Header.h',
        'example/lib/main.dart',
        'ios/Classes/FlutterProjectPlugin.h',
        'ios/Classes/FlutterProjectPlugin.m',
        'ios/Classes/SwiftFlutterProjectPlugin.swift',
        'lib/flutter_project.dart',
      ];
      const List<String> unexpectedPaths = <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
        'example/ios/Runner/AppDelegate.h',
        'example/ios/Runner/AppDelegate.m',
        'example/ios/Runner/main.m',
      ];
      for (String path in expectedPaths) {
        expect(fs.isFileSync(fs.path.join('flutter_project', path)), true);
      }
      for (String path in unexpectedPaths) {
        expect(fs.isFileSync(fs.path.join('flutter_project', path)), false);
      }
    }));

    test('plugin project with custom org', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'create',
        '--no-pub',
        '--suppress-analytics',
        '--flutter-root=flutter',
        '--template=plugin',
        '--org', 'com.bar.foo',
        'flutter_project'
      ]);
      const List<String> expectedPaths = <String>[
        'android/src/main/java/com/bar/foo/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/bar/foo/flutter_project_example/MainActivity.java',
      ];
      const List<String> unexpectedPaths = <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
      ];
      for (String path in expectedPaths) {
        expect(fs.isFileSync(fs.path.join('flutter_project', path)), true);
      }
      for (String path in unexpectedPaths) {
        expect(fs.isFileSync(fs.path.join('flutter_project', path)), false);
      }
    }));

    test('plugin project with valid custom project name', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'create',
        '--no-pub',
        '--suppress-analytics',
        '--flutter-root=flutter',
        '--template=plugin',
        '--project-name',
        'xyz',
        'flutter_project'
      ]);

      const List<String> expectedPaths = <String>[
        'android/src/main/java/com/example/xyz/XyzPlugin.java',
        'example/android/app/src/main/java/com/example/xyz_example/MainActivity.java',
      ];
      const List<String> unexpectedPaths = <String>[
        'android/src/main/java/com/example/flutter_project/FlutterProjectPlugin.java',
        'example/android/app/src/main/java/com/example/flutter_project_example/MainActivity.java',
      ];
      for (String path in expectedPaths) {
        expect(fs.isFileSync(fs.path.join('flutter_project', path)), true);
      }
      for (String path in unexpectedPaths) {
        expect(fs.isFileSync(fs.path.join('flutter_project', path)), false);
      }
    }));

    test('plugin project with invalid custom project name', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      final Future<void> runResult = runner.run(<String>[
        'create',
        '--no-pub',
        '--suppress-analytics',
        '--flutter-root=flutter',
        '--template=plugin',
        '--project-name',
        'xyz.xyz',
        'flutter_project'
      ]);

      expect(
        runResult,
        throwsToolExit(message: '"xyz.xyz" is not a valid Dart package name.'),
      );
    }));
  });
}

/// Copy templates from real flutter root into fake memory file system.
MemoryFileSystem populateTemplates(String fakeFlutterRoot, String realFlutterRoot) {
  final MemoryFileSystem memoryFileSystem = MemoryFileSystem(style: platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix);
  const LocalFileSystem localFileSystem = LocalFileSystem();
  final Directory templateDirectory = localFileSystem
      .directory(memoryFileSystem.path.join(realFlutterRoot, 'packages', 'flutter_tools', 'templates'));
  for (FileSystemEntity entity in templateDirectory.listSync(recursive: true)) {
    if (entity is File) {
      final String relativePath = memoryFileSystem.path.relative(entity.path, from: templateDirectory.path);
      final String fakePath = memoryFileSystem.path.join(fakeFlutterRoot, 'packages',
          'flutter_tools', 'templates', relativePath);
      memoryFileSystem.file(fakePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(entity.readAsBytesSync());
    }
  }
  return memoryFileSystem;
}
