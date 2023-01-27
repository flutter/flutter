// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart' hide FakeOperatingSystemUtils;
import '../src/pubspec_schema.dart';

/// Information for a platform entry in the 'platforms' section of a plugin's
/// pubspec.yaml.
class _PluginPlatformInfo {
  const _PluginPlatformInfo({
    this.pluginClass,
    this.dartPluginClass,
    this.androidPackage,
    this.fileName
  }) : assert(pluginClass != null || dartPluginClass != null),
       assert(androidPackage == null || pluginClass != null);

  /// The pluginClass entry, if any.
  final String? pluginClass;

  /// The dartPluginClass entry, if any.
  final String? dartPluginClass;

  /// The package entry for an Android plugin implementation using pluginClass.
  final String? androidPackage;

  /// The fileName entry for a web plugin implementation.
  final String? fileName;

  /// Returns the body of a platform section for a plugin's pubspec, properly
  /// indented.
  String get indentedPubspecSection {
    const String indentation = '        ';
    return <String>[
      if (pluginClass != null)
        '${indentation}pluginClass: $pluginClass',
      if (dartPluginClass != null)
        '${indentation}dartPluginClass: $dartPluginClass',
      if (androidPackage != null)
        '${indentation}package: $androidPackage',
      if (fileName != null)
        '${indentation}fileName: $fileName',
    ].join('\n');
  }
}

