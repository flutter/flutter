// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/tasks/plugin_tests.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<void> main() async {
  await task(combine(<TaskFunction>[
    PluginTest('ios', <String>['-i', 'objc', '--platforms=ios']),
    PluginTest('ios', <String>['-i', 'swift', '--platforms=ios']),
    PluginTest('macos', <String>['--platforms=macos']),
  ]));
}
