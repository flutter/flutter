// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/pubspec_schema.dart';
import '../src/testbed.dart';

void main() {
  group('plugins', () {
    FileSystem fs;
    MockFlutterProject flutterProject;
    MockFlutterManifest flutterManifest;
    MockIosProject iosProject;
    MockMacOSProject macosProject;
    MockAndroidProject androidProject;
    MockWebProject webProject;
    MockWindowsProject windowsProject;
    MockLinuxProject linuxProject;
    FakeSystemClock systemClock;
    FlutterVersion mockVersion;
    // A Windows-style filesystem. This is not populated by default, so tests
    // using it instead of fs must re-run any necessary setup (e.g.,
    // setUpProject).
    FileSystem fsWindows;

    // Adds basic properties to the flutterProject and its subprojects.
    void setUpProject(FileSystem fileSystem) {
      flutterProject = MockFlutterProject();

      flutterManifest = MockFlutterManifest();
      when(flutterManifest.dependencies).thenReturn(<String>{});

      when(flutterProject.manifest).thenReturn(flutterManifest);

      when(flutterProject.directory).thenReturn(fileSystem.systemTempDirectory.childDirectory('app'));
      // TODO(franciscojma): Remove logic for .flutter-plugins once it's deprecated.
      when(flutterProject.flutterPluginsFile).thenReturn(flutterProject.directory.childFile('.flutter-plugins'));
      when(flutterProject.flutterPluginsDependenciesFile).thenReturn(flutterProject.directory.childFile('.flutter-plugins-dependencies'));

      iosProject = MockIosProject();
      when(flutterProject.ios).thenReturn(iosProject);
      final Directory iosDirectory = flutterProject.directory.childDirectory('ios');
      when(iosProject.pluginRegistrantHost).thenReturn(flutterProject.directory.childDirectory('Runner'));
      when(iosProject.podfile).thenReturn(iosDirectory.childFile('Podfile'));
      when(iosProject.podManifestLock).thenReturn(iosDirectory.childFile('Podfile.lock'));
      when(iosProject.pluginConfigKey).thenReturn('ios');
      when(iosProject.existsSync()).thenReturn(false);

      macosProject = MockMacOSProject();
      when(flutterProject.macos).thenReturn(macosProject);
      final Directory macosDirectory = flutterProject.directory.childDirectory('macos');
      when(macosProject.podfile).thenReturn(macosDirectory.childFile('Podfile'));
      when(macosProject.podManifestLock).thenReturn(macosDirectory.childFile('Podfile.lock'));
      final Directory macosManagedDirectory = macosDirectory.childDirectory('Flutter');
      when(macosProject.managedDirectory).thenReturn(macosManagedDirectory);
      when(macosProject.pluginConfigKey).thenReturn('macos');
      when(macosProject.existsSync()).thenReturn(false);

      androidProject = MockAndroidProject();
      when(flutterProject.android).thenReturn(androidProject);
      final Directory androidDirectory = flutterProject.directory.childDirectory('android');
      when(androidProject.pluginRegistrantHost).thenReturn(androidDirectory.childDirectory('app'));
      when(androidProject.hostAppGradleRoot).thenReturn(androidDirectory);
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
      when(windowsProject.cmakeFile).thenReturn(windowsManagedDirectory.parent.childFile('CMakeLists.txt'));
      when(windowsProject.generatedPluginCmakeFile).thenReturn(windowsManagedDirectory.childFile('generated_plugins.mk'));
      when(windowsProject.pluginSymlinkDirectory).thenReturn(windowsManagedDirectory.childDirectory('ephemeral').childDirectory('.plugin_symlinks'));
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
    }

    setUp(() async {
      fs = MemoryFileSystem.test();
      fsWindows = MemoryFileSystem(style: FileSystemStyle.windows);
      systemClock = FakeSystemClock()
        ..currentTime = DateTime(1970, 1, 1);
      mockVersion = MockFlutterVersion();

      // Add basic properties to the Flutter project and subprojects
      setUpProject(fs);
      flutterProject.directory.childFile('.packages').createSync(recursive: true);

      when(mockVersion.frameworkVersion).thenAnswer(
        (Invocation _) => '1.0.0'
      );
    });

    // Makes fake plugin packages for each plugin, adds them to flutterProject,
    // and returns their directories.
    //
    // If an entry contains a path separator, it will be treated as a path for
    // the location of the package, with the name being the last component.
    // Otherwise it will be treated as a name, and put in a default location
    // (a fake pub cache).
    List<Directory> createFakePlugins(FileSystem fileSystem, List<String> pluginNamesOrPaths) {
      const String pluginYamlTemplate = '''
  flutter:
    plugin:
      platforms:
        ios:
          pluginClass: PLUGIN_CLASS
        macos:
          pluginClass: PLUGIN_CLASS
        windows:
          pluginClass: PLUGIN_CLASS
        linux:
          pluginClass: PLUGIN_CLASS
        web:
          pluginClass: PLUGIN_CLASS
          fileName: lib/PLUGIN_CLASS.dart
        android:
          pluginClass: PLUGIN_CLASS
          package: AndroidPackage
  ''';

      final List<Directory> directories = <Directory>[];
      final Directory fakePubCache = fileSystem.systemTempDirectory.childDirectory('cache');
      final File packagesFile = flutterProject.directory.childFile('.packages')
            ..createSync(recursive: true);
      for (final String nameOrPath in pluginNamesOrPaths) {
        final String name = fileSystem.path.basename(nameOrPath);
        final Directory pluginDirectory = (nameOrPath == name)
            ? fakePubCache.childDirectory(name)
            : fileSystem.directory(nameOrPath);
        packagesFile.writeAsStringSync(
            '$name:file://${pluginDirectory.childFile('lib').uri}\n',
            mode: FileMode.writeOnlyAppend);
        pluginDirectory.childFile('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync(pluginYamlTemplate.replaceAll('PLUGIN_CLASS', toTitleCase(camelCase(name))));
        directories.add(pluginDirectory);
      }
      return directories;
    }

    // Makes a fake plugin package, adds it to flutterProject, and returns its directory.
    Directory createFakePlugin(FileSystem fileSystem) {
      return createFakePlugins(fileSystem, <String>['some_plugin'])[0];
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

      testUsingContext('Refreshing the plugin list creates a sorted plugin directory when there are plugins', () async {
        createFakePlugins(fs, <String>[
          'plugin_d',
          'plugin_a',
          '/local_plugins/plugin_c',
          '/local_plugins/plugin_b'
        ]);

        when(iosProject.existsSync()).thenReturn(true);

        await refreshPluginsList(flutterProject);

        expect(flutterProject.flutterPluginsFile.existsSync(), true);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), true);

        final String pluginsFileContents = flutterProject.flutterPluginsFile.readAsStringSync();
        expect(pluginsFileContents.indexOf('plugin_a'), lessThan(pluginsFileContents.indexOf('plugin_b')));
        expect(pluginsFileContents.indexOf('plugin_b'), lessThan(pluginsFileContents.indexOf('plugin_c')));
        expect(pluginsFileContents.indexOf('plugin_c'), lessThan(pluginsFileContents.indexOf('plugin_d')));
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
        systemClock.currentTime = dateCreated;
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
        SystemClock: () => systemClock,
        FlutterVersion: () => mockVersion
      });

      testUsingContext('Changes to the plugin list invalidates the Cocoapod lockfiles', () async {
        simulatePodInstallRun(iosProject);
        simulatePodInstallRun(macosProject);
        createFakePlugin(fs);
        when(iosProject.existsSync()).thenReturn(true);
        when(macosProject.existsSync()).thenReturn(true);

        await refreshPluginsList(flutterProject, iosPlatform: true, macOSPlatform: true);
        expect(iosProject.podManifestLock.existsSync(), false);
        expect(macosProject.podManifestLock.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        SystemClock: () => systemClock,
        FlutterVersion: () => mockVersion
      });

      testUsingContext('No changes to the plugin list does not invalidate the Cocoapod lockfiles', () async {
        createFakePlugin(fs);
        when(iosProject.existsSync()).thenReturn(true);
        when(macosProject.existsSync()).thenReturn(true);

        // First call will create the .flutter-plugins-dependencies and the legacy .flutter-plugins file.
        // Since there was no plugins list, the lock files will be invalidated.
        // The second call is where the plugins list is compared to the existing one, and if there is no change,
        // the podfiles shouldn't be invalidated.
        await refreshPluginsList(flutterProject, iosPlatform: true, macOSPlatform: true);
        simulatePodInstallRun(iosProject);
        simulatePodInstallRun(macosProject);

        await refreshPluginsList(flutterProject);
        expect(iosProject.podManifestLock.existsSync(), true);
        expect(macosProject.podManifestLock.existsSync(), true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        SystemClock: () => systemClock,
        FlutterVersion: () => mockVersion
      });
    });

    group('injectPlugins', () {
      MockXcodeProjectInterpreter xcodeProjectInterpreter;

      setUp(() {
        xcodeProjectInterpreter = MockXcodeProjectInterpreter();
        when(xcodeProjectInterpreter.isInstalled).thenReturn(false);
      });

      testUsingContext('Registrant uses old embedding in app project', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        await injectPlugins(flutterProject, androidPlatform: true);

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
      });

      testUsingContext('Registrant uses new embedding if app uses new embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        await injectPlugins(flutterProject, androidPlatform: true);

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
      });

      testUsingContext('Registrant uses shim for plugins using old embedding if app uses new embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createNewJavaPlugin1();
        createNewKotlinPlugin2();
        createOldJavaPlugin('plugin3');

        await injectPlugins(flutterProject, androidPlatform: true);

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
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('exits the tool if an app uses the v1 embedding and a plugin only supports the v2 embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        createNewJavaPlugin1();

        await expectLater(
          () async {
            await injectPlugins(flutterProject, androidPlatform: true);
          },
          throwsToolExit(
            message: 'The plugin `plugin1` requires your app to be migrated to the Android embedding v2. '
                     'Follow the steps on https://flutter.dev/go/android-project-migration and re-run this command.'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      // Issue: https://github.com/flutter/flutter/issues/47803
      testUsingContext('exits the tool if a plugin sets an invalid android package in pubspec.yaml', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        final Directory pluginDir = createPluginWithInvalidAndroidPackage();

        await expectLater(
          () async {
            await injectPlugins(flutterProject, androidPlatform: true);
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
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('old embedding app uses a plugin that supports v1 and v2 embedding works', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v1);

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject, androidPlatform: true);

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
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('new embedding app uses a plugin that supports v1 and v2 embedding', () async {
        when(flutterProject.isModule).thenReturn(false);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject, androidPlatform: true);

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
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Modules use new embedding', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        await injectPlugins(flutterProject, androidPlatform: true);

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
      });

      testUsingContext('Module using old plugin shows warning', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createOldJavaPlugin('plugin3');

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('plugin3.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("plugin3.UseOldEmbedding"));'));
        expect(testLogger.statusText, contains('The plugin `plugin3` is built using an older version of the Android plugin API'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using new plugin shows no warnings', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createNewJavaPlugin1();

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin1.UseNewEmbedding());'));

        expect(testLogger.statusText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using plugin with v1 and v2 support shows no warning', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin4.UseBothEmbedding());'));

        expect(testLogger.statusText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using multiple old plugins all show warnings', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(androidProject.getEmbeddingVersion()).thenReturn(AndroidEmbeddingVersion.v2);

        createOldJavaPlugin('plugin3');
        createOldJavaPlugin('plugin4');

        await injectPlugins(flutterProject, androidPlatform: true);

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
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Does not throw when AndroidManifest.xml is not found', () async {
        when(flutterProject.isModule).thenReturn(false);

        final File manifest = fs.file('AndroidManifest.xml');
        when(androidProject.appManifestFile).thenReturn(manifest);

        await injectPlugins(flutterProject, androidPlatform: true);

      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext("Registrant for web doesn't escape slashes in imports", () async {
        when(flutterProject.isModule).thenReturn(true);
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

        await injectPlugins(flutterProject, webPlatform: true);

        final File registrant = flutterProject.directory
            .childDirectory('lib')
            .childFile('generated_plugin_registrant.dart');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains("import 'package:web_plugin_with_nested/src/web_plugin.dart';"));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated macos registrant, but does not include Dart-only plugins', () async {
        when(flutterProject.isModule).thenReturn(true);
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      macos:
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, macOSPlatform: true);

        final File registrantFile = macosProject.managedDirectory.childFile('GeneratedPluginRegistrant.swift');

        expect(registrantFile, exists);
        expect(registrantFile, isNot(contains('SomePlugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('pluginClass: none doesn\'t trigger registrant entry on macOS', () async {
        when(flutterProject.isModule).thenReturn(true);
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      macos:
        pluginClass: none
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, macOSPlatform: true);

        final File registrantFile = macosProject.managedDirectory.childFile('GeneratedPluginRegistrant.swift');

        expect(registrantFile, exists);
        expect(registrantFile, isNot(contains('SomePlugin')));
        expect(registrantFile, isNot(contains('none')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Invalid yaml does not crash plugin lookup.', () async {
        when(flutterProject.isModule).thenReturn(true);
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync(r'''
"aws ... \"Branch\": $BITBUCKET_BRANCH, \"Date\": $(date +"%m-%d-%y"), \"Time\": $(date +"%T")}\"
    ''');

        await injectPlugins(flutterProject, macOSPlatform: true);

        final File registrantFile = macosProject.managedDirectory.childFile('GeneratedPluginRegistrant.swift');

        expect(registrantFile, exists);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated Linux registrant', () async {
        when(flutterProject.isModule).thenReturn(false);
        createFakePlugin(fs);

        await injectPlugins(flutterProject, linuxPlatform: true);

        final File registrantHeader = linuxProject.managedDirectory.childFile('generated_plugin_registrant.h');
        final File registrantImpl = linuxProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantHeader.existsSync(), isTrue);
        expect(registrantImpl.existsSync(), isTrue);
        expect(registrantImpl.readAsStringSync(), contains('some_plugin_register_with_registrar'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated Linux registrant, but does not include Dart-only plugins', () async {
        when(flutterProject.isModule).thenReturn(false);
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      linux:
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, linuxPlatform: true);

        final File registrantImpl = linuxProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantImpl, exists);
        expect(registrantImpl, isNot(contains('SomePlugin')));
        expect(registrantImpl, isNot(contains('some_plugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('pluginClass: none doesn\'t trigger registrant entry on Linux', () async {
        when(flutterProject.isModule).thenReturn(false);
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      linux:
        pluginClass: none
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, linuxPlatform: true);

        final File registrantImpl = linuxProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantImpl, exists);
        expect(registrantImpl, isNot(contains('SomePlugin')));
        expect(registrantImpl, isNot(contains('none')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated Linux plugin Cmake file', () async {
        when(flutterProject.isModule).thenReturn(false);
        createFakePlugin(fs);

        await injectPlugins(flutterProject, linuxPlatform: true);

        final File pluginMakefile = linuxProject.generatedPluginCmakeFile;

        expect(pluginMakefile.existsSync(), isTrue);
        final String contents = pluginMakefile.readAsStringSync();
        expect(contents, contains('some_plugin'));
        expect(contents, contains(r'target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)'));
        expect(contents, contains(r'list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)'));
        expect(contents, contains(r'list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Generated Linux plugin files sorts by plugin name', () async {
        when(flutterProject.isModule).thenReturn(false);
        createFakePlugins(fs, <String>[
          'plugin_d',
          'plugin_a',
          '/local_plugins/plugin_c',
          '/local_plugins/plugin_b'
        ]);

        await injectPlugins(flutterProject, linuxPlatform: true);

        final File pluginCmakeFile = linuxProject.generatedPluginCmakeFile;
        final File pluginRegistrant = linuxProject.managedDirectory.childFile('generated_plugin_registrant.cc');
        for (final File file in <File>[pluginCmakeFile, pluginRegistrant]) {
          final String contents = file.readAsStringSync();
          expect(contents.indexOf('plugin_a'), lessThan(contents.indexOf('plugin_b')));
          expect(contents.indexOf('plugin_b'), lessThan(contents.indexOf('plugin_c')));
          expect(contents.indexOf('plugin_c'), lessThan(contents.indexOf('plugin_d')));
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated Windows registrant', () async {
        when(flutterProject.isModule).thenReturn(false);
        createFakePlugin(fs);

        await injectPlugins(flutterProject, windowsPlatform: true);

        final File registrantHeader = windowsProject.managedDirectory.childFile('generated_plugin_registrant.h');
        final File registrantImpl = windowsProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantHeader.existsSync(), isTrue);
        expect(registrantImpl.existsSync(), isTrue);
        expect(registrantImpl.readAsStringSync(), contains('SomePluginRegisterWithRegistrar'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated Windows registrant, but does not include Dart-only plugins', () async {
        when(flutterProject.isModule).thenReturn(false);
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      windows:
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, windowsPlatform: true);

        final File registrantImpl = windowsProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantImpl, exists);
        expect(registrantImpl, isNot(contains('SomePlugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('pluginClass: none doesn\'t trigger registrant entry on Windows', () async {
        when(flutterProject.isModule).thenReturn(false);
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      windows:
        pluginClass: none
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, windowsPlatform: true);

        final File registrantImpl = windowsProject.managedDirectory.childFile('generated_plugin_registrant.cc');

        expect(registrantImpl, exists);
        expect(registrantImpl, isNot(contains('SomePlugin')));
        expect(registrantImpl, isNot(contains('none')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Generated Windows plugin files sorts by plugin name', () async {
        when(flutterProject.isModule).thenReturn(false);
        createFakePlugins(fs, <String>[
          'plugin_d',
          'plugin_a',
          '/local_plugins/plugin_c',
          '/local_plugins/plugin_b'
        ]);

        await injectPlugins(flutterProject, windowsPlatform: true);

        final File pluginCmakeFile = windowsProject.generatedPluginCmakeFile;
        final File pluginRegistrant = windowsProject.managedDirectory.childFile('generated_plugin_registrant.cc');
        for (final File file in <File>[pluginCmakeFile, pluginRegistrant]) {
          final String contents = file.readAsStringSync();
          expect(contents.indexOf('plugin_a'), lessThan(contents.indexOf('plugin_b')));
          expect(contents.indexOf('plugin_b'), lessThan(contents.indexOf('plugin_c')));
          expect(contents.indexOf('plugin_c'), lessThan(contents.indexOf('plugin_d')));
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Generated plugin CMake files always use posix-style paths', () async {
        // Re-run the setup using the Windows filesystem.
        setUpProject(fsWindows);
        createFakePlugin(fsWindows);

        when(flutterProject.isModule).thenReturn(false);

        await injectPlugins(flutterProject, linuxPlatform: true, windowsPlatform: true);

        for (final CmakeBasedProject project in <CmakeBasedProject>[linuxProject, windowsProject]) {
          final File pluginCmakefile = project.generatedPluginCmakeFile;

          expect(pluginCmakefile.existsSync(), isTrue);
          final String contents = pluginCmakefile.readAsStringSync();
          expect(contents, contains('add_subdirectory(flutter/ephemeral/.plugin_symlinks'));
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fsWindows,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    group('createPluginSymlinks', () {
      FeatureFlags featureFlags;

      setUp(() {
        featureFlags = TestFeatureFlags(isLinuxEnabled: true, isWindowsEnabled: true);
      });

      testUsingContext('Symlinks are created for Linux plugins', () async {
        when(linuxProject.existsSync()).thenReturn(true);
        createFakePlugin(fs);
        // refreshPluginsList should call createPluginSymlinks.
        await refreshPluginsList(flutterProject);

        expect(linuxProject.pluginSymlinkDirectory.childLink('some_plugin').existsSync(), true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => featureFlags,
      });

      testUsingContext('Symlinks are created for Windows plugins', () async {
        when(windowsProject.existsSync()).thenReturn(true);
        createFakePlugin(fs);
        // refreshPluginsList should call createPluginSymlinks.
        await refreshPluginsList(flutterProject);

        expect(windowsProject.pluginSymlinkDirectory.childLink('some_plugin').existsSync(), true);
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
        createFakePlugin(fs);
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
        createFakePlugin(fs);
        await refreshPluginsList(flutterProject);

        final List<Link> links = <Link>[
          linuxProject.pluginSymlinkDirectory.childLink('some_plugin'),
          windowsProject.pluginSymlinkDirectory.childLink('some_plugin'),
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

    group('resolvePlatformImplementation', () {
      test('selects implementation from direct dependency', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{
          'url_launcher_linux',
          'url_launcher_macos',
        };
        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_macos',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginMacOS',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'undirect_dependency_plugin',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginWindows',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);

        resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_macos',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginMacOS',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);

        expect(resolutions.length, equals(2));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
        expect(resolutions[1].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_macos',
            'dartClass': 'UrlLauncherPluginMacOS',
            'platform': 'macos',
          })
        );
      });

      test('selects default implementation', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      test('selects default implementation if interface is direct dependency', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{'url_launcher'};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      test('selects user selected implementation despites default implementation', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{
          'user_selected_url_launcher_implementation',
          'url_launcher',
        };

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'user_selected_url_launcher_implementation',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'user_selected_url_launcher_implementation',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      test('selects user selected implementation despites default implementation', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{
          'user_selected_url_launcher_implementation',
          'url_launcher',
        };

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'user_selected_url_launcher_implementation',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'user_selected_url_launcher_implementation',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testUsingContext('provides error when user selected multiple implementations', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
          'url_launcher_linux_2',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_linux_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);

          expect(
            testLogger.errorText,
            'Plugin `url_launcher_linux_2` implements an interface for `linux`, which was already implemented by plugin `url_launcher_linux_1`.\n'
            'To fix this issue, remove either dependency from pubspec.yaml.'
            '\n\n'
          );
        },
        throwsToolExit(
          message: 'Please resolve the errors',
        ));
      });

      testUsingContext('provides all errors when user selected multiple implementations', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
          'url_launcher_linux_2',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_linux_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);

          expect(
            testLogger.errorText,
            'Plugin `url_launcher_linux_2` implements an interface for `linux`, which was already implemented by plugin `url_launcher_linux_1`.\n'
            'To fix this issue, remove either dependency from pubspec.yaml.'
            '\n\n'
          );
        },
        throwsToolExit(
          message: 'Please resolve the errors',
        ));
      });

      testUsingContext('provides error when plugin pubspec.yaml doesn\'t have "implementation" nor "default_implementation"', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);
        },
        throwsToolExit(
          message: 'Please resolve the errors'
        ));
        expect(
          testLogger.errorText,
          'Plugin `url_launcher_linux_1` doesn\'t implement a plugin interface, '
          'nor sets a default implementation in pubspec.yaml.\n\n'
          'To set a default implementation, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    platforms:\n'
          '      linux:\n'
          '        default_package: <plugin-implementation>\n'
          '\n'
          'To implement an interface, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    implements: <plugin-interface>'
          '\n\n'
        );
      });

      testUsingContext('provides all errors when plugin pubspec.yaml doesn\'t have "implementation" nor "default_implementation"', () async {
        final FileSystem fs = MemoryFileSystem();
        final Set<String> directDependencies = <String>{
          'url_launcher_linux',
          'url_launcher_windows',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux',
              '',
              YamlMap.wrap(<String, dynamic>{
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_windows',
              '',
              YamlMap.wrap(<String, dynamic>{
                'platforms': <String, dynamic>{
                  'windows': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginWindows',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);
        },
        throwsToolExit(
          message: 'Please resolve the errors'
        ));
        expect(
          testLogger.errorText,
          'Plugin `url_launcher_linux` doesn\'t implement a plugin interface, '
          'nor sets a default implementation in pubspec.yaml.\n\n'
          'To set a default implementation, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    platforms:\n'
          '      linux:\n'
          '        default_package: <plugin-implementation>\n'
          '\n'
          'To implement an interface, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    implements: <plugin-interface>'
          '\n\n'
          'Plugin `url_launcher_windows` doesn\'t implement a plugin interface, '
          'nor sets a default implementation in pubspec.yaml.\n\n'
          'To set a default implementation, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    platforms:\n'
          '      windows:\n'
          '        default_package: <plugin-implementation>\n'
          '\n'
          'To implement an interface, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    implements: <plugin-interface>'
          '\n\n'
        );
      });
    });

    group('generateMainDartWithPluginRegistrant', () {
      testUsingContext('Generates new entrypoint', () async {
        when(flutterProject.isModule).thenReturn(false);

        final List<Directory> directories = <Directory>[];
        final Directory fakePubCache = fs.systemTempDirectory.childDirectory('cache');
        final File packagesFile = flutterProject.directory
            .childFile('.packages')
            ..createSync(recursive: true);

        final Map<String, String> plugins = <String, String>{};
        plugins['url_launcher_macos'] = '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          dartPluginClass: MacOSPlugin
''';
        plugins['url_launcher_linux'] = '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        linux:
          dartPluginClass: LinuxPlugin
''';
        plugins['url_launcher_windows'] = '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        windows:
          dartPluginClass: WindowsPlugin
''';
        plugins['awesome_macos'] = '''
  flutter:
    plugin:
      implements: awesome
      platforms:
        macos:
          dartPluginClass: AwesomeMacOS
''';
        for (final MapEntry<String, String> entry in plugins.entries) {
          final String name = fs.path.basename(entry.key);
          final Directory pluginDirectory = fakePubCache.childDirectory(name);
          packagesFile.writeAsStringSync(
              '$name:file://${pluginDirectory.childFile('lib').uri}\n',
              mode: FileMode.writeOnlyAppend);
          pluginDirectory.childFile('pubspec.yaml')
              ..createSync(recursive: true)
              ..writeAsStringSync(entry.value);
          directories.add(pluginDirectory);
        }

        when(flutterManifest.dependencies).thenReturn(<String>{...plugins.keys});

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('''
// @dart = 2.8
void main() {
}
''');
        final File flutterBuild = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        final bool didGenerate = await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          flutterBuild,
          mainFile,
        );
        expect(didGenerate, isTrue);
        expect(flutterBuild.readAsStringSync(),
            '//\n'
            '// Generated file. Do not edit.\n'
            '//\n'
            '\n'
            '// @dart = 2.8\n'
            '\n'
            'import \'package:app/main.dart\' as entrypoint;\n'
            'import \'dart:io\'; // ignore: dart_io_import.\n'
            'import \'package:url_launcher_linux${fs.path.separator}url_launcher_linux.dart\';\n'
            'import \'package:awesome_macos/awesome_macos.dart\';\n'
            'import \'package:url_launcher_macos${fs.path.separator}url_launcher_macos.dart\';\n'
            'import \'package:url_launcher_windows${fs.path.separator}url_launcher_windows.dart\';\n'
            '\n'
            '@pragma(\'vm:entry-point\')\n'
            'void _registerPlugins() {\n'
            '  if (Platform.isLinux) {\n'
            '      LinuxPlugin.registerWith();\n'
            '  } else if (Platform.isMacOS) {\n'
            '      AwesomeMacOS.registerWith();\n'
            '      MacOSPlugin.registerWith();\n'
            '  } else if (Platform.isWindows) {\n'
            '      WindowsPlugin.registerWith();\n'
            '  }\n'
            '}\n'
            'void main() {\n'
            '  entrypoint.main();\n'
            '}\n'
            '',
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Plugin without platform support throws tool exit', () async {
        when(flutterProject.isModule).thenReturn(false);

        final List<Directory> directories = <Directory>[];
        final Directory fakePubCache = fs.systemTempDirectory.childDirectory('cache');
        final File packagesFile = flutterProject.directory
            .childFile('.packages')
            ..createSync(recursive: true);
        final Map<String, String> plugins = <String, String>{};
        plugins['url_launcher_macos'] = '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          invalid:
''';
        for (final MapEntry<String, String> entry in plugins.entries) {
          final String name = fs.path.basename(entry.key);
          final Directory pluginDirectory = fakePubCache.childDirectory(name);
          packagesFile.writeAsStringSync(
              '$name:file://${pluginDirectory.childFile('lib').uri}\n',
              mode: FileMode.writeOnlyAppend);
          pluginDirectory.childFile('pubspec.yaml')
              ..createSync(recursive: true)
              ..writeAsStringSync(entry.value);
          directories.add(pluginDirectory);
        }

        when(flutterManifest.dependencies).thenReturn(<String>{...plugins.keys});

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final File flutterBuild = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await expectLater(
          generateMainDartWithPluginRegistrant(
            flutterProject,
            packageConfig,
            'package:app/main.dart',
            flutterBuild,
            mainFile,
          ), throwsToolExit(message:
            'Invalid plugin specification url_launcher_macos.\n'
            'Invalid "macos" plugin specification.'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Plugin with platform support without dart plugin class throws tool exit', () async {
        when(flutterProject.isModule).thenReturn(false);

        final List<Directory> directories = <Directory>[];
        final Directory fakePubCache = fs.systemTempDirectory.childDirectory('cache');
        final File packagesFile = flutterProject.directory
            .childFile('.packages')
            ..createSync(recursive: true);
        final Map<String, String> plugins = <String, String>{};
        plugins['url_launcher_macos'] = '''
  flutter:
    plugin:
      implements: url_launcher
''';
        for (final MapEntry<String, String> entry in plugins.entries) {
          final String name = fs.path.basename(entry.key);
          final Directory pluginDirectory = fakePubCache.childDirectory(name);
          packagesFile.writeAsStringSync(
              '$name:file://${pluginDirectory.childFile('lib').uri}\n',
              mode: FileMode.writeOnlyAppend);
          pluginDirectory.childFile('pubspec.yaml')
              ..createSync(recursive: true)
              ..writeAsStringSync(entry.value);
          directories.add(pluginDirectory);
        }

        when(flutterManifest.dependencies).thenReturn(<String>{...plugins.keys});

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final File flutterBuild = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await expectLater(
          generateMainDartWithPluginRegistrant(
            flutterProject,
            packageConfig,
            'package:app/main.dart',
            flutterBuild,
            mainFile,
          ), throwsToolExit(message:
            'Invalid plugin specification url_launcher_macos.\n'
            'Cannot find the `flutter.plugin.platforms` key in the `pubspec.yaml` file. '
            'An instruction to format the `pubspec.yaml` can be found here: '
            'https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    group('pubspec', () {

      Directory projectDir;
      Directory tempDir;
      setUp(() {
        tempDir = globals.fs.systemTempDirectory.createTempSync('plugin_test.');
        projectDir = tempDir.childDirectory('flutter_project');
      });

      tearDown(() {
        tryToDelete(tempDir);
      });

      void _createPubspecFile(String yamlString) {
        projectDir.childFile('pubspec.yaml')..createSync(recursive: true)..writeAsStringSync(yamlString);
      }

      test('validatePubspecForPlugin works', () async {
        const String pluginYaml = '''
  flutter:
    plugin:
      platforms:
        ios:
          pluginClass: SomePlugin
        macos:
          pluginClass: SomePlugin
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
  ''';
        _createPubspecFile(pluginYaml);
        validatePubspecForPlugin(projectDir: projectDir.absolute.path, pluginClass: 'SomePlugin', expectedPlatforms: <String>[
          'ios', 'macos', 'windows', 'linux', 'android', 'web'
        ], androidIdentifier: 'AndroidPackage', webFileName: 'lib/SomeFile.dart');
      });

      test('createPlatformsYamlMap should create the correct map', () async {
        final YamlMap map = Plugin.createPlatformsYamlMap(<String>['ios', 'android', 'linux'], 'PluginClass', 'some.android.package');
        expect(map['ios'], <String, String> {
          'pluginClass' : 'PluginClass'
        });
        expect(map['android'], <String, String> {
          'pluginClass' : 'PluginClass',
          'package': 'some.android.package',
        });
        expect(map['linux'], <String, String> {
          'pluginClass' : 'PluginClass'
        });
      });

      test('createPlatformsYamlMap should create empty map', () async {
        final YamlMap map = Plugin.createPlatformsYamlMap(<String>[], null, null);
        expect(map.isEmpty, true);
      });

    });

    testWithoutContext('Symlink failures give developer mode instructions on recent versions of Windows', () async {
      final Platform platform = FakePlatform(operatingSystem: 'windows');
      final MockOperatingSystemUtils os = MockOperatingSystemUtils();
      when(os.name).thenReturn('Microsoft Windows [Version 10.0.14972.1]');

      const FileSystemException e = FileSystemException('', '', OSError('', 1314));

      expect(() => handleSymlinkException(e, platform: platform, os: os),
        throwsToolExit(message: 'start ms-settings:developers'));
    });

    testWithoutContext('Symlink failures instruct developers to run as administrator on older versions of Windows', () async {
      final Platform platform = FakePlatform(operatingSystem: 'windows');
      final MockOperatingSystemUtils os = MockOperatingSystemUtils();
      when(os.name).thenReturn('Microsoft Windows [Version 10.0.14393]');

      const FileSystemException e = FileSystemException('', '', OSError('', 1314));

      expect(() => handleSymlinkException(e, platform: platform, os: os),
        throwsToolExit(message: 'administrator'));
    });

    testWithoutContext('Symlink failures only give instructions for specific errors', () async {
      final Platform platform = FakePlatform(operatingSystem: 'windows');
      final MockOperatingSystemUtils os = MockOperatingSystemUtils();
      when(os.name).thenReturn('Microsoft Windows [Version 10.0.14393]');

      const FileSystemException e = FileSystemException('', '', OSError('', 999));

      expect(() => handleSymlinkException(e, platform: platform, os: os), returnsNormally);
    });
  });
}

class MockAndroidProject extends Mock implements AndroidProject {}
class MockFlutterManifest extends Mock implements FlutterManifest {}
class MockFlutterProject extends Mock implements FlutterProject {}
class MockIosProject extends Mock implements IosProject {}
class MockMacOSProject extends Mock implements MacOSProject {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockWebProject extends Mock implements WebProject {}
class MockWindowsProject extends Mock implements WindowsProject {}
class MockLinuxProject extends Mock implements LinuxProject {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

class FakeSystemClock extends Fake implements SystemClock {
  DateTime currentTime;

  @override
  DateTime now() {
    return currentTime;
  }
}