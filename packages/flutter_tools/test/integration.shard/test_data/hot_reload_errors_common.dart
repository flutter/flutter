// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;
import 'package:vm_service/vm_service.dart';

import '../../src/common.dart';
import '../test_driver.dart';
import '../test_utils.dart';
import 'hot_reload_const_project.dart';

void testAll({
  bool chrome = false,
  List<String> additionalCommandArgs = const <String>[],
  Object? skip = false,
}) {
  group('chrome: $chrome'
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
    late Directory tempDir;
    final project = HotReloadConstProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_reload_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext(
      'hot reload displays a formatted error message when removing a field from a const class, and hot restart succeeds',
      () async {
        await flutter.run(
          device: chrome
              ? GoogleChromeDevice.kChromeDeviceId
              : FlutterTesterDevices.kTesterDeviceId,
          additionalCommandArgs: additionalCommandArgs,
        );

        project.removeFieldFromConstClass();
        await expectLater(
          flutter.hotReload(),
          throwsA(
            isA<Exception>().having(
              (Exception e) => e.toString(),
              'message',
              contains('Try performing a hot restart instead.'),
            ),
          ),
        );
        await expectLater(flutter.hotRestart(), completes);
      },
    );

    testWithoutContext(
      'Expression evaluation succeeds after a hot reload rejection error',
      () async {
        await flutter.run(
          device: chrome
              ? GoogleChromeDevice.kChromeDeviceId
              : FlutterTesterDevices.kTesterDeviceId,
          withDebugger: true,
          additionalCommandArgs: additionalCommandArgs,
        );
        project.removeFieldFromConstClass();
        await expectLater(
          flutter.hotReload(),
          throwsA(
            isA<Exception>().having(
              (Exception e) => e.toString(),
              'message',
              contains('Try performing a hot restart instead.'),
            ),
          ),
        );
        final LibraryRef library = (await flutter.getFlutterIsolate()).libraries!.firstWhere(
          (LibraryRef l) => l.uri!.contains('package:test/main.dart'),
        );
        final ObjRef result = await flutter.evaluate(library.id!, '42.isEven');
        expect(
          result,
          const TypeMatcher<InstanceRef>()
              .having((InstanceRef instance) => instance.kind, 'kind', InstanceKind.kBool)
              .having(
                (InstanceRef instance) => instance.valueAsString,
                'valueAsString',
                true.toString(),
              ),
        );
      },
    );
  });
}
