// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
          await flutter('build', options: <String>[
            'xcarchive',
          ]);
        });

        final String archivePath = path.join(
          flutterProject.rootPath,
          'build',
          'ios',
          'archive',
          'Runner.xcarchive',
        );

        checkDirectoryExists(path.join(
          archivePath,
          'Products',
        ));

        checkDirectoryExists(path.join(
          archivePath,
          'dSYMs',
          'Runner.app.dSYM',
        ));
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
