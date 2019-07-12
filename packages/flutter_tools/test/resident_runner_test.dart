// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/testbed.dart';

void main() {
  group('ResidentRunner', () {
    final Uri testUri = Uri.parse('foo://bar');
    Testbed testbed;
    MockFlutterDevice mockFlutterDevice;
    MockVMService mockVMService;
    MockDevFS mockDevFS;
    MockFlutterView mockFlutterView;
    ResidentRunner residentRunner;
    MockDevice mockDevice;

    setUp(() {
      testbed = Testbed(setup: () {
        residentRunner = HotRunner(
          <FlutterDevice>[
            mockFlutterDevice,
          ],
          stayResident: false,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        );
      });
      mockFlutterDevice = MockFlutterDevice();
      mockDevice = MockDevice();
      mockVMService = MockVMService();
      mockDevFS = MockDevFS();
      mockFlutterView = MockFlutterView();
      // DevFS Mocks
      when(mockDevFS.lastCompiled).thenReturn(DateTime(2000));
      when(mockDevFS.sources).thenReturn(<Uri>[]);
      when(mockDevFS.destroy()).thenAnswer((Invocation invocation) async { });
      // FlutterDevice Mocks.
      when(mockFlutterDevice.updateDevFS(
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
      when(mockFlutterDevice.devFS).thenReturn(mockDevFS);
      when(mockFlutterDevice.views).thenReturn(<FlutterView>[
        mockFlutterView
      ]);
      when(mockFlutterDevice.device).thenReturn(mockDevice);
      when(mockFlutterView.uiIsolate).thenReturn(MockIsolate());
      when(mockFlutterDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) async { });
      when(mockFlutterDevice.observatoryUris).thenReturn(<Uri>[
        testUri,
      ]);
      when(mockFlutterDevice.connect(
        reloadSources: anyNamed('reloadSources'),
        restart: anyNamed('restart'),
        compileExpression: anyNamed('compileExpression')
      )).thenAnswer((Invocation invocation) async { });
      when(mockFlutterDevice.setupDevFS(any, any, packagesFilePath: anyNamed('packagesFilePath')))
        .thenAnswer((Invocation invocation) async {
          return testUri;
        });
      when(mockFlutterDevice.vmServices).thenReturn(<VMService>[
        mockVMService,
      ]);
      when(mockFlutterDevice.refreshViews()).thenAnswer((Invocation invocation) async { });
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

      verify(mockFlutterDevice.initLogReader()).called(1);

      expect(onConnectionInfo.isCompleted, true);
      expect((await connectionInfo).baseUri, 'foo://bar');
      expect(onAppStart.isCompleted, true);
    }));

    test('Can handle an RPC exception from hot reload', () => testbed.run(() async {
      when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation invocation) async {
        return 'Example';
      });
      when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
        return TargetPlatform.android_arm;
      });
      when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) async {
        return false;
      });
      final Completer<DebugConnectionInfo> onConnectionInfo = Completer<DebugConnectionInfo>.sync();
      final Completer<void> onAppStart = Completer<void>.sync();
      unawaited(residentRunner.attach(
        appStartedCompleter: onAppStart,
        connectionInfoCompleter: onConnectionInfo,
      ));
      await onAppStart.future;
      when(mockFlutterDevice.updateDevFS(
        mainPath: anyNamed('mainPath'),
        target: anyNamed('target'),
        bundle: anyNamed('bundle'),
        firstBuildTime: anyNamed('firstBuildTime'),
        bundleFirstUpload: anyNamed('bundleFirstUpload'),
        bundleDirty: anyNamed('bundleDirty'),
        fullRestart: anyNamed('fullRestart'),
        projectRootPath: anyNamed('projectRootPath'),
        pathToReload: anyNamed('pathToReload'),
        invalidatedFiles: anyNamed('invalidatedFiles'),
      )).thenThrow(RpcException(666, 'something bad happened'));

      final OperationResult result = await residentRunner.restart(fullRestart: false);
      expect(result.fatal, true);
      expect(result.code, 1);
      verify(flutterUsage.sendEvent('unhandled_exception', 'hot_mode', parameters: <String, String>{
        reloadExceptionTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        reloadExceptionSdkName: 'Example',
        reloadExceptionEmulator: 'false',
        reloadExceptionFullRestart: 'false',
      })).called(1);
    }, overrides: <Type, Generator>{
      Usage: () => MockUsage(),
    }));

    test('Can handle an RPC exception from hot restart', () => testbed.run(() async {
      when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation invocation) async {
        return 'Example';
      });
      when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
        return TargetPlatform.android_arm;
      });
      when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) async {
        return false;
      });
      when(mockDevice.supportsHotRestart).thenReturn(true);
      final Completer<DebugConnectionInfo> onConnectionInfo = Completer<DebugConnectionInfo>.sync();
      final Completer<void> onAppStart = Completer<void>.sync();
      unawaited(residentRunner.attach(
        appStartedCompleter: onAppStart,
        connectionInfoCompleter: onConnectionInfo,
      ));
      await onAppStart.future;
      when(mockFlutterDevice.updateDevFS(
        mainPath: anyNamed('mainPath'),
        target: anyNamed('target'),
        bundle: anyNamed('bundle'),
        firstBuildTime: anyNamed('firstBuildTime'),
        bundleFirstUpload: anyNamed('bundleFirstUpload'),
        bundleDirty: anyNamed('bundleDirty'),
        fullRestart: anyNamed('fullRestart'),
        projectRootPath: anyNamed('projectRootPath'),
        pathToReload: anyNamed('pathToReload'),
        invalidatedFiles: anyNamed('invalidatedFiles'),
      )).thenThrow(RpcException(666, 'something bad happened'));

      final OperationResult result = await residentRunner.restart(fullRestart: true);
      expect(result.fatal, true);
      expect(result.code, 1);
      verify(flutterUsage.sendEvent('unhandled_exception', 'hot_mode', parameters: <String, String>{
        reloadExceptionTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        reloadExceptionSdkName: 'Example',
        reloadExceptionEmulator: 'false',
        reloadExceptionFullRestart: 'true',
      })).called(1);
    }, overrides: <Type, Generator>{
      Usage: () => MockUsage(),
    }));
  });
}

class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockFlutterView extends Mock implements FlutterView {}
class MockVMService extends Mock implements VMService {}
class MockDevFS extends Mock implements DevFS {}
class MockIsolate extends Mock implements Isolate {}
class MockDevice extends Mock implements Device {}
class MockUsage extends Mock implements Usage {}
