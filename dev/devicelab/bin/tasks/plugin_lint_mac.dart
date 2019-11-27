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
          ],
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
          ],
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
      String podspecContent = objcPubspec.readAsStringSync();
      podspecContent = podspecContent.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  $objcPluginName:\n    path: $objcPluginPath\n  $swiftPluginName:\n    path: $swiftPluginPath\n',
      );
      objcPubspec.writeAsStringSync(podspecContent, flush: true);

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
      swiftPubspec.writeAsStringSync(podspecContent, flush: true);

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

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
