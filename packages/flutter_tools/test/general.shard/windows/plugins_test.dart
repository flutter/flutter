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
import '../../src/fakes.dart';

const TemplateRenderer renderer = MustacheTemplateRenderer();

const String kPluginDependencies = r'''
{
  "info":"This is a generated file; do not edit or check into version control.",
  "plugins":{
    "windows":[
      {
        "name":"example","path":"C:\\\\example\\\\",
        "dependencies":[]
      }
    ]
  }
}
''';

void main() {

  testWithoutContext('Win32 injects Win32 plugins', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    setUpProject(fileSystem);
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    await writeWindowsPluginFiles(flutterProject, <Plugin>[
      Plugin(
        name: 'test',
        path: 'foo',
        defaultPackagePlatforms: const <String, String>{},
        pluginDartClassPlatforms: const <String, String>{},
        platforms: const <String, PluginPlatform>{
          WindowsPlugin.kConfigKey: WindowsPlugin(
            name: 'test',
            pluginClass: 'Foo',
            variants: <PluginPlatformVariant>{PluginPlatformVariant.win32},
          )},
        dependencies: <String>[],
        isDirectDependency: true,
      ),
    ], renderer);

    final Directory managed = flutterProject.windows.managedDirectory;
    expect(flutterProject.windows.generatedPluginCmakeFile, exists);
    expect(managed.childFile('generated_plugin_registrant.h'), exists);
    expect(
      managed.childFile('generated_plugin_registrant.cc').readAsStringSync(),
      contains('#include <test/foo.h>'),
    );
  });

  testWithoutContext('UWP injects plugins marked as UWP-compatible', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    setUpProject(fileSystem);
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    await writeWindowsUwpPluginFiles(flutterProject, <Plugin>[
      Plugin(
        name: 'test',
        path: 'foo',
        defaultPackagePlatforms: const <String, String>{},
        pluginDartClassPlatforms: const <String, String>{},
        platforms: const <String, PluginPlatform>{
          WindowsPlugin.kConfigKey: WindowsPlugin(
            name: 'test',
            pluginClass: 'Foo',
            variants: <PluginPlatformVariant>{PluginPlatformVariant.winuwp},
          )},
        dependencies: <String>[],
        isDirectDependency: true,
      ),
    ], renderer);

    final Directory managed = flutterProject.windowsUwp.managedDirectory;
    expect(flutterProject.windowsUwp.generatedPluginCmakeFile, exists);
    expect(managed.childFile('generated_plugin_registrant.h'), exists);
    expect(
      managed.childFile('generated_plugin_registrant.cc').readAsStringSync(),
      contains('#include <test/foo.h>'),
    );
  });

  testWithoutContext('UWP does not inject Win32-only plugins', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    setUpProject(fileSystem);
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    await writeWindowsUwpPluginFiles(flutterProject, <Plugin>[
      Plugin(
        name: 'test',
        path: 'foo',
        defaultPackagePlatforms: const <String, String>{},
        pluginDartClassPlatforms: const <String, String>{},
        platforms: const <String, PluginPlatform>{
          WindowsPlugin.kConfigKey: WindowsPlugin(
            name: 'test',
            pluginClass: 'Foo',
            variants: <PluginPlatformVariant>{PluginPlatformVariant.win32},
          )},
        dependencies: <String>[],
        isDirectDependency: true,
      ),
    ], renderer);

    final Directory managed = flutterProject.windowsUwp.managedDirectory;
    expect(flutterProject.windowsUwp.generatedPluginCmakeFile, exists);
    expect(managed.childFile('generated_plugin_registrant.h'), exists);
    expect(
      managed.childFile('generated_plugin_registrant.cc').readAsStringSync(),
      isNot(contains('#include <test/foo.h>')),
    );
  });

  testWithoutContext('Symlink injection treats UWP as Win32', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    setUpProject(fileSystem);
    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    flutterProject.flutterPluginsDependenciesFile.writeAsStringSync(kPluginDependencies);

    createPluginSymlinks(
      flutterProject,
      featureFlagsOverride: TestFeatureFlags(isWindowsUwpEnabled: true),
    );

    expect(flutterProject.windowsUwp.pluginSymlinkDirectory, exists);

    final Link link = flutterProject.windowsUwp.pluginSymlinkDirectory.listSync().single as Link;

    expect(link.path, '/winuwp/flutter/ephemeral/.plugin_symlinks/example');
    expect(link.targetSync(), r'C:\\example\\');
  });
}

void setUpProject(FileSystem fileSystem) {
  fileSystem.file('pubspec.yaml').createSync();
  fileSystem.file('winuwp/CMakeLists.txt')
    .createSync(recursive: true);
  fileSystem.file('winuwp/project_version')
    ..createSync(recursive: true)
    ..writeAsStringSync('0');
}
