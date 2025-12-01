// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that the Flutter plugin template works. Use `pod lib lint`
/// to confirm the plugin module can be imported into an app.
Future<void> main() async {
  await task(() async {
    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_plugin_test.');
    try {
      section('Lint integration_test');

      await inDirectory(tempDir, () async {
        // Update pod repo.
        await exec('pod', <String>['repo', 'update']);

        // Relative to this script.
        final String flutterRoot = path.dirname(
          path.dirname(path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))))),
        );
        print('Flutter root at $flutterRoot');
        final String integrationTestPackage = path.join(
          flutterRoot,
          'packages',
          'integration_test',
        );
        final String iosintegrationTestPodspec = path.join(
          integrationTestPackage,
          'ios',
          'integration_test.podspec',
        );

        await exec('pod', <String>['lib', 'lint', iosintegrationTestPodspec, '--use-libraries']);

        final String macosintegrationTestPodspec = path.join(
          integrationTestPackage,
          'integration_test_macos',
          'macos',
          'integration_test_macos.podspec',
        );
        await _tryMacOSLint(macosintegrationTestPodspec, <String>[]);
      });

      section('Create plugin');

      const pluginName = 'test_plugin';
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--template=plugin',
            '--platforms=ios,macos',
            pluginName,
          ],
        );
      });

      section('Lint iOS podspec plugin as framework');

      final String pluginPath = path.join(tempDir.path, pluginName);
      final String podspecPath = path.join(pluginPath, 'ios', '$pluginName.podspec');
      await inDirectory(tempDir, () async {
        await exec('pod', <String>['lib', 'lint', podspecPath, '--allow-warnings']);
      });

      section('Lint iOS podspec plugin as library');

      await inDirectory(tempDir, () async {
        await exec('pod', <String>[
          'lib',
          'lint',
          podspecPath,
          '--allow-warnings',
          '--use-libraries',
        ]);
      });

      section('Lint macOS podspec plugin as framework');

      final String macOSPodspecPath = path.join(pluginPath, 'macos', '$pluginName.podspec');
      await inDirectory(tempDir, () async {
        await _tryMacOSLint(macOSPodspecPath, <String>['--allow-warnings']);
      });

      section('Lint macOS podspec plugin as library');

      await inDirectory(tempDir, () async {
        await _tryMacOSLint(macOSPodspecPath, <String>['--allow-warnings', '--use-libraries']);
      });

      section('Create iOS application');

      const iosAppName = 'test_app';
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--platforms=ios,macos', iosAppName],
        );
      });

      section('Build iOS application with plugins as frameworks');

      final String appPath = path.join(tempDir.path, iosAppName);

      final pubspec = File(path.join(appPath, 'pubspec.yaml'));

      String pubspecContent = pubspec.readAsStringSync();
      // Add (randomly selected) first-party plugins that support iOS and macOS.
      // Add the new plugins we just made.
      pubspecContent = pubspecContent.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  $pluginName:\n    path: $pluginPath\n  url_launcher: 6.0.16\n  url_launcher_macos:\n',
      );
      pubspec.writeAsStringSync(pubspecContent, flush: true);

      await inDirectory(appPath, () async {
        await flutter('build', options: <String>['ios', '--no-codesign']);
      });

      final iosPodfile = File(path.join(appPath, 'ios', 'Podfile'));
      String iosPodfileContent = iosPodfile.readAsStringSync();
      if (!iosPodfileContent.contains('use_frameworks!')) {
        return TaskResult.failure('Expected default Podfile to contain use_frameworks');
      }

      section('Build iOS application with plugins as libraries');

      iosPodfileContent = iosPodfileContent.replaceAll('use_frameworks!', '');
      iosPodfile.writeAsStringSync(iosPodfileContent, flush: true);

      await inDirectory(appPath, () async {
        await flutter('build', options: <String>['ios', '--no-codesign']);
      });

      _validateIosPodfile(appPath);

      section('Build macOS application with plugins as frameworks');
      await inDirectory(appPath, () async {
        await flutter('build', options: <String>['macos']);
      });

      final macOSPodfile = File(path.join(appPath, 'macos', 'Podfile'));
      String macosPodfileContent = macOSPodfile.readAsStringSync();
      if (!macosPodfileContent.contains('use_frameworks!')) {
        return TaskResult.failure('Expected default Podfile to contain use_frameworks');
      }

      _validateMacOSPodfile(appPath);

      section('Remove iOS support from plugin');

      Directory(path.join(pluginPath, 'ios')).deleteSync(recursive: true);

      const iosPlatformMap = '''
      ios:
        pluginClass: TestPlugin''';

      final pluginPubspec = File(path.join(pluginPath, 'pubspec.yaml'));
      String pluginPubspecContent = pluginPubspec.readAsStringSync();
      if (!pluginPubspecContent.contains(iosPlatformMap)) {
        return TaskResult.failure('Plugin pubspec.yaml missing iOS platform map');
      }

      pluginPubspecContent = pluginPubspecContent.replaceFirst(iosPlatformMap, '');
      pluginPubspec.writeAsStringSync(pluginPubspecContent, flush: true);

      await inDirectory(appPath, () async {
        await flutter('clean');
        await flutter('build', options: <String>['ios', '--no-codesign']);
      });

      section('Validate plugin without iOS platform');

      final podfileLockFile = File(path.join(appPath, 'ios', 'Podfile.lock'));
      final String podfileLockOutput = podfileLockFile.readAsStringSync();
      if (!podfileLockOutput.contains(':path: ".symlinks/plugins/url_launcher_ios/ios"') ||
          !podfileLockOutput.contains(':path: Flutter')
          // test_plugin no longer supports iOS, shouldn't be present.
          ||
          podfileLockOutput.contains(':path: ".symlinks/plugins/test_plugin/ios"')) {
        print(podfileLockOutput);
        return TaskResult.failure('Podfile.lock does not contain expected pods');
      }

      final String pluginSymlinks = path.join(appPath, 'ios', '.symlinks', 'plugins');

      checkDirectoryExists(path.join(pluginSymlinks, 'url_launcher_ios', 'ios'));

      // test_plugin no longer supports iOS, shouldn't exist!
      checkDirectoryNotExists(path.join(pluginSymlinks, 'test_plugin'));

      section('Build macOS application with plugins as libraries');

      macosPodfileContent = macosPodfileContent.replaceAll('use_frameworks!', '');
      macOSPodfile.writeAsStringSync(macosPodfileContent, flush: true);

      await inDirectory(appPath, () async {
        await flutter('build', options: <String>['macos']);
      });

      _validateMacOSPodfile(appPath);

      return TaskResult.success(null);
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}

