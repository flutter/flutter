// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const TemplateRenderer renderer = MustacheTemplateRenderer();

void main() {
  List<String> buildModesToTest = ['debug', 'profile', 'release'];

  testUsingContext(
    'MacOS injects MacOS non-dev dependency plugins',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );

      for (final String buildMode in buildModesToTest) {
        await writeMacOSPluginRegistrant(flutterProject, <Plugin>[
          Plugin(
            name: 'test',
            path: 'foo',
            defaultPackagePlatforms: const <String, String>{},
            pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
            platforms: const <String, PluginPlatform>{
              MacOSPlugin.kConfigKey: MacOSPlugin(name: 'test', pluginClass: 'Foo'),
            },
            dependencies: <String>[],
            isDirectDependency: true,
            isDevDependency: false,
          ),
        ], releaseMode: buildMode == 'release');

        final Directory managed = flutterProject.macos.managedDirectory;
        expect(managed.childFile('GeneratedPluginRegistrant.swift'), exists);
        expect(
          managed.childFile('GeneratedPluginRegistrant.swift').readAsStringSync(),
          contains('Foo.register'),
        );
      }
    },
    overrides: <Type, Generator>{TemplateRenderer: () => const MustacheTemplateRenderer()},
  );

  testUsingContext(
    'MacOS does not inject MacOS dev dependency plugins in release mode',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );

      for (final String buildMode in buildModesToTest) {
        bool isTestingReleaseMode = buildMode == 'release';
        await writeMacOSPluginRegistrant(flutterProject, <Plugin>[
          Plugin(
            name: 'test',
            path: 'foo',
            defaultPackagePlatforms: const <String, String>{},
            pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
            platforms: const <String, PluginPlatform>{
              MacOSPlugin.kConfigKey: MacOSPlugin(name: 'test', pluginClass: 'Foo'),
            },
            dependencies: <String>[],
            isDirectDependency: true,
            isDevDependency: true,
          ),
        ], releaseMode: isTestingReleaseMode);

        final Directory managed = flutterProject.macos.managedDirectory;
        final String testPluginRegistration = 'Foo.register';
        expect(managed.childFile('GeneratedPluginRegistrant.swift'), exists);
        expect(
          managed.childFile('GeneratedPluginRegistrant.swift').readAsStringSync(),
          isTestingReleaseMode ? isNot(contains(testPluginRegistration)) : contains(testPluginRegistration),
        );
      }
    },
    overrides: <Type, Generator>{TemplateRenderer: () => const MustacheTemplateRenderer()},
  );
}
