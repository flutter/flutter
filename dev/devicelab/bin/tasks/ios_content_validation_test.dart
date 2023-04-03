// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      await runProjectTest((FlutterProject flutterProject) async {
        section('Archive');

        await inDirectory(flutterProject.rootPath, () async {
          final File appIconFile = File(path.join(
              flutterProject.rootPath,
              'ios',
              'Runner',
              'Assets.xcassets',
              'AppIcon.appiconset',
              'Icon-App-20x20@1x.png',
          ));
          // Resizes app icon to 123x456 (it is supposed to be 20x20).
          appIconFile.writeAsBytesSync(appIconFile.readAsBytesSync()
            ..buffer.asByteData().setInt32(16, 123)
            ..buffer.asByteData().setInt32(20, 456)
          );

          final String output = await evalFlutter('build', options: <String>[
            'xcarchive',
            '-v',
          ]);

          // Note this isBot so usage won't actually be sent,
          // this log line is printed whenever the app is archived.
          if (!output.contains('Sending archive event if usage enabled')) {
            throw TaskResult.failure('Usage archive event not sent');
          }

          if (!output.contains('Warning: App icon is using the wrong size (e.g. Icon-App-20x20@1x.png).')) {
            throw TaskResult.failure('Must validate incorrect app icon image size.');
          }

          // The project is still using Flutter template icon.
          if (!output.contains('Warning: App icon is set to the default placeholder icon. Replace with unique icons.')) {
            throw TaskResult.failure('Must validate template app icon.');
          }
        });

        final String archivePath = path.join(
          flutterProject.rootPath,
          'build',
          'ios',
          'archive',
          'Runner.xcarchive',
        );

        final String products = path.join(archivePath, 'Products');

        checkDirectoryExists(products);

        checkDirectoryExists(path.join(
          archivePath,
          'dSYMs',
          'Runner.app.dSYM',
        ));
        final Directory applications = Directory(path.join(products, 'Applications'));

        final Directory appBundle = applications
            .listSync()
            .whereType<Directory>()
            .singleWhere((Directory directory) => path.extension(directory.path) == '.app');

        final String flutterFramework = path.join(
          appBundle.path,
          'Frameworks',
          'Flutter.framework',
          'Flutter',
        );
        // Exits 0 only if codesigned.
        final Future<String> flutterCodesign =
            eval('xcrun', <String>['codesign', '--verify', flutterFramework]);

        final String appFramework = path.join(
          appBundle.path,
          'Frameworks',
          'App.framework',
          'App',
        );
        final Future<String> appCodesign =
            eval('xcrun', <String>['codesign', '--verify', appFramework]);
        await flutterCodesign;
        await appCodesign;
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
