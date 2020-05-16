// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('plugins', () {
    FileSystem fs;
    MockFlutterProject flutterProject;
    MockIosProject iosProject;
    MockMacOSProject macosProject;
    MockAndroidProject androidProject;
    MockWebProject webProject;
    MockWindowsProject windowsProject;
    MockLinuxProject linuxProject;
    File packagesFile;
    Directory dummyPackageDirectory;
    SystemClock mockClock;
    FlutterVersion mockVersion;

    setUp(() async {
      fs = MemoryFileSystem();
      mockClock = MockClock();
      mockVersion = MockFlutterVersion();

      // Add basic properties to the Flutter project and subprojects
      flutterProject = MockFlutterProject();
      when(flutterProject.directory).thenReturn(fs.directory('/'));
      // TODO(franciscojma): Remove logic for .flutter-plugins it's deprecated.
      when(flutterProject.flutterPluginsFile).thenReturn(flutterProject.directory.childFile('.flutter-plugins'));
      when(flutterProject.flutterPluginsDependenciesFile).thenReturn(flutterProject.directory.childFile('.flutter-plugins-dependencies'));
      iosProject = MockIosProject();
      when(flutterProject.ios).thenReturn(iosProject);
      when(iosProject.pluginRegistrantHost).thenReturn(flutterProject.directory.childDirectory('Runner'));
      when(iosProject.podfile).thenReturn(flutterProject.directory.childDirectory('ios').childFile('Podfile'));
      when(iosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('ios').childFile('Podfile.lock'));
      when(iosProject.pluginConfigKey).thenReturn('ios');
      when(iosProject.existsSync()).thenReturn(false);
      macosProject = MockMacOSProject();
      when(flutterProject.macos).thenReturn(macosProject);
      when(macosProject.podfile).thenReturn(flutterProject.directory.childDirectory('macos').childFile('Podfile'));
      when(macosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('macos').childFile('Podfile.lock'));
      final Directory macosManagedDirectory = flutterProject.directory.childDirectory('macos').childDirectory('Flutter');
      when(macosProject.managedDirectory).thenReturn(macosManagedDirectory);
      when(macosProject.pluginConfigKey).thenReturn('macos');
      when(macosProject.existsSync()).thenReturn(false);
      androidProject = MockAndroidProject();
      when(flutterProject.android).thenReturn(androidProject);
      when(androidProject.pluginRegistrantHost).thenReturn(flutterProject.directory.childDirectory('android').childDirectory('app'));
      when(androidProject.hostAppGradleRoot).thenReturn(flutterProject.directory.childDirectory('android'));
      when(androidProject.pluginConfigKey).thenReturn('android');
      when(androidProject.existsSync()).thenReturn(false);
      webProject = MockWebProject();
      when(flutterProject.web).thenReturn(webProject);
      when(webProject.libDirectory).thenReturn(flutterProject.directory.childDirectory('lib'));
      when(webProject.existsSync()).thenReturn(true);
      when(webProject.pluginConfigKey).thenReturn('web');
      when(webProject.existsSync()).thenReturn(false);
      windowsProject = MockWindowsProject();
      when(flutterProject.windows).thenReturn(windowsProject);
      when(windowsProject.pluginConfigKey).thenReturn('windows');
      final Directory windowsManagedDirectory = flutterProject.directory.childDirectory('windows').childDirectory('flutter');
      when(windowsProject.managedDirectory).thenReturn(windowsManagedDirectory);
      when(windowsProject.vcprojFile).thenReturn(windowsManagedDirectory.parent.childFile('Runner.vcxproj'));
      when(windowsProject.solutionFile).thenReturn(windowsManagedDirectory.parent.childFile('Runner.sln'));
      when(windowsProject.pluginSymlinkDirectory).thenReturn(windowsManagedDirectory.childDirectory('ephemeral').childDirectory('.plugin_symlinks'));
      when(windowsProject.generatedPluginPropertySheetFile).thenReturn(windowsManagedDirectory.childFile('GeneratedPlugins.props'));
      when(windowsProject.existsSync()).thenReturn(false);
      linuxProject = MockLinuxProject();
      when(flutterProject.linux).thenReturn(linuxProject);
      when(linuxProject.pluginConfigKey).thenReturn('linux');
      final Directory linuxManagedDirectory = flutterProject.directory.childDirectory('linux').childDirectory('flutter');
      final Directory linuxEphemeralDirectory = linuxManagedDirectory.childDirectory('ephemeral');
      when(linuxProject.managedDirectory).thenReturn(linuxManagedDirectory);
      when(linuxProject.ephemeralDirectory).thenReturn(linuxEphemeralDirectory);
      when(linuxProject.pluginSymlinkDirectory).thenReturn(linuxEphemeralDirectory.childDirectory('.plugin_symlinks'));
      when(linuxProject.cmakeFile).thenReturn(linuxManagedDirectory.parent.childFile('CMakeLists.txt'));
      when(linuxProject.generatedPluginCmakeFile).thenReturn(linuxManagedDirectory.childFile('generated_plugins.mk'));
      when(linuxProject.existsSync()).thenReturn(false);

      when(mockClock.now()).thenAnswer(
        (Invocation _) => DateTime(1970, 1, 1)
      );
      when(mockVersion.frameworkVersion).thenAnswer(
        (Invocation _) => '1.0.0'
      );

      // Set up a simple .packages file for all the tests to use, pointing to one package.
      dummyPackageDirectory = fs.directory('/pubcache/apackage/lib/');
      packagesFile = fs.file(fs.path.join(flutterProject.directory.path, globalPackagesPath));
      packagesFile..createSync(recursive: true)
          ..writeAsStringSync('apackage:file://${dummyPackageDirectory.path}\n');
    });

    // Makes the dummy package pointed to by packagesFile look like a plugin.
    void configureDummyPackageAsPlugin() {
      dummyPackageDirectory.parent.childFile('pubspec.yaml')..createSync(recursive: true)..writeAsStringSync('''
  flutter:
    plugin:
      platforms:
        ios:
          pluginClass: FLESomePlugin
        macos:
          pluginClass: FLESomePlugin
        windows:
          pluginClass: SomePlugin
        linux:
          pluginClass: SomePlugin
        web:
          pluginClass: SomePlugin
          fileName: lib/SomeFile.dart
        android:
          pluginClass: SomePlugin
          package: AndroidPackage
  ''');
    }

    void createNewJavaPlugin1() {
      final Directory pluginUsingJavaAndNewEmbeddingDir =
              fs.systemTempDirectory.createTempSync('flutter_plugin_using_java_and_new_embedding_dir.');
      pluginUsingJavaAndNewEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin1
    pluginClass: UseNewEmbedding
              ''');
      pluginUsingJavaAndNewEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory('plugin1')
        .childFile('UseNewEmbedding.java')
        ..createSync(recursive: true)
        ..writeAsStringSync('import io.flutter.embedding.engine.plugins.FlutterPlugin;');

      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync(
          'plugin1:${pluginUsingJavaAndNewEmbeddingDir.childDirectory('lib').uri.toString()}\n',
          mode: FileMode.append,
        );
    }

    Directory createPluginWithInvalidAndroidPackage() {
      final Directory pluginUsingJavaAndNewEmbeddingDir =
              fs.systemTempDirectory.createTempSync('flutter_plugin_invalid_package.');
      pluginUsingJavaAndNewEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin1.invalid
    pluginClass: UseNewEmbedding
              ''');
      pluginUsingJavaAndNewEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory('plugin1')
        .childDirectory('correct')
        .childFile('UseNewEmbedding.java')
        ..createSync(recursive: true)
        ..writeAsStringSync('import io.flutter.embedding.engine.plugins.FlutterPlugin;');

      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync(
          'plugin1:${pluginUsingJavaAndNewEmbeddingDir.childDirectory('lib').uri.toString()}\n',
          mode: FileMode.append,
        );
      return pluginUsingJavaAndNewEmbeddingDir;
    }

    void createNewKotlinPlugin2() {
      final Directory pluginUsingKotlinAndNewEmbeddingDir =
          fs.systemTempDirectory.createTempSync('flutter_plugin_using_kotlin_and_new_embedding_dir.');
      pluginUsingKotlinAndNewEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin2
    pluginClass: UseNewEmbedding
          ''');
      pluginUsingKotlinAndNewEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('kotlin')
        .childDirectory('plugin2')
        .childFile('UseNewEmbedding.kt')
        ..createSync(recursive: true)
        ..writeAsStringSync('import io.flutter.embedding.engine.plugins.FlutterPlugin');

      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync(
          'plugin2:${pluginUsingKotlinAndNewEmbeddingDir.childDirectory('lib').uri.toString()}\n',
          mode: FileMode.append,
        );
    }

    void createOldJavaPlugin(String pluginName) {
      final Directory pluginUsingOldEmbeddingDir =
        fs.systemTempDirectory.createTempSync('flutter_plugin_using_old_embedding_dir.');
      pluginUsingOldEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: $pluginName
    pluginClass: UseOldEmbedding
        ''');
      pluginUsingOldEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory(pluginName)
        .childFile('UseOldEmbedding.java')
        .createSync(recursive: true);

      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync(
          '$pluginName:${pluginUsingOldEmbeddingDir.childDirectory('lib').uri.toString()}\n',
          mode: FileMode.append,
        );
    }

    void createDualSupportJavaPlugin4() {
      final Directory pluginUsingJavaAndNewEmbeddingDir =
        fs.systemTempDirectory.createTempSync('flutter_plugin_using_java_and_new_embedding_dir.');
      pluginUsingJavaAndNewEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin4
    pluginClass: UseBothEmbedding
''');
      pluginUsingJavaAndNewEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory('plugin4')
        .childFile('UseBothEmbedding.java')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import io.flutter.embedding.engine.plugins.FlutterPlugin;\n'
          'PluginRegistry\n'
          'registerWith(Irrelevant registrar)\n'
        );

      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync(
          'plugin4:${pluginUsingJavaAndNewEmbeddingDir.childDirectory('lib').uri.toString()}',
          mode: FileMode.append,
        );
    }

    Directory createPluginWithDependencies({
      @required String name,
      @required List<String> dependencies,
    }) {
      assert(name != null);
      assert(dependencies != null);

      final Directory pluginDirectory = fs.systemTempDirectory.createTempSync('plugin.');
      pluginDirectory
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
name: $name
flutter:
  plugin:
    androidPackage: plugin2
    pluginClass: UseNewEmbedding
dependencies:
''');
      for (final String dependency in dependencies) {
        pluginDirectory
          .childFile('pubspec.yaml')
          .writeAsStringSync('  $dependency:\n', mode: FileMode.append);
      }
      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync(
          '$name:${pluginDirectory.childDirectory('lib').uri.toString()}\n',
          mode: FileMode.append,
        );
      return pluginDirectory;
    }

    // Creates the files that would indicate that pod install has run for the
    // given project.
    void simulatePodInstallRun(XcodeBasedProject project) {
      project.podManifestLock.createSync(recursive: true);
    }

    // Creates a Windows solution file sufficient to allow plugin injection
    // to run without failing.
    void createDummyWindowsSolutionFile() {
      windowsProject.solutionFile.createSync(recursive: true);
      // This isn't a valid solution file, but it's just enough to work with the
      // plugin injection.
      windowsProject.solutionFile.writeAsStringSync('''
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "Runner", "Runner.vcxproj", "{3842E94C-E348-463A-ADBE-625A2B69B628}"
	ProjectSection(ProjectDependencies) = postProject
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F} = {6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}
	EndProjectSection
EndProject
Global
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
	EndGlobalSection
EndGlobal''');
    }

    // Creates a Windows project file for dummyPackageDirectory sufficient to
    // allow plugin injection to run without failing.
    void createDummyPluginWindowsProjectFile() {
      final File projectFile = dummyPackageDirectory
        .parent
        .childDirectory('windows')
        .childFile('plugin.vcxproj');
      projectFile.createSync(recursive: true);
      // This isn't a valid project file, but it's just enough to work with the
      // plugin injection.
      projectFile.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup Label="Globals">
    <ProjectGuid>{5919689F-A5D5-462C-AF50-D405CCEF89B8}</ProjectGuid>'}
    <ProjectName>apackage</ProjectName>
  </PropertyGroup>
</Project>''');
    }

    group('refreshPlugins', () {
      testUsingContext('Refreshing the plugin list is a no-op when the plugins list stays empty', () async {
        await refreshPluginsList(flutterProject);

        expect(flutterProject.flutterPluginsFile.existsSync(), false);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Refreshing the plugin list deletes the plugin file when there were plugins but no longer are', () async {
        flutterProject.flutterPluginsFile.createSync();
        flutterProject.flutterPluginsDependenciesFile.createSync();

        await refreshPluginsList(flutterProject);

        expect(flutterProject.flutterPluginsFile.existsSync(), false);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Refreshing the plugin list creates a plugin directory when there are plugins', () async {
        configureDummyPackageAsPlugin();
        when(iosProject.existsSync()).thenReturn(true);

        await refreshPluginsList(flutterProject);

        expect(flutterProject.flutterPluginsFile.existsSync(), true);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext(
        'Refreshing the plugin list modifies .flutter-plugins '
        'and .flutter-plugins-dependencies when there are plugins', () async {
        final Directory pluginA = createPluginWithDependencies(name: 'plugin-a', dependencies: const <String>['plugin-b', 'plugin-c', 'random-package']);
        final Directory pluginB = createPluginWithDependencies(name: 'plugin-b', dependencies: const <String>['plugin-c']);
        final Directory pluginC = createPluginWithDependencies(name: 'plugin-c', dependencies: const <String>[]);
        when(iosProject.existsSync()).thenReturn(true);

        final DateTime dateCreated = DateTime(1970, 1, 1);
        when(mockClock.now()).thenAnswer(
          (Invocation _) => dateCreated
        );
        const String version = '1.0.0';
        when(mockVersion.frameworkVersion).thenAnswer(
          (Invocation _) => version
        );

        await refreshPluginsList(flutterProject);

        // Verify .flutter-plugins-dependencies is configured correctly.
        expect(flutterProject.flutterPluginsFile.existsSync(), true);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), true);
        expect(flutterProject.flutterPluginsFile.readAsStringSync(),
          '# This is a generated file; do not edit or check into version control.\n'
          'plugin-a=${pluginA.path}/\n'
          'plugin-b=${pluginB.path}/\n'
          'plugin-c=${pluginC.path}/\n'
          ''
        );

        final String pluginsString = flutterProject.flutterPluginsDependenciesFile.readAsStringSync();
        final Map<String, dynamic> jsonContent = json.decode(pluginsString) as  Map<String, dynamic>;
        expect(jsonContent['info'], 'This is a generated file; do not edit or check into version control.');

        final Map<String, dynamic> plugins = jsonContent['plugins'] as Map<String, dynamic>;
        final List<dynamic> expectedPlugins = <dynamic>[
          <String, dynamic> {
            'name': 'plugin-a',
            'path': '${pluginA.path}/',
            'dependencies': <String>[
              'plugin-b',
              'plugin-c'
            ]
          },
          <String, dynamic> {
            'name': 'plugin-b',
            'path': '${pluginB.path}/',
            'dependencies': <String>[
              'plugin-c'
            ]
          },
          <String, dynamic> {
            'name': 'plugin-c',
            'path': '${pluginC.path}/',
            'dependencies': <String>[]
          },
        ];
        expect(plugins['ios'], expectedPlugins);
        expect(plugins['android'], expectedPlugins);
        expect(plugins['macos'], <dynamic>[]);
        expect(plugins['windows'], <dynamic>[]);
        expect(plugins['linux'], <dynamic>[]);
        expect(plugins['web'], <dynamic>[]);

        final List<dynamic> expectedDependencyGraph = <dynamic>[
          <String, dynamic> {
            'name': 'plugin-a',
            'dependencies': <String>[
              'plugin-b',
              'plugin-c'
            ]
          },
          <String, dynamic> {
            'name': 'plugin-b',
            'dependencies': <String>[
              'plugin-c'
            ]
          },
          <String, dynamic> {
            'name': 'plugin-c',
            'dependencies': <String>[]
          },
        ];

        expect(jsonContent['dependencyGraph'], expectedDependencyGraph);
        expect(jsonContent['date_created'], dateCreated.toString());
        expect(jsonContent['version'], version);

        // Make sure tests are updated if a new object is added/removed.
        final List<String> expectedKeys = <String>[
          'info',
          'plugins',
          'dependencyGraph',
          'date_created',
          'version',
        ];
        expect(jsonContent.keys, expectedKeys);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        SystemClock: () => mockClock,
        FlutterVersion: () => mockVersion
      });

      testUsingContext('Changes to the plugin list invalidates the Cocoapod lockfiles', () async {
        simulatePodInstallRun(iosProject);
        simulatePodInstallRun(macosProject);
        configureDummyPackageAsPlugin();
        when(iosProject.existsSync()).thenReturn(true);
        when(macosProject.existsSync()).thenReturn(true);

        await refreshPluginsList(flutterProject);
        expect(iosProject.podManifestLock.existsSync(), false);
        expect(macosProject.podManifestLock.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        SystemClock: () => mockClock,
        FlutterVersion: () => mockVersion
      });

      testUsingContext('No changes to the plugin list does not invalidate the Cocoapod lockfiles', () async {
        configureDummyPackageAsPlugin();
        when(iosProject.existsSync()).thenReturn(true);
        when(macosProject.existsSync()).thenReturn(true);

        // First call will create the .flutter-plugins-dependencies and the legacy .flutter-plugins file.
        // Since there was no plugins list, the lock files will be invalidated.
        // The second call is where the plugins list is compared to the existing one, and if there is no change,
        // the podfiles shouldn't be invalidated.
        await refreshPluginsList(flutterProject);
        simulatePodInstallRun(iosProject);
        simulatePodInstallRun(macosProject);

        await refreshPluginsList(flutterProject);
        expect(iosProject.podManifestLock.existsSync(), true);
        expect(macosProject.podManifestLock.existsSync(), true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        SystemClock: () => mockClock,
        FlutterVersion: () => mockVersion
      });
    });

    group('injectPlugins', () {
      MockFeatureFlags featureFlags;
      MockXcodeProjectInterpreter xcodeProjectInterpreter;

      setUp(() {
        featureFlags = MockFeatureFlags();
        when(featureFlags.isLinuxEnabled).thenReturn(false);
        when(featureFlags.isMacOSEnabled).thenReturn(false);
        when(featureFlags.isWindowsEnabled).thenReturn(false);
        when(featureFlags.isWebEnabled).thenReturn(false);

        xcodeProjectInterpreter = MockXcodeProjectInterpreter();
        when(xcodeProjectInterpreter.isInstalled).thenReturn(false);
      });

      testUsingContext('Registrant uses old embedding in app project', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
        expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
        expect(registrant.readAsStringSync(), contains('public static void registerWith(PluginRegistry registry)'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Registrant uses new embedding if app uses new embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
        expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
        expect(registrant.readAsStringSync(), contains('public static void registerWith(@NonNull FlutterEngine flutterEngine)'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Registrant uses shim for plugins using old embedding if app uses new embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createNewJavaPlugin1();
        createNewKotlinPlugin2();
        createOldJavaPlugin('plugin3');

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');

        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin1.UseNewEmbedding());'));
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin2.UseNewEmbedding());'));
        expect(registrant.readAsStringSync(),
          contains('plugin3.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("plugin3.UseOldEmbedding"));'));

        // There should be no warning message
        expect(testLogger.statusText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('exits the tool if an app uses the v1 embedding and a plugin only supports the v2 embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        createNewJavaPlugin1();

        await expectLater(
          () async {
            await injectPlugins(flutterProject);
          },
          throwsToolExit(
            message: 'The plugin `plugin1` requires your app to be migrated to the Android embedding v2. '
                     'Follow the steps on https://flutter.dev/go/android-project-migration and re-run this command.'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      // Issue: https://github.com/flutter/flutter/issues/47803
      testUsingContext('exits the tool if a plugin sets an invalid android package in pubspec.yaml', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        final Directory pluginDir = createPluginWithInvalidAndroidPackage();

        await expectLater(
          () async {
            await injectPlugins(flutterProject);
          },
          throwsToolExit(
            message: "The plugin `plugin1` doesn't have a main class defined in "
                     '${pluginDir.path}/android/src/main/java/plugin1/invalid/UseNewEmbedding.java or '
                     '${pluginDir.path}/android/src/main/kotlin/plugin1/invalid/UseNewEmbedding.kt. '
                     "This is likely to due to an incorrect `androidPackage: plugin1.invalid` or `mainClass` entry in the plugin's pubspec.yaml.\n"
                     'If you are the author of this plugin, fix the `androidPackage` entry or move the main class to any of locations used above. '
                     'Otherwise, please contact the author of this plugin and consider using a different plugin in the meanwhile.',
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('old embedding app uses a plugin that supports v1 and v2 embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
        expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
        expect(registrant.readAsStringSync(),
          contains('UseBothEmbedding.registerWith(registry.registrarFor("plugin4.UseBothEmbedding"));'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('new embedding app uses a plugin that supports v1 and v2 embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
        expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin4.UseBothEmbedding());'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Modules use new embedding', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
        expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
        expect(registrant.readAsStringSync(), contains('public static void registerWith(@NonNull FlutterEngine flutterEngine)'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Module using old plugin shows warning', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createOldJavaPlugin('plugin3');

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('plugin3.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("plugin3.UseOldEmbedding"));'));
        expect(testLogger.statusText, contains('The plugin `plugin3` is built using an older version of the Android plugin API'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using new plugin shows no warnings', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createNewJavaPlugin1();

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin1.UseNewEmbedding());'));

        expect(testLogger.statusText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using plugin with v1 and v2 support shows no warning', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin4.UseBothEmbedding());'));

        expect(testLogger.statusText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using multiple old plugins all show warnings', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createOldJavaPlugin('plugin3');
        createOldJavaPlugin('plugin4');

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('plugin3.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("plugin3.UseOldEmbedding"));'));
        expect(registrant.readAsStringSync(),
          contains('plugin4.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("plugin4.UseOldEmbedding"));'));
        expect(testLogger.statusText, contains('The plugin `plugin3` is built using an older version of the Android plugin API'));
        expect(testLogger.statusText, contains('The plugin `plugin4` is built using an older version of the Android plugin API'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Does not throw when AndroidManifest.xml is not found', () async {
        when(flutterProject.isModule).thenReturn(false);

        final File manifest = MockFile();
        when(manifest.existsSync()).thenReturn(false);
        when(androidProject.appManifestFile).thenReturn(manifest);

        await injectPlugins(flutterProject);

      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext("Registrant for web doesn't escape slashes in imports", () async {
        when(flutterProject.isModule).thenReturn(true);
        when(featureFlags.isWebEnabled).thenReturn(true);
        when(webProject.existsSync()).thenReturn(true);

        final Directory webPluginWithNestedFile =
            fs.systemTempDirectory.createTempSync('web_plugin_with_nested');
        webPluginWithNestedFile.childFile('pubspec.yaml').writeAsStringSync('''
  flutter:
    plugin:
      platforms:
        web:
          pluginClass: WebPlugin
          fileName: src/web_plugin.dart
  ''');
        webPluginWithNestedFile
          .childDirectory('lib')
          .childDirectory('src')
          .childFile('web_plugin.dart')
          .createSync(recursive: true);

        flutterProject.directory
          .childFile('.packages')
          .writeAsStringSync('''
web_plugin_with_nested:${webPluginWithNestedFile.childDirectory('lib').uri.toString()}
''');

        await injectPlugins(flutterProject);

        final File registrant = flutterProject.directory
            .childDirectory('lib')
            .childFile('generated_plugin_registrant.dart');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains("import 'package:web_plugin_with_nested/src/web_plugin.dart';"));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Injecting creates generated macos registrant, but does not include Dart-only plugins', () async {
        when(macosProject.existsSync()).thenReturn(true);
        when(featureFlags.isMacOSEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(true);
        // Create a plugin without a pluginClass.
        dummyPackageDirectory.parent.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
flutter:
  plugin:
    platforms:
      macos:
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, checkProjects: true);

        final File registrantFile = macosProject.managedDirectory.childFile('GeneratedPluginRegistrant.swift');

        expect(registrantFile, exists);
        expect(registrantFile, isNot(contains('SomePlugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Injecting creates generated Linux registrant', () async {
        when(linuxProject.existsSync()).thenReturn(true);
        when(featureFlags.isLinuxEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(false);
        configureDummyPackageAsPlugin();

        await injectPlugins(flutterProject, checkProjects: true);

        final File registrantHeader = linuxProject.managedDirectory.childFile('generated_plugin_registrant.h');
        final File registrantImpl = linuxProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantHeader.existsSync(), isTrue);
        expect(registrantImpl.existsSync(), isTrue);
        expect(registrantImpl.readAsStringSync(), contains('SomePluginRegisterWithRegistrar'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Injecting creates generated Linux registrant, but does not include Dart-only plugins', () async {
        when(linuxProject.existsSync()).thenReturn(true);
        when(featureFlags.isLinuxEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(false);
        // Create a plugin without a pluginClass.
        dummyPackageDirectory.parent.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
flutter:
  plugin:
    platforms:
      linux:
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, checkProjects: true);

        final File registrantImpl = linuxProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantImpl, exists);
        expect(registrantImpl, isNot(contains('SomePlugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Injecting creates generated Linux plugin Cmake file', () async {
        when(linuxProject.existsSync()).thenReturn(true);
        when(featureFlags.isLinuxEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(false);
        configureDummyPackageAsPlugin();

        await injectPlugins(flutterProject, checkProjects: true);

        final File pluginMakefile = linuxProject.generatedPluginCmakeFile;

        expect(pluginMakefile.existsSync(), isTrue);
        final String contents = pluginMakefile.readAsStringSync();
        expect(contents, contains('apackage'));
        expect(contents, contains('target_link_libraries(\${BINARY_NAME} PRIVATE \${plugin}_plugin)'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });


      testUsingContext('Injecting creates generated Windows registrant', () async {
        when(windowsProject.existsSync()).thenReturn(true);
        when(featureFlags.isWindowsEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(false);
        configureDummyPackageAsPlugin();
        createDummyWindowsSolutionFile();
        createDummyPluginWindowsProjectFile();

        await injectPlugins(flutterProject, checkProjects: true);

        final File registrantHeader = windowsProject.managedDirectory.childFile('generated_plugin_registrant.h');
        final File registrantImpl = windowsProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantHeader.existsSync(), isTrue);
        expect(registrantImpl.existsSync(), isTrue);
        expect(registrantImpl.readAsStringSync(), contains('SomePluginRegisterWithRegistrar'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Injecting creates generated Windows registrant, but does not include Dart-only plugins', () async {
        when(windowsProject.existsSync()).thenReturn(true);
        when(featureFlags.isWindowsEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(false);
        // Create a plugin without a pluginClass.
        dummyPackageDirectory.parent.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
flutter:
  plugin:
    platforms:
      windows:
        dartPluginClass: SomePlugin
    ''');

        createDummyWindowsSolutionFile();
        createDummyPluginWindowsProjectFile();

        await injectPlugins(flutterProject, checkProjects: true);

        final File registrantImpl = windowsProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantImpl, exists);
        expect(registrantImpl, isNot(contains('SomePlugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Injecting creates generated Windows plugin properties', () async {
        when(windowsProject.existsSync()).thenReturn(true);
        when(featureFlags.isWindowsEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(false);
        configureDummyPackageAsPlugin();
        createDummyWindowsSolutionFile();
        createDummyPluginWindowsProjectFile();

        await injectPlugins(flutterProject, checkProjects: true);

        final File properties = windowsProject.generatedPluginPropertySheetFile;
        final String includePath = fs.path.join('flutter', 'ephemeral', '.plugin_symlinks', 'apackage', 'windows');

        expect(properties.existsSync(), isTrue);
        expect(properties.readAsStringSync(), contains('apackage_plugin.lib'));
        expect(properties.readAsStringSync(), contains('>$includePath;'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Injecting updates Windows solution file', () async {
        when(windowsProject.existsSync()).thenReturn(true);
        when(featureFlags.isWindowsEnabled).thenReturn(true);
        when(flutterProject.isModule).thenReturn(false);
        configureDummyPackageAsPlugin();
        createDummyWindowsSolutionFile();
        createDummyPluginWindowsProjectFile();

        await injectPlugins(flutterProject, checkProjects: true);

        expect(windowsProject.solutionFile.readAsStringSync(), contains(r'apackage\windows\plugin.vcxproj'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });
    });

    group('createPluginSymlinks', () {
      MockFeatureFlags featureFlags;

      setUp(() {
        featureFlags = MockFeatureFlags();
        when(featureFlags.isLinuxEnabled).thenReturn(true);
        when(featureFlags.isWindowsEnabled).thenReturn(true);
      });

      testUsingContext('Symlinks are created for Linux plugins', () async {
        when(linuxProject.existsSync()).thenReturn(true);
        configureDummyPackageAsPlugin();
        // refreshPluginsList should call createPluginSymlinks.
        await refreshPluginsList(flutterProject);

        expect(linuxProject.pluginSymlinkDirectory.childLink('apackage').existsSync(), true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Symlinks are created for Windows plugins', () async {
        when(windowsProject.existsSync()).thenReturn(true);
        configureDummyPackageAsPlugin();
        // refreshPluginsList should call createPluginSymlinks.
        await refreshPluginsList(flutterProject);

        expect(windowsProject.pluginSymlinkDirectory.childLink('apackage').existsSync(), true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Existing symlinks are removed when no longer in use with force', () {
        when(linuxProject.existsSync()).thenReturn(true);
        when(windowsProject.existsSync()).thenReturn(true);

        final List<File> dummyFiles = <File>[
          flutterProject.linux.pluginSymlinkDirectory.childFile('dummy'),
          flutterProject.windows.pluginSymlinkDirectory.childFile('dummy'),
        ];
        for (final File file in dummyFiles) {
          file.createSync(recursive: true);
        }

        createPluginSymlinks(flutterProject, force: true);

        for (final File file in dummyFiles) {
          expect(file.existsSync(), false);
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Existing symlinks are removed automatically on refresh when no longer in use', () async {
        when(linuxProject.existsSync()).thenReturn(true);
        when(windowsProject.existsSync()).thenReturn(true);

        final List<File> dummyFiles = <File>[
          flutterProject.linux.pluginSymlinkDirectory.childFile('dummy'),
          flutterProject.windows.pluginSymlinkDirectory.childFile('dummy'),
        ];
        for (final File file in dummyFiles) {
          file.createSync(recursive: true);
        }

        // refreshPluginsList should remove existing links and recreate on changes.
        configureDummyPackageAsPlugin();
        await refreshPluginsList(flutterProject);

        for (final File file in dummyFiles) {
          expect(file.existsSync(), false);
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('createPluginSymlinks is a no-op without force when up to date', () {
        when(linuxProject.existsSync()).thenReturn(true);
        when(windowsProject.existsSync()).thenReturn(true);

        final List<File> dummyFiles = <File>[
          flutterProject.linux.pluginSymlinkDirectory.childFile('dummy'),
          flutterProject.windows.pluginSymlinkDirectory.childFile('dummy'),
        ];
        for (final File file in dummyFiles) {
          file.createSync(recursive: true);
        }

        // Without force, this should do nothing to existing files.
        createPluginSymlinks(flutterProject);

        for (final File file in dummyFiles) {
          expect(file.existsSync(), true);
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('createPluginSymlinks repairs missing links', () async {
        when(linuxProject.existsSync()).thenReturn(true);
        when(windowsProject.existsSync()).thenReturn(true);
        configureDummyPackageAsPlugin();
        await refreshPluginsList(flutterProject);

        final List<Link> links = <Link>[
          linuxProject.pluginSymlinkDirectory.childLink('apackage'),
          windowsProject.pluginSymlinkDirectory.childLink('apackage'),
        ];
        for (final Link link in links) {
          link.deleteSync();
        }
        createPluginSymlinks(flutterProject);

        for (final Link link in links) {
          expect(link.existsSync(), true);
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });
    });
  });
}

class MockAndroidProject extends Mock implements AndroidProject {}
class MockFeatureFlags extends Mock implements FeatureFlags {}
class MockFlutterProject extends Mock implements FlutterProject {}
class MockFile extends Mock implements File {}
class MockFileSystem extends Mock implements FileSystem {}
class MockIosProject extends Mock implements IosProject {}
class MockMacOSProject extends Mock implements MacOSProject {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockWebProject extends Mock implements WebProject {}
class MockWindowsProject extends Mock implements WindowsProject {}
class MockLinuxProject extends Mock implements LinuxProject {}
