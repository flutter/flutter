// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  List<String> buildModesToTest = ['debug', 'profile', 'release'];
  final FileSystem fileSystem = MemoryFileSystem.test();

  testUsingContext(
    'Android injects Android non-dev dependency plugins',
    () async {
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );
      fileSystem.file('.pub_cache/foo/android/src/main/java/com/company/Foo.java')
        ..createSync(recursive: true)
        ..writeAsStringSync('io.flutter.embedding.engine.plugins.FlutterPlugin');

      for (final String buildMode in buildModesToTest) {
        await writeAndroidPluginRegistrant(flutterProject, <Plugin>[
          Plugin(
            name: 'foo',
            path: 'foo',
            defaultPackagePlatforms: const <String, String>{},
            pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
            platforms: <String, PluginPlatform>{
              AndroidPlugin.kConfigKey: AndroidPlugin(
                name: 'foo',
                package: 'com.company',
                pluginClass: 'Foo',
                pluginPath: '.pub_cache/foo',
                fileSystem: fileSystem,
              ),
            },
            dependencies: <String>[],
            isDirectDependency: true,
            isDevDependency: false,
          ),
        ], releaseMode: buildMode == 'release');

        expect(flutterProject.android.generatedPluginRegistrantFile, exists);
        expect(
          flutterProject.android.generatedPluginRegistrantFile.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new com.company.Foo());'),
        );
      }
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'Android does not inject Android dev dependency plugins in release mode',
    () async {
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );
      fileSystem.file('.pub_cache/foo/android/src/main/java/com/company/Foo.java')
        ..createSync(recursive: true)
        ..writeAsStringSync('io.flutter.embedding.engine.plugins.FlutterPlugin');

      for (final String buildMode in buildModesToTest) {
        bool isTestingReleaseMode = buildMode == 'release';
        await writeAndroidPluginRegistrant(flutterProject, <Plugin>[
          Plugin(
            name: 'foo',
            path: 'foo',
            defaultPackagePlatforms: const <String, String>{},
            pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
            platforms: <String, PluginPlatform>{
              AndroidPlugin.kConfigKey: AndroidPlugin(
                name: 'foo',
                package: 'com.company',
                pluginClass: 'Foo',
                pluginPath: '.pub_cache/foo',
                fileSystem: fileSystem,
              ),
            },
            dependencies: <String>[],
            isDirectDependency: true,
            isDevDependency: true,
          ),
        ], releaseMode: isTestingReleaseMode);

        final String fooPluginDependency = 'com.company.Foo()';
        expect(flutterProject.android.generatedPluginRegistrantFile, exists);
        expect(
          flutterProject.android.generatedPluginRegistrantFile.readAsStringSync(),
          isTestingReleaseMode
              ? isNot(contains(fooPluginDependency))
              : contains(fooPluginDependency),
        );
      }
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );
}
