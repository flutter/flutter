// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

/// Combines several TaskFunctions with trivial success value into one.
TaskFunction combine(List<TaskFunction> tasks) {
  return () async {
    for (final TaskFunction task in tasks) {
      final TaskResult result = await task();
      if (result.failed) {
        return result;
      }
    }
    return TaskResult.success(null);
  };
}

/// Defines task that creates new Flutter project, adds a local and remote
/// plugin, and then builds the specified [buildTarget].
class PluginTest {
  PluginTest(
    this.buildTarget,
    this.options, {
    this.pluginCreateEnvironment,
    this.appCreateEnvironment,
    this.dartOnlyPlugin = false,
    this.template = 'plugin',
  });

  final String buildTarget;
  final List<String> options;
  final Map<String, String>? pluginCreateEnvironment;
  final Map<String, String>? appCreateEnvironment;
  final bool dartOnlyPlugin;
  final String template;

  Future<TaskResult> call() async {
    final Directory tempDir =
        Directory.systemTemp.createTempSync('flutter_devicelab_plugin_test.');
    // FFI plugins do not have support for `flutter test`.
    // `flutter test` does not do a native build.
    // Supporting `flutter test` would require invoking a native build.
    final bool runFlutterTest = template != 'plugin_ffi';
    try {
      section('Create plugin');
      final _FlutterProject plugin = await _FlutterProject.create(
          tempDir, options, buildTarget,
          name: 'plugintest', template: template, environment: pluginCreateEnvironment);
      if (dartOnlyPlugin) {
        await plugin.convertDefaultPluginToDartPlugin();
      }
      section('Test plugin');
      if (runFlutterTest) {
        await plugin.test();
      }
      section('Create Flutter app');
      final _FlutterProject app = await _FlutterProject.create(tempDir, options, buildTarget,
          name: 'plugintestapp', template: 'app', environment: appCreateEnvironment);
      try {
        section('Add plugins');
        await app.addPlugin('plugintest',
            pluginPath: path.join('..', 'plugintest'));
        await app.addPlugin('path_provider');
        section('Build app');
        await app.build(buildTarget, validateNativeBuildProject: !dartOnlyPlugin);
        if (runFlutterTest) {
          section('Test app');
          await app.test();
        }
      } finally {
        await plugin.delete();
        await app.delete();
      }
      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  }
}

class _FlutterProject {
  _FlutterProject(this.parent, this.name);

  final Directory parent;
  final String name;

  String get rootPath => path.join(parent.path, name);

  File get pubspecFile => File(path.join(rootPath, 'pubspec.yaml'));

  Future<void> addPlugin(String plugin, {String? pluginPath}) async {
    final File pubspec = pubspecFile;
    String content = await pubspec.readAsString();
    final String dependency =
        pluginPath != null ? '$plugin:\n    path: $pluginPath' : '$plugin:';
    content = content.replaceFirst(
      '\ndependencies:\n',
      '\ndependencies:\n  $dependency\n',
    );
    await pubspec.writeAsString(content, flush: true);
  }

  /// Converts a plugin created from the standard template to a Dart-only
  /// plugin.
  Future<void> convertDefaultPluginToDartPlugin() async {
    final String dartPluginClass = 'DartClassFor$name';
    // Convert the metadata.
    final File pubspec = pubspecFile;
    String content = await pubspec.readAsString();
    content = content.replaceAll(
      RegExp(r' pluginClass: .*?\n'),
      ' dartPluginClass: $dartPluginClass\n',
    );
    await pubspec.writeAsString(content, flush: true);

    // Add the Dart registration hook that the build will generate a call to.
    final File dartCode = File(path.join(rootPath, 'lib', '$name.dart'));
    content = await dartCode.readAsString();
    content = '''
$content

class $dartPluginClass {
  static void registerWith() {}
}
''';
    await dartCode.writeAsString(content, flush: true);

    // Remove any native plugin code.
    const List<String> platforms = <String>[
      'android',
      'ios',
      'linux',
      'macos',
      'windows',
    ];
    for (final String platform in platforms) {
      final Directory platformDir = Directory(path.join(rootPath, platform));
      if (platformDir.existsSync()) {
        await platformDir.delete(recursive: true);
      }
    }
  }

  Future<void> test() async {
    await inDirectory(Directory(rootPath), () async {
      await flutter('test');
    });
  }

