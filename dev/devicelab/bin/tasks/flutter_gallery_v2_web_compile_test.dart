// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart' show WebCompileTest;
import 'package:flutter_devicelab/versions/gallery.dart' show galleryVersion;
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(const NewGalleryWebCompileTest().run);
}

/// Measures the time to compile the New Flutter Gallery to JavaScript
/// and the size of the compiled code.
class NewGalleryWebCompileTest {
  const NewGalleryWebCompileTest();

  String get metricKeyPrefix => 'new_gallery';

  /// Runs the test.
  Future<TaskResult> run() async {
    final Directory galleryParentDir =
        Directory.systemTemp.createTempSync('flutter_gallery_v2_web_compile.');
    final Directory galleryDir =
        Directory(path.join(galleryParentDir.path, 'gallery'));

    await getNewGallery(galleryVersion, galleryDir);

    final Map<String, Object> metrics = await inDirectory<Map<String, int>>(
      galleryDir,
      () async {
        await flutter('doctor');

        return WebCompileTest.runSingleBuildTest(
          directory: galleryDir.path,
          metric: metricKeyPrefix,
          measureBuildTime: true,
        );
      },
    );

    rmTree(galleryParentDir);

    return TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
  }
}
