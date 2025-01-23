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

void main() {
  List<String> buildModesToTest = ['debug', 'profile', 'release'];
  final FileSystem fileSystem = MemoryFileSystem.test();

  testUsingContext(
    'iOS injects iOS non-dev dependency plugins',
    () async {
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );

      for (final String buildMode in buildModesToTest) {
        await writeIOSPluginRegistrant(flutterProject, <Plugin>[
          Plugin(
            name: 'foo',
            path: 'foo',
            defaultPackagePlatforms: const <String, String>{},
            pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
            platforms: <String, PluginPlatform>{
              IOSPlugin.kConfigKey: IOSPlugin(
                name: 'foo',
                classPrefix: '',
                pluginClass: 'Foo',
              ),
            },
            dependencies: <String>[],
            isDirectDependency: true,
            isDevDependency: false,
          ),
        ], releaseMode: buildMode == 'release');

        expect(flutterProject.ios.pluginRegistrantHeader, exists);
        expect(flutterProject.ios.pluginRegistrantImplementation, exists);
        expect(
          flutterProject.ios.pluginRegistrantImplementation.readAsStringSync(),
          contains('#import <foo/Foo.h>'),
        );
      }
    },
    overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
    }
  );

   testUsingContext(
    'iOS does not iOS dev dependency plugins in realease mode',
    () async {
      final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );

      for (final String buildMode in buildModesToTest) {
        bool isTestingReleaseMode = buildMode == 'release';
        await writeIOSPluginRegistrant(flutterProject, <Plugin>[
          Plugin(
            name: 'foo',
            path: 'foo',
            defaultPackagePlatforms: const <String, String>{},
            pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
            platforms: <String, PluginPlatform>{
              IOSPlugin.kConfigKey: IOSPlugin(
                name: 'foo',
                classPrefix: '',
                pluginClass: 'Foo',
              ),
            },
            dependencies: <String>[],
            isDirectDependency: true,
            isDevDependency: true,
          ),
        ], releaseMode: isTestingReleaseMode);

        final String fooPluginDependencyImport = '#import <foo/Foo.h>';
        expect(flutterProject.ios.pluginRegistrantHeader, exists);
        expect(flutterProject.ios.pluginRegistrantImplementation, exists);
        expect(
          flutterProject.ios.pluginRegistrantImplementation.readAsStringSync(),
          isTestingReleaseMode ? isNot(contains(fooPluginDependencyImport)) : contains(fooPluginDependencyImport),
        );
      }
    },
    overrides: <Type, Generator>{
        TemplateRenderer: () => const MustacheTemplateRenderer(),
    }
  );
}
