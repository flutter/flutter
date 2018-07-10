// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../test_utils.dart';

abstract class TestProject {
  Directory dir;

  String get pubspec;
  String get main;

  // Valid locations for a breakpoint for tests that just need to break somewhere.
  String get breakpointFile;
  int get breakpointLine;

  Future<void> setUpIn(Directory dir) async {
    this.dir = dir;
    writeFile(fs.path.join(dir.path, 'pubspec.yaml'), pubspec);
    writeFile(fs.path.join(dir.path, 'lib', 'main.dart'), main);
    await getPackages(dir.path);
  }

  void cleanup() {
    dir?.deleteSync(recursive: true);
  }
}
