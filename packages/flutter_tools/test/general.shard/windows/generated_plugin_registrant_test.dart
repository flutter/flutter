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

const TemplateRenderer renderer = MustacheTemplateRenderer();

void main() {
  final List<String> buildModesToTest = <String>['debug', 'profile', 'release'];

  testWithoutContext('Win32 injects Win32 non-dev dependency plugins', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
      fileSystem.currentDirectory,
    );

    for (final String buildMode in buildModesToTest) {
      await writeWindowsPluginFiles(
        flutterProject,
        <Plugin>[
          Plugin(
            name: 'test',
            path: 'foo',
            defaultPackagePlatforms: const <String, String>{},
            pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
            platforms: const <String, PluginPlatform>{
              WindowsPlugin.kConfigKey: WindowsPlugin(
                name: 'test',
                pluginClass: 'Foo',
                variants: <PluginPlatformVariant>{PluginPlatformVariant.win32},
              ),
            },
            dependencies: <String>[],
            isDirectDependency: true,
            isDevDependency: false,
          ),
        ],
        renderer,
        releaseMode: buildMode == 'release',
      );

      final Directory managed = flutterProject.windows.managedDirectory;
      expect(flutterProject.windows.generatedPluginCmakeFile, exists);
      expect(managed.childFile('generated_plugin_registrant.h'), exists);
      expect(
        managed.childFile('generated_plugin_registrant.cc').readAsStringSync(),
        contains('#include <test/foo.h>'),
      );
    }
  });

  testWithoutContext(
    'Win32 does not inject Win32 dev dependency plugins in release mode',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );

      for (final String buildMode in buildModesToTest) {
        final bool isTestingReleaseMode = buildMode == 'release';
        await writeWindowsPluginFiles(
          flutterProject,
          <Plugin>[
            Plugin(
              name: 'test',
              path: 'foo',
              defaultPackagePlatforms: const <String, String>{},
              pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
              platforms: const <String, PluginPlatform>{
                WindowsPlugin.kConfigKey: WindowsPlugin(
                  name: 'test',
                  pluginClass: 'Foo',
                  variants: <PluginPlatformVariant>{PluginPlatformVariant.win32},
                ),
              },
              dependencies: <String>[],
              isDirectDependency: true,
              isDevDependency: true,
            ),
          ],
          renderer,
          releaseMode: isTestingReleaseMode,
        );

        final Directory managed = flutterProject.windows.managedDirectory;
        const String testPluginDependencyImport = '#include <test/foo.h>';
        expect(flutterProject.windows.generatedPluginCmakeFile, exists);
        expect(managed.childFile('generated_plugin_registrant.h'), exists);
        expect(
          managed.childFile('generated_plugin_registrant.cc').readAsStringSync(),
          isTestingReleaseMode
              ? isNot(contains(testPluginDependencyImport))
              : contains(testPluginDependencyImport),
        );
      }
    },
  );
}