void main() {
  group('plugins', () {
    late FileSystem fs;
    late FakeFlutterProject flutterProject;
    late FakeFlutterManifest flutterManifest;
    late FakeIosProject iosProject;
    late FakeMacOSProject macosProject;
    late FakeAndroidProject androidProject;
    late FakeWebProject webProject;
    late FakeWindowsProject windowsProject;
    late FakeLinuxProject linuxProject;
    late FakeSystemClock systemClock;
    late FlutterVersion flutterVersion;
    // A Windows-style filesystem. This is not populated by default, so tests
    // using it instead of fs must re-run any necessary setup (e.g.,
    // setUpProject).
    late FileSystem fsWindows;
    const String pubCachePath = '/path/to/.pub-cache/hosted/pub.dartlang.org/foo-1.2.3';
    const String ephemeralPackagePath = '/path/to/app/linux/flutter/ephemeral/foo-1.2.3';

    // Adds basic properties to the flutterProject and its subprojects.
    void setUpProject(FileSystem fileSystem) {
      flutterProject = FakeFlutterProject();
      flutterManifest = FakeFlutterManifest();

      flutterProject
        ..manifest = flutterManifest
        ..directory = fileSystem.systemTempDirectory.childDirectory('app')
        ..flutterPluginsFile = flutterProject.directory.childFile('.flutter-plugins')
        ..flutterPluginsDependenciesFile = flutterProject.directory.childFile('.flutter-plugins-dependencies');

      iosProject = FakeIosProject();
      flutterProject.ios = iosProject;
      final Directory iosDirectory = flutterProject.directory.childDirectory('ios');
      iosProject
        ..pluginRegistrantHost = flutterProject.directory.childDirectory('Runner')
        ..podfile = iosDirectory.childFile('Podfile')
        ..podManifestLock = iosDirectory.childFile('Podfile.lock')
        ..testExists = false;

      macosProject = FakeMacOSProject();
      flutterProject.macos = macosProject;
      final Directory macosDirectory = flutterProject.directory.childDirectory('macos');
      final Directory macosManagedDirectory = macosDirectory.childDirectory('Flutter');
      macosProject
        ..podfile = macosDirectory.childFile('Podfile')
        ..podManifestLock = macosDirectory.childFile('Podfile.lock')
        ..managedDirectory = macosManagedDirectory
        ..exists = false;

      androidProject = FakeAndroidProject();
      flutterProject.android = androidProject;
      final Directory androidDirectory = flutterProject.directory.childDirectory('android');
      androidProject
        ..pluginRegistrantHost = androidDirectory.childDirectory('app')
        ..hostAppGradleRoot = androidDirectory
        ..exists = false
        ..embeddingVersion = AndroidEmbeddingVersion.v2;

      webProject = FakeWebProject();
      flutterProject.web = webProject;
      webProject
        ..libDirectory = flutterProject.directory.childDirectory('lib')
        ..exists = false;

      windowsProject = FakeWindowsProject();
      flutterProject.windows = windowsProject;
      final Directory windowsManagedDirectory = flutterProject.directory.childDirectory('windows').childDirectory('flutter');
      windowsProject
        ..managedDirectory = windowsManagedDirectory
        ..cmakeFile = windowsManagedDirectory.parent.childFile('CMakeLists.txt')
        ..generatedPluginCmakeFile = windowsManagedDirectory.childFile('generated_plugins.mk')
        ..pluginSymlinkDirectory = windowsManagedDirectory.childDirectory('ephemeral').childDirectory('.plugin_symlinks')
        ..exists = false;

      linuxProject = FakeLinuxProject();
      flutterProject.linux = linuxProject;
      final Directory linuxManagedDirectory = flutterProject.directory.childDirectory('linux').childDirectory('flutter');
      final Directory linuxEphemeralDirectory = linuxManagedDirectory.childDirectory('ephemeral');
      linuxProject
        ..managedDirectory = linuxManagedDirectory
        ..ephemeralDirectory = linuxEphemeralDirectory
        ..pluginSymlinkDirectory = linuxEphemeralDirectory.childDirectory('.plugin_symlinks')
        ..cmakeFile = linuxManagedDirectory.parent.childFile('CMakeLists.txt')
        ..generatedPluginCmakeFile = linuxManagedDirectory.childFile('generated_plugins.mk')
        ..exists = false;
    }

    setUp(() async {
      fs = MemoryFileSystem.test();
      fsWindows = MemoryFileSystem(style: FileSystemStyle.windows);
      systemClock = FakeSystemClock()
        ..currentTime = DateTime(1970);
      flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0');

      // Add basic properties to the Flutter project and subprojects
      setUpProject(fs);
      flutterProject.directory.childFile('.packages').createSync(recursive: true);
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
            ..writeAsStringSync(pluginYamlTemplate.replaceAll('PLUGIN_CLASS', sentenceCase(camelCase(name))));
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
          'plugin1:${pluginUsingJavaAndNewEmbeddingDir.childDirectory('lib').uri}\n',
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
          'plugin1:${pluginUsingJavaAndNewEmbeddingDir.childDirectory('lib').uri}\n',
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
          'plugin2:${pluginUsingKotlinAndNewEmbeddingDir.childDirectory('lib').uri}\n',
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
          '$pluginName:${pluginUsingOldEmbeddingDir.childDirectory('lib').uri}\n',
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
          'plugin4:${pluginUsingJavaAndNewEmbeddingDir.childDirectory('lib').uri}',
          mode: FileMode.append,
        );
    }

    Directory createLegacyPluginWithDependencies({
      required String name,
      required List<String> dependencies,
    }) {
      assert(name != null);
      assert(dependencies != null);

      final Directory pluginDirectory = fs.systemTempDirectory.createTempSync('flutter_plugin.');
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
          '$name:${pluginDirectory.childDirectory('lib').uri}\n',
          mode: FileMode.append,
        );
      return pluginDirectory;
    }

    Directory createPlugin({
      required String name,
      required Map<String, _PluginPlatformInfo> platforms,
      List<String> dependencies = const <String>[],
    }) {
      assert(name != null);
      assert(dependencies != null);

      final Iterable<String> platformSections = platforms.entries.map((MapEntry<String, _PluginPlatformInfo> entry) => '''
      ${entry.key}:
${entry.value.indentedPubspecSection}
''');
      final Directory pluginDirectory = fs.systemTempDirectory.createTempSync('flutter_plugin.');
      pluginDirectory
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
name: $name
flutter:
  plugin:
    platforms:
${platformSections.join('\n')}

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
          '$name:${pluginDirectory.childDirectory('lib').uri}\n',
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
          '/local_plugins/plugin_b',
        ]);

        iosProject.testExists = true;

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
        final Directory pluginA = createLegacyPluginWithDependencies(name: 'plugin-a', dependencies: const <String>['plugin-b', 'plugin-c', 'random-package']);
        final Directory pluginB = createLegacyPluginWithDependencies(name: 'plugin-b', dependencies: const <String>['plugin-c']);
        final Directory pluginC = createLegacyPluginWithDependencies(name: 'plugin-c', dependencies: const <String>[]);
        iosProject.testExists = true;

        final DateTime dateCreated = DateTime(1970);
        systemClock.currentTime = dateCreated;

        await refreshPluginsList(flutterProject);

        // Verify .flutter-plugins-dependencies is configured correctly.
        expect(flutterProject.flutterPluginsFile.existsSync(), true);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), true);
        expect(flutterProject.flutterPluginsFile.readAsStringSync(),
          '# This is a generated file; do not edit or check into version control.\n'
          'plugin-a=${pluginA.path}/\n'
          'plugin-b=${pluginB.path}/\n'
          'plugin-c=${pluginC.path}/\n'
        );

        final String pluginsString = flutterProject.flutterPluginsDependenciesFile.readAsStringSync();
        final Map<String, dynamic> jsonContent = json.decode(pluginsString) as  Map<String, dynamic>;
        expect(jsonContent['info'], 'This is a generated file; do not edit or check into version control.');

        final Map<String, dynamic> plugins = jsonContent['plugins'] as Map<String, dynamic>;
        final List<dynamic> expectedPlugins = <dynamic>[
          <String, dynamic> {
            'name': 'plugin-a',
            'path': '${pluginA.path}/',
            'native_build': true,
            'dependencies': <String>[
              'plugin-b',
              'plugin-c',
            ],
          },
          <String, dynamic> {
            'name': 'plugin-b',
            'path': '${pluginB.path}/',
            'native_build': true,
            'dependencies': <String>[
              'plugin-c',
            ],
          },
          <String, dynamic> {
            'name': 'plugin-c',
            'path': '${pluginC.path}/',
            'native_build': true,
            'dependencies': <String>[],
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
              'plugin-c',
            ],
          },
          <String, dynamic> {
            'name': 'plugin-b',
            'dependencies': <String>[
              'plugin-c',
            ],
          },
          <String, dynamic> {
            'name': 'plugin-c',
            'dependencies': <String>[],
          },
        ];

        expect(jsonContent['dependencyGraph'], expectedDependencyGraph);
        expect(jsonContent['date_created'], dateCreated.toString());
        expect(jsonContent['version'], '1.0.0');

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
        FlutterVersion: () => flutterVersion,
      });

      testUsingContext(
        '.flutter-plugins-dependencies indicates native build inclusion', () async {
        createPlugin(
          name: 'plugin-a',
          platforms: const <String, _PluginPlatformInfo>{
            // Native-only; should include native build.
            'android': _PluginPlatformInfo(pluginClass: 'Foo', androidPackage: 'bar.foo'),
            // Hybrid native and Dart; should include native build.
            'ios': _PluginPlatformInfo(pluginClass: 'Foo', dartPluginClass: 'Bar'),
            // Web; should not have the native build key at all since it doesn't apply.
            'web': _PluginPlatformInfo(pluginClass: 'Foo', fileName: 'lib/foo.dart'),
            // Dart-only; should not include native build.
            'windows': _PluginPlatformInfo(dartPluginClass: 'Foo'),
          });
        iosProject.testExists = true;

        final DateTime dateCreated = DateTime(1970);
        systemClock.currentTime = dateCreated;

        await refreshPluginsList(flutterProject);

        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), true);
        final String pluginsString = flutterProject.flutterPluginsDependenciesFile.readAsStringSync();
        final Map<String, dynamic> jsonContent = json.decode(pluginsString) as  Map<String, dynamic>;
        final Map<String, dynamic>? plugins = jsonContent['plugins'] as Map<String, dynamic>?;

        // Extracts the native_build key (if any) from the first plugin for the
        // given platform.
        bool? getNativeBuildValue(String platform) {
          final List<Map<String, dynamic>> platformPlugins = (plugins![platform]
            as List<dynamic>).cast<Map<String, dynamic>>();
          expect(platformPlugins.length, 1);
          return platformPlugins[0]['native_build'] as bool?;
        }
        expect(getNativeBuildValue('android'), true);
        expect(getNativeBuildValue('ios'), true);
        expect(getNativeBuildValue('web'), null);
        expect(getNativeBuildValue('windows'), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        SystemClock: () => systemClock,
        FlutterVersion: () => flutterVersion,
      });

      testUsingContext('Changes to the plugin list invalidates the Cocoapod lockfiles', () async {
        simulatePodInstallRun(iosProject);
        simulatePodInstallRun(macosProject);
        createFakePlugin(fs);
        iosProject.testExists = true;
        macosProject.exists = true;

        await refreshPluginsList(flutterProject, iosPlatform: true, macOSPlatform: true);
        expect(iosProject.podManifestLock.existsSync(), false);
        expect(macosProject.podManifestLock.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        SystemClock: () => systemClock,
        FlutterVersion: () => flutterVersion,
      });

      testUsingContext('No changes to the plugin list does not invalidate the Cocoapod lockfiles', () async {
        createFakePlugin(fs);
        iosProject.testExists = true;
        macosProject.exists = true;

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
        FlutterVersion: () => flutterVersion,
      });
    });

    group('injectPlugins', () {
      FakeXcodeProjectInterpreter? xcodeProjectInterpreter;

      setUp(() {
        xcodeProjectInterpreter = FakeXcodeProjectInterpreter();
      });

      testUsingContext('Registrant uses old embedding in app project', () async {
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v1;

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
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

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
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

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
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v1;

        createNewJavaPlugin1();

        await expectLater(
          () async {
            await injectPlugins(flutterProject, androidPlatform: true);
          },
          throwsToolExit(
            message: 'The plugin `plugin1` requires your app to be migrated to the Android embedding v2. '
                     'Follow the steps on the migration doc above and re-run this command.'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      // Issue: https://github.com/flutter/flutter/issues/47803
      testUsingContext('exits the tool if a plugin sets an invalid android package in pubspec.yaml', () async {
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v1;

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
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v1;

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
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

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
        flutterProject.isModule = true;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

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
        flutterProject.isModule = true;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

        createOldJavaPlugin('plugin3');

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('plugin3.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("plugin3.UseOldEmbedding"));'));
        expect(testLogger.warningText, equals(
          'The plugin `plugin3` uses a deprecated version of the Android embedding.\n'
          'To avoid unexpected runtime failures, or future build failures, try to see if this plugin supports the Android V2 embedding. '
          'Otherwise, consider removing it since a future release of Flutter will remove these deprecated APIs.\n'
          'If you are plugin author, take a look at the docs for migrating the plugin to the V2 embedding: https://flutter.dev/go/android-plugin-migration.\n'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using new plugin shows no warnings', () async {
        flutterProject.isModule = true;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

        createNewJavaPlugin1();

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin1.UseNewEmbedding());'));

        expect(testLogger.errorText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using plugin with v1 and v2 support shows no warning', () async {
        flutterProject.isModule = true;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin4.UseBothEmbedding());'));

        expect(testLogger.errorText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('App using plugin with v1 and v2 support shows no warning', () async {
        flutterProject.isModule = false;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

        createDualSupportJavaPlugin4();

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        expect(registrant.readAsStringSync(),
          contains('flutterEngine.getPlugins().add(new plugin4.UseBothEmbedding());'));

        expect(testLogger.errorText, isNot(contains('go/android-plugin-migration')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('App using the v1 embedding shows warning', () async {
        flutterProject.isModule = false;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v1;

        await injectPlugins(flutterProject, androidPlatform: true);

        expect(testLogger.warningText, equals(
          'This app is using a deprecated version of the Android embedding.\n'
          'To avoid unexpected runtime failures, or future build failures, try to migrate this app to the V2 embedding.\n'
          'Take a look at the docs for migrating an app: https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects\n'
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using multiple old plugins all show warnings', () async {
        flutterProject.isModule = true;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

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
        expect(testLogger.warningText, equals(
          'The plugins `plugin3, plugin4` use a deprecated version of the Android embedding.\n'
          'To avoid unexpected runtime failures, or future build failures, try to see if these plugins support the Android V2 embedding. '
          'Otherwise, consider removing them since a future release of Flutter will remove these deprecated APIs.\n'
          'If you are plugin author, take a look at the docs for migrating the plugin to the V2 embedding: https://flutter.dev/go/android-plugin-migration.\n'
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('App using multiple old plugins all show warnings', () async {
        flutterProject.isModule = false;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

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
        expect(testLogger.warningText, equals(
          'The plugins `plugin3, plugin4` use a deprecated version of the Android embedding.\n'
          'To avoid unexpected runtime failures, or future build failures, try to see if these plugins support the Android V2 embedding. '
          'Otherwise, consider removing them since a future release of Flutter will remove these deprecated APIs.\n'
          'If you are plugin author, take a look at the docs for migrating the plugin to the V2 embedding: https://flutter.dev/go/android-plugin-migration.\n'
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Module using multiple old and new plugins should be wrapped with try catch', () async {
        flutterProject.isModule = true;
        androidProject.embeddingVersion = AndroidEmbeddingVersion.v2;

        createOldJavaPlugin('abcplugin1');
        createNewJavaPlugin1();

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrant = flutterProject.directory
          .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');
        const String newPluginName = 'flutterEngine.getPlugins().add(new plugin1.UseNewEmbedding());';
        const String oldPluginName = 'abcplugin1.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("abcplugin1.UseOldEmbedding"));';
        final String content = registrant.readAsStringSync();
        for(final String plugin in <String>[newPluginName,oldPluginName]) {
          expect(content, contains(plugin));
          expect(content.split(plugin).first.trim().endsWith('try {'), isTrue);
          expect(content.split(plugin).last.trim().startsWith('} catch(Exception e) {'), isTrue);
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('Does not throw when AndroidManifest.xml is not found', () async {
        final File manifest = fs.file('AndroidManifest.xml');
        androidProject.appManifestFile = manifest;
        await injectPlugins(flutterProject, androidPlatform: true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext("Registrant for web doesn't escape slashes in imports", () async {
        flutterProject.isModule = true;
        final Directory webPluginWithNestedFile =
            fs.systemTempDirectory.createTempSync('flutter_web_plugin_with_nested.');
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
web_plugin_with_nested:${webPluginWithNestedFile.childDirectory('lib').uri}
''');

        final Directory destination = flutterProject.directory.childDirectory('lib');
        await injectBuildTimePluginFiles(flutterProject, webPlatform: true, destination: destination);

        final File registrant = flutterProject.directory
            .childDirectory('lib')
            .childFile('web_plugin_registrant.dart');

        expect(registrant.existsSync(), isTrue);
        expect(registrant.readAsStringSync(), contains("import 'package:web_plugin_with_nested/src/web_plugin.dart';"));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated Android registrant, but does not include Dart-only plugins', () async {
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      android:
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, androidPlatform: true);

        final File registrantFile = androidProject.pluginRegistrantHost
          .childDirectory(fs.path.join('src', 'main', 'java', 'io', 'flutter', 'plugins'))
          .childFile('GeneratedPluginRegistrant.java');

        expect(registrantFile, exists);
        expect(registrantFile, isNot(contains('SomePlugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated iOS registrant, but does not include Dart-only plugins', () async {
        flutterProject.isModule = true;
        // Create a plugin without a pluginClass.
        final Directory pluginDirectory = createFakePlugin(fs);
        pluginDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  plugin:
    platforms:
      ios:
        dartPluginClass: SomePlugin
    ''');

        await injectPlugins(flutterProject, iosPlatform: true);

        final File registrantFile = iosProject.pluginRegistrantImplementation;

        expect(registrantFile, exists);
        expect(registrantFile, isNot(contains('SomePlugin')));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Injecting creates generated macos registrant, but does not include Dart-only plugins', () async {
        flutterProject.isModule = true;
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

      testUsingContext("pluginClass: none doesn't trigger registrant entry on macOS", () async {
        flutterProject.isModule = true;
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
        flutterProject.isModule = true;
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

      testUsingContext("pluginClass: none doesn't trigger registrant entry on Linux", () async {
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
        createFakePlugins(fs, <String>[
          'plugin_d',
          'plugin_a',
          '/local_plugins/plugin_c',
          '/local_plugins/plugin_b',
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

      testUsingContext("pluginClass: none doesn't trigger registrant entry on Windows", () async {
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
        createFakePlugins(fs, <String>[
          'plugin_d',
          'plugin_a',
          '/local_plugins/plugin_c',
          '/local_plugins/plugin_b',
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

        await injectPlugins(flutterProject, linuxPlatform: true, windowsPlatform: true);

        for (final CmakeBasedProject? project in <CmakeBasedProject?>[linuxProject, windowsProject]) {
          final File pluginCmakefile = project!.generatedPluginCmakeFile;

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
      FeatureFlags? featureFlags;

      setUp(() {
        featureFlags = TestFeatureFlags(isLinuxEnabled: true, isWindowsEnabled: true);
      });

      testUsingContext('Symlinks are created for Linux plugins', () async {
        linuxProject.exists = true;
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
        windowsProject.exists = true;
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
        linuxProject.exists = true;
        windowsProject.exists = true;

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
        linuxProject.exists = true;
        windowsProject.exists = true;

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
        linuxProject.exists = true;
        windowsProject.exists = true;

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
        linuxProject.exists = true;
        windowsProject.exists = true;
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

    group('pubspec', () {
      late Directory projectDir;
      late Directory tempDir;

      setUp(() {
        tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_plugin_test.');
        projectDir = tempDir.childDirectory('flutter_project');
      });

      tearDown(() {
        tryToDelete(tempDir);
      });

      void createPubspecFile(String yamlString) {
        projectDir.childFile('pubspec.yaml')..createSync(recursive: true)..writeAsStringSync(yamlString);
      }

      testUsingContext('validatePubspecForPlugin works', () async {
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
        createPubspecFile(pluginYaml);
        validatePubspecForPlugin(projectDir: projectDir.absolute.path, pluginClass: 'SomePlugin', expectedPlatforms: <String>[
          'ios', 'macos', 'windows', 'linux', 'android', 'web',
        ], androidIdentifier: 'AndroidPackage', webFileName: 'lib/SomeFile.dart');
      });

      testUsingContext('createPlatformsYamlMap should create the correct map', () async {
        final YamlMap map = Plugin.createPlatformsYamlMap(<String>['ios', 'android', 'linux'], 'PluginClass', 'some.android.package');
        expect(map['ios'], <String, String> {
          'pluginClass' : 'PluginClass',
        });
        expect(map['android'], <String, String> {
          'pluginClass' : 'PluginClass',
          'package': 'some.android.package',
        });
        expect(map['linux'], <String, String> {
          'pluginClass' : 'PluginClass',
        });
      });

      testUsingContext('createPlatformsYamlMap should create empty map', () async {
        final YamlMap map = Plugin.createPlatformsYamlMap(<String>[], 'foo', 'bar');
        expect(map.isEmpty, true);
      });

    });

    testWithoutContext('Symlink failures give developer mode instructions on recent versions of Windows', () async {
      final Platform platform = FakePlatform(operatingSystem: 'windows');
      final FakeOperatingSystemUtils os = FakeOperatingSystemUtils('Microsoft Windows [Version 10.0.14972.1]');

      const FileSystemException e = FileSystemException('', '', OSError('', 1314));

      expect(
        () => handleSymlinkException(
          e,
          platform: platform,
          os: os,
          source: pubCachePath,
          destination: ephemeralPackagePath,
        ),
        throwsToolExit(message: 'start ms-settings:developers'),
      );
    });

    testWithoutContext('Symlink ERROR_ACCESS_DENIED failures show developers paths that were used', () async {
      final Platform platform = FakePlatform(operatingSystem: 'windows');
      final FakeOperatingSystemUtils os = FakeOperatingSystemUtils('Microsoft Windows [Version 10.0.14972.1]');

      const FileSystemException e = FileSystemException('', '', OSError('', 5));

      expect(
        () => handleSymlinkException(
          e,
          platform: platform,
          os: os,
          source: pubCachePath,
          destination: ephemeralPackagePath,
        ),
        throwsToolExit(
          message: 'ERROR_ACCESS_DENIED file system exception thrown while trying to create a symlink from $pubCachePath to $ephemeralPackagePath',
        ),
      );
    });

    testWithoutContext('Symlink failures instruct developers to run as administrator on older versions of Windows', () async {
      final Platform platform = FakePlatform(operatingSystem: 'windows');
      final FakeOperatingSystemUtils os = FakeOperatingSystemUtils('Microsoft Windows [Version 10.0.14393]');

      const FileSystemException e = FileSystemException('', '', OSError('', 1314));

      expect(
        () => handleSymlinkException(
          e,
          platform: platform,
          os: os,
          source: pubCachePath,
          destination: ephemeralPackagePath,
        ),
        throwsToolExit(message: 'administrator'),
      );
    });

    testWithoutContext('Symlink failures only give instructions for specific errors', () async {
      final Platform platform = FakePlatform(operatingSystem: 'windows');
      final FakeOperatingSystemUtils os = FakeOperatingSystemUtils('Microsoft Windows [Version 10.0.14393]');

      const FileSystemException e = FileSystemException('', '', OSError('', 999));

      expect(
        () => handleSymlinkException(
          e,
          platform: platform,
          os: os,
          source: pubCachePath,
          destination: ephemeralPackagePath,
        ),
        returnsNormally,
      );
    });
  });
}

class FakeFlutterManifest extends Fake implements FlutterManifest {
  @override
  Set<String> get dependencies => <String>{};
}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  @override
  bool get isInstalled => false;
}

class FakeFlutterProject extends Fake implements FlutterProject {
  @override
  bool isModule = false;

  @override
  late FlutterManifest manifest;

  @override
  late Directory directory;

  @override
  late File flutterPluginsFile;

  @override
  late File flutterPluginsDependenciesFile;

  @override
  late IosProject ios;

  @override
  late AndroidProject android;

  @override
  late WebProject web;

  @override
  late MacOSProject macos;

  @override
  late LinuxProject linux;

  @override
  late WindowsProject windows;
}

class FakeMacOSProject extends Fake implements MacOSProject {
  @override
  String pluginConfigKey = 'macos';

  bool exists = false;

  @override
  late File podfile;

  @override
  late File podManifestLock;

  @override
  late Directory managedDirectory;

  @override
  bool existsSync() => exists;
}

class FakeIosProject extends Fake implements IosProject {
  @override
  String pluginConfigKey = 'ios';

  bool testExists = false;

  @override
  bool existsSync() => testExists;

  @override
  bool get exists => testExists;

  @override
  late Directory pluginRegistrantHost;

  @override
  File get pluginRegistrantHeader => pluginRegistrantHost.childFile('GeneratedPluginRegistrant.h');

  @override
  File get pluginRegistrantImplementation => pluginRegistrantHost.childFile('GeneratedPluginRegistrant.m');

  @override
  late File podfile;

  @override
  late File podManifestLock;
}

class FakeAndroidProject extends Fake implements AndroidProject {
  @override
  String pluginConfigKey = 'android';

  bool exists = false;

  @override
  late Directory pluginRegistrantHost;

  @override
  late Directory hostAppGradleRoot;

  @override
  late File appManifestFile;

  late AndroidEmbeddingVersion embeddingVersion;

  @override
  bool existsSync() => exists;

  @override
  AndroidEmbeddingVersion getEmbeddingVersion() {
    return embeddingVersion;
  }

  @override
  AndroidEmbeddingVersionResult computeEmbeddingVersion() {
    return AndroidEmbeddingVersionResult(embeddingVersion, 'reasons for version');
  }
}

class FakeWebProject extends Fake implements WebProject {
  @override
  String pluginConfigKey = 'web';

  @override
  late Directory libDirectory;

  bool exists = false;

  @override
  bool existsSync() => exists;
}

class FakeWindowsProject extends Fake implements WindowsProject {
  @override
  String pluginConfigKey = 'windows';

  @override
  late Directory managedDirectory;

  @override
  late Directory ephemeralDirectory;

  @override
  late Directory pluginSymlinkDirectory;

  @override
  late File cmakeFile;

  @override
  late File generatedPluginCmakeFile;
  bool exists = false;

  @override
  bool existsSync() => exists;
}

class FakeLinuxProject extends Fake implements LinuxProject {
  @override
  String pluginConfigKey = 'linux';

  @override
  late Directory managedDirectory;

  @override
  late Directory ephemeralDirectory;

  @override
  late Directory pluginSymlinkDirectory;

  @override
  late File cmakeFile;

  @override
  late File generatedPluginCmakeFile;
  bool exists = false;

  @override
  bool existsSync() => exists;

}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils(this.name);

  @override
  final String name;
}

class FakeSystemClock extends Fake implements SystemClock {
  late DateTime currentTime;

  @override
  DateTime now() {
    return currentTime;
  }
}