  static Future<_FlutterProject> create(
      Directory directory,
      List<String> options,
      String target,
      {
        required String name,
        required String template,
        Map<String, String>? environment,
      }) async {
    await inDirectory(directory, () async {
      await flutter(
        'create',
        options: <String>[
          '--template=$template',
          '--org',
          'io.flutter.devicelab',
          ...options,
          name,
        ],
        environment: environment,
      );
    });

    final _FlutterProject project = _FlutterProject(directory, name);
    if (template == 'plugin' && (target == 'ios' || target == 'macos')) {
      project._reduceDarwinPluginMinimumVersion(name, target);
    }
    return project;
  }

  // Make the platform version artificially low to test that the "deployment
  // version too low" warning is never emitted.
  void _reduceDarwinPluginMinimumVersion(String plugin, String target) {
    final File podspec = File(path.join(rootPath, target, '$plugin.podspec'));
    if (!podspec.existsSync()) {
      throw TaskResult.failure('podspec file missing at ${podspec.path}');
    }
    final String versionString = target == 'ios'
        ? "s.platform = :ios, '9.0'"
        : "s.platform = :osx, '10.11'";
    String podspecContent = podspec.readAsStringSync();
    if (!podspecContent.contains(versionString)) {
      throw TaskResult.failure('Update this test to match plugin minimum $target deployment version');
    }
    podspecContent = podspecContent.replaceFirst(
      versionString,
      target == 'ios'
          ? "s.platform = :ios, '10.0'"
          : "s.platform = :osx, '10.8'"
    );
    podspec.writeAsStringSync(podspecContent, flush: true);
  }

  Future<void> build(String target, {bool validateNativeBuildProject = true}) async {
    await inDirectory(Directory(rootPath), () async {
      final String buildOutput =  await evalFlutter('build', options: <String>[
        target,
        '-v',
        if (target == 'ios')
          '--no-codesign',
      ]);

      if (target == 'ios' || target == 'macos') {
        // This warning is confusing and shouldn't be emitted. Plugins often support lower versions than the
        // Flutter app, but as long as they support the minimum it will work.
        // warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0,
        // but the range of supported deployment target versions is 9.0 to 14.0.99.
        //
        // (or "The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET'"...)
        if (buildOutput.contains('the range of supported deployment target versions')) {
          throw TaskResult.failure('Minimum plugin version warning present');
        }

        if (validateNativeBuildProject) {
          final File podsProject = File(path.join(rootPath, target, 'Pods', 'Pods.xcodeproj', 'project.pbxproj'));
          if (!podsProject.existsSync()) {
            throw TaskResult.failure('Xcode Pods project file missing at ${podsProject.path}');
          }

          final String podsProjectContent = podsProject.readAsStringSync();
          if (target == 'ios') {
            // Plugins with versions lower than the app version should not have IPHONEOS_DEPLOYMENT_TARGET set.
            // The plugintest plugin target should not have IPHONEOS_DEPLOYMENT_TARGET set since it has been lowered
            // in _reduceDarwinPluginMinimumVersion to 10, which is below the target version of 11.
            if (podsProjectContent.contains('IPHONEOS_DEPLOYMENT_TARGET = 10')) {
              throw TaskResult.failure('Plugin build setting IPHONEOS_DEPLOYMENT_TARGET not removed');
            }
            if (!podsProjectContent.contains(r'"EXCLUDED_ARCHS[sdk=iphonesimulator*]" = "$(inherited) i386";')) {
              throw TaskResult.failure(r'EXCLUDED_ARCHS is not "$(inherited) i386"');
            }
          }

          // Same for macOS deployment target, but 10.8.
          // The plugintest target should not have MACOSX_DEPLOYMENT_TARGET set.
          if (target == 'macos' && podsProjectContent.contains('MACOSX_DEPLOYMENT_TARGET = 10.8')) {
            throw TaskResult.failure('Plugin build setting MACOSX_DEPLOYMENT_TARGET not removed');
          }
        }
      }
    });
  }

  Future<void> delete() async {
    if (Platform.isWindows) {
      // A running Gradle daemon might prevent us from deleting the project
      // folder on Windows.
      final String wrapperPath =
          path.absolute(path.join(rootPath, 'android', 'gradlew.bat'));
      if (File(wrapperPath).existsSync()) {
        await exec(wrapperPath, <String>['--stop'], canFail: true);
      }
      // TODO(ianh): Investigating if flakiness is timing dependent.
      await Future<void>.delayed(const Duration(seconds: 10));
    }
    rmTree(parent);
  }
}
