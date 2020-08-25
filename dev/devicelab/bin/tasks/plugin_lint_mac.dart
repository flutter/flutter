// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that the Flutter plugin template works. Use `pod lib lint`
/// to confirm the plugin module can be imported into an app.
Future<void> main() async {
  await task(() async {

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_plugin_test.');
    try {
      section('Create Objective-C plugin');

      const String objcPluginName = 'test_plugin_objc';
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--template=plugin',
            '--platforms=ios,android',
            '--ios-language=objc',
            objcPluginName,
          ],
        );
      });

      section('Lint Objective-C iOS podspec plugin as framework');

      final String objcPluginPath = path.join(tempDir.path, objcPluginName);
      final String objcPodspecPath = path.join(objcPluginPath, 'ios', '$objcPluginName.podspec');
      await inDirectory(tempDir, () async {
        await exec(
          'pod',
          <String>[
            'lib',
            'lint',
            objcPodspecPath,
            '--allow-warnings',
            '--verbose',
          ],
          environment: <String, String>{
            'LANG': 'en_US.UTF-8',
          },
          // TODO(jmagman): Flutter cannot build against ARM simulators https://github.com/flutter/flutter/issues/64502
          canFail: true,
        );
      });

      section('Lint Objective-C iOS podspec plugin as library');

      await inDirectory(tempDir, () async {
        await exec(
          'pod',
          <String>[
            'lib',
            'lint',
            objcPodspecPath,
            '--allow-warnings',
            '--use-libraries',
            '--verbose',
          ],
          environment: <String, String>{
            'LANG': 'en_US.UTF-8',
          },
          // TODO(jmagman): Flutter cannot build against ARM simulators https://github.com/flutter/flutter/issues/64502
          canFail: true,
        );
      });

      section('Create Swift plugin');

      const String swiftPluginName = 'test_plugin_swift';
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--template=plugin',
            '--platforms=ios,android',
            '--ios-language=swift',
            swiftPluginName,
          ],
        );
      });

      section('Create Objective-C application');

      const String objcAppName = 'test_app_objc';
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--ios-language=objc',
            objcAppName,
          ],
        );
      });

      section('Build Objective-C application with Swift and Objective-C plugins as libraries');

      final String objcAppPath = path.join(tempDir.path, objcAppName);

      final String swiftPluginPath = path.join(tempDir.path, swiftPluginName);
      final File objcPubspec = File(path.join(objcAppPath, 'pubspec.yaml'));
      String pubspecContent = objcPubspec.readAsStringSync();
      pubspecContent = pubspecContent.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  $objcPluginName:\n    path: $objcPluginPath\n  $swiftPluginName:\n    path: $swiftPluginPath\n  device_info:\n',
      );
      objcPubspec.writeAsStringSync(pubspecContent, flush: true);

      await inDirectory(objcAppPath, () async {
        await flutter(
          'build',
          options: <String>[
            'ios',
            '--no-codesign'
          ],
          // TODO(jmagman): Make Objective-C applications handle Swift libraries https://github.com/flutter/flutter/issues/16049
          canFail: true
        );
      });

      final File objcPodfile = File(path.join(objcAppPath, 'ios', 'Podfile'));
      String objcPodfileContent = objcPodfile.readAsStringSync();
      if (objcPodfileContent.contains('use_frameworks!')) {
        return TaskResult.failure('Expected default Objective-C Podfile to not contain use_frameworks');
      }
      _validatePodfile(objcAppPath);

      section('Build Objective-C application with Swift and Objective-C plugins as frameworks');

      objcPodfileContent = 'use_frameworks!\n' + objcPodfileContent;
      objcPodfile.writeAsStringSync(objcPodfileContent, flush: true);

      await inDirectory(objcAppPath, () async {
        await flutter(
          'build',
          options: <String>[
            'ios',
            '--no-codesign'
          ],
        );
      });

      section('Create Swift application');

      const String swiftAppName = 'test_app_swift';
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--ios-language=swift',
            swiftAppName,
          ],
        );
      });

      section('Build Swift application with Swift and Objective-C plugins as frameworks');

      final String swiftAppPath = path.join(tempDir.path, swiftAppName);

      final File swiftPubspec = File(path.join(swiftAppPath, 'pubspec.yaml'));
      swiftPubspec.writeAsStringSync(pubspecContent, flush: true);

      await inDirectory(swiftAppPath, () async {
        await flutter(
          'build',
          options: <String>[
            'ios',
            '--no-codesign'
          ],
        );
      });

      final File swiftPodfile = File(path.join(swiftAppPath, 'ios', 'Podfile'));
      String swiftPodfileContent = swiftPodfile.readAsStringSync();
      if (!swiftPodfileContent.contains('use_frameworks!')) {
        return TaskResult.failure('Expected default Swift Podfile to contain use_frameworks');
      }

      section('Build Swift application with Swift and Objective-C plugins as libraries');

      swiftPodfileContent = swiftPodfileContent.replaceAll('use_frameworks!', '');
      swiftPodfile.writeAsStringSync(swiftPodfileContent, flush: true);

      await inDirectory(swiftAppPath, () async {
        await flutter(
          'build',
          options: <String>[
            'ios',
            '--no-codesign'
          ],
        );
      });

      _validatePodfile(swiftAppPath);

      section('Remove iOS support from plugin');

      Directory(path.join(objcPluginPath, 'ios')).deleteSync(recursive: true);

      const String iosPlatformMap = '''
      ios:
        pluginClass: TestPluginObjcPlugin''';

      final File pluginPubspec = File(path.join(objcPluginPath, 'pubspec.yaml'));
      String pluginPubspecContent = pluginPubspec.readAsStringSync();
      if (!pluginPubspecContent.contains(iosPlatformMap)) {
        return TaskResult.failure('Plugin pubspec.yaml missing iOS platform map');
      }

      pluginPubspecContent = pluginPubspecContent.replaceFirst(iosPlatformMap, '');
      pluginPubspec.writeAsStringSync(pluginPubspecContent, flush: true);

      await inDirectory(swiftAppPath, () async {
        await flutter('clean');
        await flutter(
          'build',
          options: <String>[
            'ios',
            '--no-codesign'
          ],
        );
      });

      section('Validate plugin without iOS platform');

      final File podfileLockFile = File(path.join(swiftAppPath, 'ios', 'Podfile.lock'));
      final String podfileLockOutput = podfileLockFile.readAsStringSync();
      if (!podfileLockOutput.contains(':path: ".symlinks/plugins/device_info/ios"')
        || !podfileLockOutput.contains(':path: Flutter')
          // test_plugin_objc no longer supports iOS, shouldn't be present.
        || podfileLockOutput.contains(':path: ".symlinks/plugins/test_plugin_objc/ios"')
        || !podfileLockOutput.contains(':path: ".symlinks/plugins/test_plugin_swift/ios"')) {
        return TaskResult.failure('Podfile.lock does not contain expected pods');
      }

      final String pluginSymlinks = path.join(
        swiftAppPath,
        'ios',
        '.symlinks',
        'plugins',
      );

      checkDirectoryExists(path.join(
        pluginSymlinks,
        'device_info',
        'ios',
      ));

      checkDirectoryExists(path.join(
        pluginSymlinks,
        'test_plugin_swift',
        'ios',
      ));

      // test_plugin_objc no longer supports iOS, shouldn't exist!
      checkDirectoryNotExists(path.join(
        pluginSymlinks,
        'test_plugin_objc',
      ));

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}