void _validateIosPodfile(String appPath) {
  section('Validate iOS Podfile');

  final podfileLockFile = File(path.join(appPath, 'ios', 'Podfile.lock'));
  final String podfileLockOutput = podfileLockFile.readAsStringSync();
  if (!podfileLockOutput.contains(':path: ".symlinks/plugins/url_launcher_ios/ios"') ||
      !podfileLockOutput.contains(':path: Flutter') ||
      !podfileLockOutput.contains(':path: ".symlinks/plugins/test_plugin/ios"') ||
      podfileLockOutput.contains('url_launcher_macos')) {
    print(podfileLockOutput);
    throw TaskResult.failure('iOS Podfile.lock does not contain expected pods');
  }

  checkDirectoryNotExists(path.join(appPath, 'ios', 'Flutter', 'Flutter.framework'));

  checkFileExists(path.join(appPath, 'ios', 'Flutter', 'Flutter.podspec'));

  final String pluginSymlinks = path.join(appPath, 'ios', '.symlinks', 'plugins');

  checkDirectoryExists(path.join(pluginSymlinks, 'url_launcher_ios', 'ios'));

  checkDirectoryNotExists(path.join(pluginSymlinks, 'url_launcher_macos'));

  checkDirectoryExists(path.join(pluginSymlinks, 'test_plugin', 'ios'));

  // Make sure no Xcode build settings are leaking derived data/build directory into the ios directory.
  checkDirectoryNotExists(path.join(appPath, 'ios', 'build'));
}

void _validateMacOSPodfile(String appPath) {
  section('Validate macOS Podfile');

  final podfileLockFile = File(path.join(appPath, 'macos', 'Podfile.lock'));
  final String podfileLockOutput = podfileLockFile.readAsStringSync();
  if (!podfileLockOutput.contains(':path: Flutter/ephemeral\n') ||
      !podfileLockOutput.contains(
        ':path: Flutter/ephemeral/.symlinks/plugins/url_launcher_macos/macos',
      ) ||
      !podfileLockOutput.contains(':path: Flutter/ephemeral/.symlinks/plugins/test_plugin/macos') ||
      podfileLockOutput.contains('url_launcher_ios/')) {
    print(podfileLockOutput);
    throw TaskResult.failure('macOS Podfile.lock does not contain expected pods');
  }

  checkFileExists(path.join(appPath, 'macos', 'Flutter', 'ephemeral', 'FlutterMacOS.podspec'));

  final String pluginSymlinks = path.join(
    appPath,
    'macos',
    'Flutter',
    'ephemeral',
    '.symlinks',
    'plugins',
  );

  checkDirectoryExists(path.join(pluginSymlinks, 'url_launcher_macos', 'macos'));

  checkDirectoryNotExists(path.join(pluginSymlinks, 'url_launcher_ios'));

  checkDirectoryExists(path.join(pluginSymlinks, 'test_plugin', 'macos'));
}

Future<void> _tryMacOSLint(String podspecPath, List<String> extraArguments) async {
  await eval('pod', <String>['lib', 'lint', podspecPath, ...extraArguments]);
}
