// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/tasks/perf_tests.dart';
import 'package:path/path.dart' as path;


import '../framework/framework.dart';
import '../framework/utils.dart';

class NewGalleryPerfTest extends PerfTest {
  NewGalleryPerfTest(this.galleryDir) : super(galleryDir.path, 'test_driver/transitions_perf.dart', 'transitions');

  @override
  Future<TaskResult> run() async {
    // Manually roll the new gallery version for now. If the new gallery repo
    // turns out to be updated frequently in the future, we can set up an auto
    // roller to update this version.
    await getNewGallery('0b3b178b30bfee5b6528a14ec06d9dc018d13a07', galleryDir);
    return await super.run();
  }

  final Directory galleryDir;
}