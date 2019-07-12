// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/testbed.dart';

void main() {
  group('ResidentRunner', () {
    final Uri testUri = Uri.parse('foo://bar');
    Testbed testbed;
    MockDevice mockDevice;
    MockVMService mockVMService;
    MockDevFS mockDevFS;
    ResidentRunner residentRunner;

    setUp(() {
      testbed = Testbed(setup: () {
        residentRunner = HotRunner(
          <FlutterDevice>[
            mockDevice,
          ],
          stayResident: false,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        );
      });
      mockDevice = MockDevice();
      mockVMService = MockVMService();
      mockDevFS = MockDevFS();
      // DevFS Mocks
      when(mockDevFS.lastCompiled).thenReturn(DateTime(2000));
      when(mockDevFS.sources).thenReturn(<Uri>[]);
      when(mockDevFS.destroy()).thenAnswer((Invocation invocation) async { });
      // FlutterDevice Mocks.
      when(mockDevice.updateDevFS(
        // Intentionally provide empty list to match above mock.
        invalidatedFiles: <Uri>[],
        mainPath: anyNamed('mainPath'),
        target: anyNamed('target'),
        bundle: anyNamed('bundle'),
        firstBuildTime: anyNamed('firstBuildTime'),
        bundleFirstUpload: anyNamed('bundleFirstUpload'),
        bundleDirty: anyNamed('bundleDirty'),
        fullRestart: anyNamed('fullRestart'),
        projectRootPath: anyNamed('projectRootPath'),
        pathToReload: anyNamed('pathToReload'),
      )).thenAnswer((Invocation invocation) async {
        return UpdateFSReport(
          success: true,
          syncedBytes: 0,
          invalidatedSourcesCount: 0,
        );
      });
      when(mockDevice.devFS).thenReturn(mockDevFS);
      when(mockDevice.views).thenReturn(<FlutterView>[
        MockFlutterView(),
      ]);
      when(mockDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) async { });
      when(mockDevice.observatoryUris).thenReturn(<Uri>[
        testUri,
      ]);
      when(mockDevice.connect(
        reloadSources: anyNamed('reloadSources'),
        restart: anyNamed('restart'),
        compileExpression: anyNamed('compileExpression')
      )).thenAnswer((Invocation invocation) async { });
      when(mockDevice.setupDevFS(any, any, packagesFilePath: anyNamed('packagesFilePath')))
        .thenAnswer((Invocation invocation) async {
          return testUri;
        });
      when(mockDevice.vmServices).thenReturn(<VMService>[
        mockVMService,
      ]);
      when(mockDevice.refreshViews()).thenAnswer((Invocation invocation) async { });
      // VMService mocks.
      when(mockVMService.wsAddress).thenReturn(testUri);
      when(mockVMService.done).thenAnswer((Invocation invocation) {
        final Completer<void> result = Completer<void>.sync();
        return result.future;
      });
    });

    test('Can attach to device successfully', () => testbed.run(() async {
      final Completer<DebugConnectionInfo> onConnectionInfo = Completer<DebugConnectionInfo>.sync();
      final Completer<void> onAppStart = Completer<void>.sync();
      final Future<int> result = residentRunner.attach(
        appStartedCompleter: onAppStart,
        connectionInfoCompleter: onConnectionInfo,
      );
      final Future<DebugConnectionInfo> connectionInfo = onConnectionInfo.future;

      expect(await result, 0);

      verify(mockDevice.initLogReader()).called(1);

      expect(onConnectionInfo.isCompleted, true);
      expect((await connectionInfo).baseUri, 'foo://bar');
      expect(onAppStart.isCompleted, true);
    }));
  });
}

class MockDevice extends Mock implements FlutterDevice {}
class MockFlutterView extends Mock implements FlutterView {}
class MockVMService extends Mock implements VMService {}
class MockDevFS extends Mock implements DevFS {}
