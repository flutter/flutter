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

    // Relative to this script.
    final String flutterRoot = path.dirname(
      path.dirname(path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))))),
    );
    print('Flutter root at $flutterRoot');

    try {
      // This test validates pods, so we need to disable SwiftPM.
      await flutter('config', options: <String>['--no-enable-swift-package-manager']);
      await flutter('precache', options: <String>['--macos', '--ios']);

      final String flutterMacOSPodspecPath = _setUpFlutterMacOSPodspec(
        flutterRoot: flutterRoot,
        tempDir: tempDir,
      );
      final String flutterIosPodspecPath = _setUpFlutterIosPodspec(
        flutterRoot: flutterRoot,
        tempDir: tempDir,
      );

      section('Lint integration_test');

      await inDirectory(tempDir, () async {
        // Update pod repo.
        await exec('pod', <String>['repo', 'update']);

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

        await exec('pod', <String>[
          'lib',
          'lint',
          iosintegrationTestPodspec,
          '--use-libraries',
          '--include-podspecs=$flutterIosPodspecPath',
        ]);

        final String macosintegrationTestPodspec = path.join(
          integrationTestPackage,
          'integration_test_macos',
          'macos',
          'integration_test_macos.podspec',
        );
        await _tryMacOSLint(macosintegrationTestPodspec, <String>[
          '--include-podspecs=$flutterMacOSPodspecPath',
        ]);
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
        await exec('pod', <String>[
          'lib',
          'lint',
          podspecPath,
          '--allow-warnings',
          '--include-podspecs=$flutterIosPodspecPath',
        ]);
      });

      section('Lint iOS podspec plugin as library');

      await inDirectory(tempDir, () async {
        await exec('pod', <String>[
          'lib',
          'lint',
          podspecPath,
          '--allow-warnings',
          '--use-libraries',
          '--include-podspecs=$flutterIosPodspecPath',
        ]);
      });

      section('Lint macOS podspec plugin as framework');

      final String macOSPodspecPath = path.join(pluginPath, 'macos', '$pluginName.podspec');
      await inDirectory(tempDir, () async {
        await _tryMacOSLint(macOSPodspecPath, <String>[
          '--allow-warnings',
          '--include-podspecs=$flutterMacOSPodspecPath',
        ]);
      });

      section('Lint macOS podspec plugin as library');

      await inDirectory(tempDir, () async {
        await _tryMacOSLint(macOSPodspecPath, <String>[
          '--allow-warnings',
          '--use-libraries',
          '--include-podspecs=$flutterMacOSPodspecPath',
        ]);
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
        await flutter('clean', options: <String>['--include-xcode-workspace']);
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

/// Creates a local `FlutterMacOS.podspec` in [tempDir] symlinked to the cached
/// `FlutterMacOS.xcframework` engine artifact and returns the podspec path.
///
/// Passing this podspec via `--include-podspecs` ensures `pod lib lint` builds
/// against the local engine framework and current deployment target rather than
/// pulling an outdated `FlutterMacOS` podspec from CocoaPods trunk.
String _setUpFlutterMacOSPodspec({required String flutterRoot, required Directory tempDir}) {
  final flutterMacOSPodspec = File(path.join(tempDir.path, 'FlutterMacOS.podspec'));
  final flutterMacOSFramework = Directory(
    path.join(
      flutterRoot,
      'bin',
      'cache',
      'artifacts',
      'engine',
      'darwin-x64',
      'FlutterMacOS.xcframework',
    ),
  );

  Link(path.join(tempDir.path, 'FlutterMacOS.xcframework')).createSync(flutterMacOSFramework.path);

  flutterMacOSPodspec.writeAsStringSync('''
Pod::Spec.new do |s|
  s.name             = 'FlutterMacOS'
  s.version          = '1.0.0'
  s.summary          = 'A UI toolkit for beautiful and fast apps.'
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
  s.osx.deployment_target = '12.0'
  s.vendored_frameworks = 'FlutterMacOS.xcframework'
end
''');
  return flutterMacOSPodspec.path;
}

/// Creates a local `Flutter.podspec` in [tempDir] symlinked to the cached
/// `Flutter.xcframework` engine artifact and returns the podspec path.
///
/// Passing this podspec via `--include-podspecs` ensures `pod lib lint` builds
/// against the local engine framework and current deployment target rather than
/// pulling an outdated `Flutter` podspec from CocoaPods trunk.
String _setUpFlutterIosPodspec({required String flutterRoot, required Directory tempDir}) {
  final flutterIosPodspec = File(path.join(tempDir.path, 'Flutter.podspec'));
  final flutterIosFramework = Directory(
    path.join(flutterRoot, 'bin', 'cache', 'artifacts', 'engine', 'ios', 'Flutter.xcframework'),
  );
  Link(path.join(tempDir.path, 'Flutter.xcframework')).createSync(flutterIosFramework.path);

  flutterIosPodspec.writeAsStringSync('''
Pod::Spec.new do |s|
  s.name             = 'Flutter'
  s.version          = '1.0.0'
  s.summary          = 'A UI toolkit for beautiful and fast apps.'
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.vendored_frameworks = 'Flutter.xcframework'
end
''');
  return flutterIosPodspec.path;
}
