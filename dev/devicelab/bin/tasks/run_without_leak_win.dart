// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/run_without_leak.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(createRunWithoutLeakTest(path.join(flutterDirectory.path, 'examples', 'hello_world')));
}