void _validatePodfile(String appPath) {
  section('Validate Podfile');

  final File podfileLockFile = File(path.join(appPath, 'ios', 'Podfile.lock'));
  final String podfileLockOutput = podfileLockFile.readAsStringSync();
  if (!podfileLockOutput.contains(':path: ".symlinks/plugins/device_info/ios"')
    || !podfileLockOutput.contains(':path: Flutter')
    || !podfileLockOutput.contains(':path: ".symlinks/plugins/test_plugin_objc/ios"')
    || !podfileLockOutput.contains(':path: ".symlinks/plugins/test_plugin_swift/ios"')) {
    throw TaskResult.failure('Podfile.lock does not contain expected pods');
  }

  checkFileExists(path.join(
    appPath,
    'ios',
    'Flutter',
    'Flutter.framework',
    'Flutter',
  ));

  checkFileExists(path.join(
    appPath,
    'ios',
    'Flutter',
    'Flutter.podspec',
  ));

  final String pluginSymlinks = path.join(
    appPath,
    'ios',
    '.symlinks',
    'plugins',
  );

  checkDirectoryExists(path.join(
    pluginSymlinks,
    'device_info',
    'ios',
  ));

  checkDirectoryExists(path.join(
    pluginSymlinks,
    'test_plugin_objc',
    'ios',
  ));

  checkDirectoryExists(path.join(
    pluginSymlinks,
    'test_plugin_swift',
    'ios',
  ));
}
