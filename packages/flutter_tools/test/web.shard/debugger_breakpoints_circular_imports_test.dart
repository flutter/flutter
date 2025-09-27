// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'package:file/file.dart';
import 'package:flutter_tools/src/web/web_device.dart';

import '../integration.shard/test_data/breakpoints_import_cycle_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  late Directory tempDirectory;
  late FlutterRunTestDriver flutter;

  setUp(() {
    tempDirectory = createResolvedTempDirectorySync('debugger_breakpoints_import_cycle_test.');
  });

  testWithoutContext('Web debugger can stop at breakpoints in library cycles', () async {
    final project = BreakpointsImportCycleProject();
    await project.setUpIn(tempDirectory);

    flutter = FlutterRunTestDriver(project.dir);

    await flutter.run(
      withDebugger: true,
      startPaused: true,
      device: GoogleChromeDevice.kChromeDeviceId,
      additionalCommandArgs: <String>['--verbose', '--no-web-resources-cdn'],
    );
    await flutter.addBreakpoint(project.breakpointUri1, project.breakpointLine1);
    await flutter.resume(waitForNextPause: true);
    expect((await flutter.getSourceLocation())!.line, equals(project.breakpointLine1));

    await flutter.addBreakpoint(project.breakpointUri2, project.breakpointLine2);
    await flutter.resume(waitForNextPause: true);
    expect((await flutter.getSourceLocation())!.line, equals(project.breakpointLine2));

    await flutter.resume();

    // TODO(nshahan): Add some expectation that the program ran to completion.

    await flutter.quit();
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDirectory);
  });
}
