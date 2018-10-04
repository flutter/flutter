// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';

Future<void> main() async {
  await task(MemoryTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
    'test_memory/memory_nav.dart',
    'io.flutter.demo.gallery',
  ).run);
}
