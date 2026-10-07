// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/drive/web_driver_service.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:package_config/package_config_types.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../src/common.dart';
import '../src/fakes.dart';
import '../src/test_build_system.dart';

void main() {
  testWithoutContext(
    'WebDriverService catches SocketExceptions cleanly and includes link to documentation',
    () async {
      final service = WebDriverService(
        analytics: const NoOpAnalytics(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        buildTargets: const BuildTargetsImpl(),
        dartSdkPath: 'dart',
        toolContext: FakeToolContext(),
      );
      const link = 'https://flutter.dev/to/integration-test-on-web';
      try {
        await service.startTest(
          'foo.test',
          <String>[],
          PackageConfig(<Package>[Package('test', Uri.base)]),
          driverPort: 1,
          headless: true,
          browserName: 'chrome',
        );
        fail('WebDriverService did not throw as expected.');
      } on ToolExit catch (error) {
        expect(error.message, isNot(contains('SocketException')));
        expect(error.message, contains(link));
      }
    },
  );
}
