// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' as gradle;
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/ide_config.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('ide-config androidSdkVersion reproduction', () {
    late Directory tempDir;
    late Directory intellijDir;
    late String? originalFlutterRoot;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      originalFlutterRoot = Cache.flutterRoot;
      tempDir = globals.fs.systemTempDirectory.createTempSync(
        'flutter_tools_ide_config_reproduce_test.',
      );
      final Directory packagesDir = tempDir.childDirectory('packages')..createSync(recursive: true);
      final Directory toolsDir = packagesDir.childDirectory('flutter_tools')..createSync();
      final Directory templateDir = toolsDir.childDirectory('ide_templates')..createSync();
      intellijDir = templateDir.childDirectory('intellij')..createSync();
    });

    tearDown(() {
      Cache.flutterRoot = originalFlutterRoot;
      tryToDelete(tempDir);
    });

    testUsingContext('renders androidSdkVersion in templates containing it', () async {
      // 1. Set up a template that uses `{{androidSdkVersion}}`.
      final Directory examplePlatformChannelDir =
          intellijDir.childDirectory('examples').childDirectory('platform_channel')
            ..createSync(recursive: true);
      final File templateFile = examplePlatformChannelDir.childFile('android.iml.tmpl');
      templateFile.writeAsStringSync(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<module type="JAVA_MODULE" version="4">\n'
        '  <component name="NewModuleRootManager" inherit-compiler-output="true">\n'
        '    <orderEntry type="jdk" jdkName="Android API {{androidSdkVersion}} Platform" jdkType="Android SDK" />\n'
        '  </component>\n'
        '</module>\n',
      );

      Cache.flutterRoot = tempDir.absolute.path;
      final command = IdeConfigCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['ide-config']);

      final File renderedFile = tempDir
          .childDirectory('examples')
          .childDirectory('platform_channel')
          .childFile('android.iml');

      expect(renderedFile.existsSync(), isTrue);
      final String contents = renderedFile.readAsStringSync();
      expect(contents, contains('Android API ${gradle.minSdkVersion} Platform'));
    });
  });
}
