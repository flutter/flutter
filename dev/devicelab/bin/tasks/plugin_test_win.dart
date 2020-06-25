// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/tasks/plugin_tests.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<void> main() async {
  await task(combine(<TaskFunction>[
    PluginTest('apk', <String>['-a', 'java', '--platforms=android']),
    PluginTest('apk', <String>['-a', 'kotlin', '--platforms=android']),
  ]));
}
