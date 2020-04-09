import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    section('Copy test Flutter App with WatchOS Companion');

    final Directory tempDir = Directory.systemTemp
        .createTempSync('ios_app_with_watch_companion_test');
    final Directory projectDir =
        Directory(path.join(tempDir.path, 'app_with_companion'));
    try {
      mkdir(projectDir);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests',
            'ios_app_with_watch_companion')),
        projectDir,
      );

      section('Create release build');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign'],
        );
      });

      final bool appReleaseBuilt = exists(Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      )));

      if (!appReleaseBuilt) {
        return TaskResult.failure(
            'Failed to build flutter iOS app with WatchOS companion.');
      }
      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
