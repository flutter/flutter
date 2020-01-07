// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
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
    File packagesFile;
    Directory dummyPackageDirectory;

    setUp(() async {
      fs = MemoryFileSystem();

      // Add basic properties to the Flutter project and subprojects
      flutterProject = MockFlutterProject();
      when(flutterProject.directory).thenReturn(fs.directory('/'));
      when(flutterProject.flutterPluginsFile).thenReturn(flutterProject.directory.childFile('.flutter-plugins'));
      when(flutterProject.flutterPluginsDependenciesFile).thenReturn(flutterProject.directory.childFile('.flutter-plugins-dependencies'));
      iosProject = MockIosProject();
      when(flutterProject.ios).thenReturn(iosProject);
      when(iosProject.pluginRegistrantHost).thenReturn(flutterProject.directory.childDirectory('Runner'));
      when(iosProject.podfile).thenReturn(flutterProject.directory.childDirectory('ios').childFile('Podfile'));
      when(iosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('ios').childFile('Podfile.lock'));
      macosProject = MockMacOSProject();
      when(flutterProject.macos).thenReturn(macosProject);
      when(macosProject.podfile).thenReturn(flutterProject.directory.childDirectory('macos').childFile('Podfile'));
      when(macosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('macos').childFile('Podfile.lock'));
      androidProject = MockAndroidProject();
      when(flutterProject.android).thenReturn(androidProject);
      when(androidProject.pluginRegistrantHost).thenReturn(flutterProject.directory.childDirectory('android').childDirectory('app'));
      when(androidProject.hostAppGradleRoot).thenReturn(flutterProject.directory.childDirectory('android'));
      webProject = MockWebProject();
      when(flutterProject.web).thenReturn(webProject);
      when(webProject.libDirectory).thenReturn(flutterProject.directory.childDirectory('lib'));
      when(webProject.existsSync()).thenReturn(true);

      // Set up a simple .packages file for all the tests to use, pointing to one package.
      dummyPackageDirectory = fs.directory('/pubcache/apackage/lib/');
      packagesFile = fs.file(fs.path.join(flutterProject.directory.path, PackageMap.globalPackagesPath));
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

    void createOldJavaPlugin3() {
      final Directory pluginUsingOldEmbeddingDir =
        fs.systemTempDirectory.createTempSync('flutter_plugin_using_old_embedding_dir.');
      pluginUsingOldEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin3
    pluginClass: UseOldEmbedding
        ''');
      pluginUsingOldEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory('plugin3')
        .childFile('UseOldEmbedding.java')
        ..createSync(recursive: true);

      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync(
          'plugin3:${pluginUsingOldEmbeddingDir.childDirectory('lib').uri.toString()}\n',
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

    void createPluginWithDependencies({
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
    }

    // Creates the files that would indicate that pod install has run for the
    // given project.
    void simulatePodInstallRun(XcodeBasedProject project) {
      project.podManifestLock.createSync(recursive: true);
    }

    group('refreshPlugins', () {
      testUsingContext('Refreshing the plugin list is a no-op when the plugins list stays empty', () {
        refreshPluginsList(flutterProject);
        expect(flutterProject.flutterPluginsFile.existsSync(), false);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Refreshing the plugin list deletes the plugin file when there were plugins but no longer are', () {
        flutterProject.flutterPluginsFile.createSync();
        when(iosProject.existsSync()).thenReturn(false);
        when(macosProject.existsSync()).thenReturn(false);
        refreshPluginsList(flutterProject);
        expect(flutterProject.flutterPluginsFile.existsSync(), false);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Refreshing the plugin list creates a plugin directory when there are plugins', () {
        configureDummyPackageAsPlugin();
        when(iosProject.existsSync()).thenReturn(false);
        when(macosProject.existsSync()).thenReturn(false);
        refreshPluginsList(flutterProject);
        expect(flutterProject.flutterPluginsFile.existsSync(), true);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Refreshing the plugin list modifies .flutter-plugins and .flutter-plugins-dependencies when there are plugins', () {
        createPluginWithDependencies(name: 'plugin-a', dependencies: const <String>['plugin-b', 'plugin-c', 'random-package']);
        createPluginWithDependencies(name: 'plugin-b', dependencies: const <String>['plugin-c']);
        createPluginWithDependencies(name: 'plugin-c', dependencies: const <String>[]);
        when(iosProject.existsSync()).thenReturn(false);
        when(macosProject.existsSync()).thenReturn(false);

        refreshPluginsList(flutterProject);

        expect(flutterProject.flutterPluginsFile.existsSync(), true);
        expect(flutterProject.flutterPluginsDependenciesFile.existsSync(), true);
        expect(flutterProject.flutterPluginsFile.readAsStringSync(),
          '# This is a generated file; do not edit or check into version control.\n'
          'plugin-a=/.tmp_rand0/plugin.rand0/\n'
          'plugin-b=/.tmp_rand0/plugin.rand1/\n'
          'plugin-c=/.tmp_rand0/plugin.rand2/\n'
          ''
        );
        expect(flutterProject.flutterPluginsDependenciesFile.readAsStringSync(),
          '{'
            '"_info":"// This is a generated file; do not edit or check into version control.",'
            '"dependencyGraph":['
              '{'
                '"name":"plugin-a",'
                '"dependencies":["plugin-b","plugin-c"]'
              '},'
              '{'
                '"name":"plugin-b",'
                '"dependencies":["plugin-c"]'
              '},'
              '{'
                '"name":"plugin-c",'
                '"dependencies":[]'
              '}'
            ']'
          '}'
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Changes to the plugin list invalidates the Cocoapod lockfiles', () {
        simulatePodInstallRun(iosProject);
        simulatePodInstallRun(macosProject);
        configureDummyPackageAsPlugin();
        when(iosProject.existsSync()).thenReturn(true);
        when(macosProject.existsSync()).thenReturn(true);
        refreshPluginsList(flutterProject);
        expect(iosProject.podManifestLock.existsSync(), false);
        expect(macosProject.podManifestLock.existsSync(), false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
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
        createOldJavaPlugin3();

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

        createOldJavaPlugin3();

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

      testUsingContext('Registrant for web doesn\'t escape slashes in imports', () async {
        when(flutterProject.isModule).thenReturn(true);
        when(featureFlags.isWebEnabled).thenReturn(true);

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
          ..createSync(recursive: true);

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
    });
  });
}

class MockAndroidProject extends Mock implements AndroidProject {}
class MockFeatureFlags extends Mock implements FeatureFlags {}
class MockFlutterProject extends Mock implements FlutterProject {}
class MockFile extends Mock implements File {}
class MockIosProject extends Mock implements IosProject {}
class MockMacOSProject extends Mock implements MacOSProject {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockWebProject extends Mock implements WebProject {}
