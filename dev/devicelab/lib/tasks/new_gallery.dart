// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../framework/task_result.dart';
import '../framework/utils.dart';
import '../versions/gallery.dart' show galleryVersion;
import 'perf_tests.dart';

class NewGalleryPerfTest extends PerfTest {
  NewGalleryPerfTest(
    this.galleryDir, {
    String timelineFileName = 'transitions',
    String dartDefine = '',
    bool enableImpeller = kEnableImpellerDefault,
    super.timeoutSeconds,
  }) : super(
    galleryDir.path,
    'test_driver/transitions_perf.dart',
    timelineFileName,
    dartDefine: dartDefine,
    enableImpeller: enableImpeller,
  );

  @override
  Future<TaskResult> run() async {
    // Manually roll the new gallery version for now. If the new gallery repo
    // turns out to be updated frequently in the future, we can set up an auto
    // roller to update this version.
    await getNewGallery(galleryVersion, galleryDir);
    return super.run();
  }

  final Directory galleryDir;
}
