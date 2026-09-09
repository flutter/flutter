// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/plugin_tests.dart';

Future<void> main() async {
  await task(
    combine(<TaskFunction>[
      // Test that shared darwin directories are supported on iOS.
      PluginTest('ios', <String>['--platforms=ios,macos'], sharedDarwinSource: true).call,
      // Test that shared darwin directories are supported on macOS.
      PluginTest('macos', <String>['--platforms=ios,macos'], sharedDarwinSource: true).call,
      // Test that iOS plugins support the darwin platform.
      PluginTest('ios', <String>['--platforms=darwin']).call,
      // Test that macOS plugins support the darwin platform.
      PluginTest('macos', <String>['--platforms=darwin']).call,
    ]),
  );
}
