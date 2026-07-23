// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart';
import '../src/testbed.dart';
import 'resident_runner_helpers.dart';

void main() {
  late TestBed testbed;
  late FakeFlutterDevice flutterDevice;
  late ScreenshotFakeDevice device;
  FakeVmServiceHost? fakeVmServiceHost;

  setUp(() {
    testbed = TestBed(
      setup: () {
        globals.fs.file(globals.fs.path.join('build', 'app.dill'))
          ..createSync(recursive: true)
          ..writeAsStringSync('ABC');
      },
      overrides: <Type, Generator>{
        Analytics: () => getInitializedFakeAnalyticsInstance(
          fakeFlutterVersion: FakeFlutterVersion(),
          fs: MemoryFileSystem.test(),
        ),
      },
    );
    device = ScreenshotFakeDevice();
    flutterDevice = FakeFlutterDevice()
      ..testUri = Uri.parse('foo://bar')
      ..vmServiceHost = (() => fakeVmServiceHost)
      ..device = device;
  });

  testUsingContext(
    'screenshot commands still take screenshot even if debug banner fails to toggle',
    () => testbed.run(() async {
      final residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: globals.analytics,
      );

      // Setup VmService to fail on debugAllowBanner.
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          listViews,
          const FakeVmServiceRequest(
            method: 'ext.flutter.debugAllowBanner',
            args: <String, Object>{'isolateId': '1', 'enabled': 'false'},
            error: FakeRPCError(code: -32603), // kInternalError
          ),
        ],
      );

      expect(device.takeScreenshotCalled, false);
      await residentRunner.screenshot(flutterDevice);
      expect(device.takeScreenshotCalled, true);
    }),
  );
}

class ScreenshotFakeDevice extends Fake implements Device {
  bool takeScreenshotCalled = false;

  @override
  final String name = 'FakeDevice';

  @override
  String get displayName => name;

  @override
  final String id = '123';

  @override
  bool supportsScreenshot = true;

  @override
  bool get isConnected => true;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    takeScreenshotCalled = true;
    outputFile.writeAsBytesSync(<int>[1, 2, 3, 4]);
  }
}
