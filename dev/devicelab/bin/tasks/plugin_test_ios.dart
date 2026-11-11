// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/plugin_tests.dart';

Future<void> main() async {
  await task(
    combine(<TaskFunction>[
      PluginTest('ios', <String>['--platforms=ios']).call,
      // Test that app builds with Flutter as a transitive dependency. The
      // plugin is the same as above, so no need to test again.
      PluginTest(
        'ios',
        <String>['--platforms=ios'],
        cocoapodsTransitiveFlutterDependency: true,
        testPlugin: false,
      ).call,
      // Test that Dart-only plugins are supported.
      PluginTest('ios', <String>['--platforms=ios'], dartOnlyPlugin: true).call,
      // Test that FFI plugins are supported.
      PluginTest('ios', <String>['--platforms=ios'], template: 'plugin_ffi').call,
    ]),
  );
}
