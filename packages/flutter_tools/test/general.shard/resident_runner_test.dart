// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  final Uri testUri = Uri.parse('foo://bar');
  Testbed testbed;
  MockFlutterDevice mockFlutterDevice;
  MockVMService mockVMService;
  MockDevFS mockDevFS;
  MockFlutterView mockFlutterView;
  ResidentRunner residentRunner;
  MockDevice mockDevice;
  MockIsolate mockIsolate;

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
    mockIsolate = MockIsolate();
    // DevFS Mocks
    when(mockDevFS.lastCompiled).thenReturn(DateTime(2000));
    when(mockDevFS.sources).thenReturn(<Uri>[]);
    when(mockDevFS.baseUri).thenReturn(Uri());
    when(mockDevFS.destroy()).thenAnswer((Invocation invocation) async { });
    when(mockDevFS.assetPathsToEvict).thenReturn(<String>{});
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
      dillOutputPath: anyNamed('dillOutputPath'),
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
    when(mockFlutterView.uiIsolate).thenReturn(mockIsolate);
    when(mockFlutterView.runFromSource(any, any, any)).thenAnswer((Invocation invocation) async {});
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
    when(mockFlutterDevice.reloadSources(any, pause: anyNamed('pause'))).thenReturn(<Future<Map<String, dynamic>>>[
      Future<Map<String, dynamic>>.value(<String, dynamic>{
        'type': 'ReloadReport',
        'success': true,
        'details': <String, dynamic>{
          'loadedLibraryCount': 1,
          'finalLibraryCount': 1,
          'receivedLibraryCount': 1,
          'receivedClassesCount': 1,
          'receivedProceduresCount': 1,
        },
      }),
    ]);
    // VMService mocks.
    when(mockVMService.wsAddress).thenReturn(testUri);
    when(mockVMService.done).thenAnswer((Invocation invocation) {
      final Completer<void> result = Completer<void>.sync();
      return result.future;
    });
    when(mockIsolate.resume()).thenAnswer((Invocation invocation) {
      return Future<Map<String, Object>>.value(null);
    });
    when(mockIsolate.flutterExit()).thenAnswer((Invocation invocation) {
      return Future<Map<String, Object>>.value(null);
    });
    when(mockIsolate.reload()).thenAnswer((Invocation invocation) {
      return Future<ServiceObject>.value(null);
    });
  });

  test('ResidentRunner can attach to device successfully', () => testbed.run(() async {
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

  test('ResidentRunner can handle an RPC exception from hot reload', () => testbed.run(() async {
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
      dillOutputPath: anyNamed('dillOutputPath'),
    )).thenThrow(RpcException(666, 'something bad happened'));

    final OperationResult result = await residentRunner.restart(fullRestart: false);
    expect(result.fatal, true);
    expect(result.code, 1);
    verify(flutterUsage.sendEvent('hot', 'exception', parameters: <String, String>{
      cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
      cdKey(CustomDimensions.hotEventSdkName): 'Example',
      cdKey(CustomDimensions.hotEventEmulator): 'false',
      cdKey(CustomDimensions.hotEventFullRestart): 'false',
    })).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  test('ResidentRunner can send target platform to analytics from hot reload', () => testbed.run(() async {
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

    final OperationResult result = await residentRunner.restart(fullRestart: false);
    expect(result.fatal, false);
    expect(result.code, 0);
    expect(verify(flutterUsage.sendEvent('hot', 'reload',
                  parameters: captureAnyNamed('parameters'))).captured[0],
      containsPair(cdKey(CustomDimensions.hotEventTargetPlatform),
                   getNameForTargetPlatform(TargetPlatform.android_arm))
    );
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  test('ResidentRunner can send target platform to analytics from full restart', () => testbed.run(() async {
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

    final OperationResult result = await residentRunner.restart(fullRestart: true);
    expect(result.fatal, false);
    expect(result.code, 0);
    expect(verify(flutterUsage.sendEvent('hot', 'restart',
                  parameters: captureAnyNamed('parameters'))).captured[0],
      containsPair(cdKey(CustomDimensions.hotEventTargetPlatform),
                   getNameForTargetPlatform(TargetPlatform.android_arm))
    );
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  test('ResidentRunner Can handle an RPC exception from hot restart', () => testbed.run(() async {
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
      dillOutputPath: anyNamed('dillOutputPath'),
    )).thenThrow(RpcException(666, 'something bad happened'));

    final OperationResult result = await residentRunner.restart(fullRestart: true);
    expect(result.fatal, true);
    expect(result.code, 1);
    verify(flutterUsage.sendEvent('hot', 'exception', parameters: <String, String>{
      cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
      cdKey(CustomDimensions.hotEventSdkName): 'Example',
      cdKey(CustomDimensions.hotEventEmulator): 'false',
      cdKey(CustomDimensions.hotEventFullRestart): 'true',
    })).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  test('ResidentRunner uses temp directory when there is no output dill path', () => testbed.run(() {
    expect(residentRunner.artifactDirectory.path, contains('_fluttter_tool'));

    final ResidentRunner otherRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      dillOutputPath: fs.path.join('foobar', 'app.dill'),
    );
    expect(otherRunner.artifactDirectory.path, contains('foobar'));
  }));

  test('ResidentRunner printHelpDetails', () => testbed.run(() {
    when(mockDevice.supportsHotRestart).thenReturn(true);
    when(mockDevice.supportsScreenshot).thenReturn(true);

    residentRunner.printHelp(details: true);
    final BufferLogger bufferLogger = context.get<Logger>();

    // supports service protocol
    expect(residentRunner.supportsServiceProtocol, true);
    expect(bufferLogger.statusText, contains('"w"'));
    expect(bufferLogger.statusText, contains('"t"'));
    expect(bufferLogger.statusText, contains('"P"'));
    expect(bufferLogger.statusText, contains('"a"'));
    // isRunningDebug
    expect(residentRunner.isRunningDebug, true);
    expect(bufferLogger.statusText, contains('"L"'));
    expect(bufferLogger.statusText, contains('"S"'));
    expect(bufferLogger.statusText, contains('"U"'));
    expect(bufferLogger.statusText, contains('"i"'));
    expect(bufferLogger.statusText, contains('"p"'));
    expect(bufferLogger.statusText, contains('"o"'));
    expect(bufferLogger.statusText, contains('"z"'));
    // screenshot
    expect(bufferLogger.statusText, contains('"s"'));
  }));

  test('ResidentRunner can take screenshot on debug device', () => testbed.run(() async {
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockDevice.takeScreenshot(any))
        .thenAnswer((Invocation invocation) async {
      final File file = invocation.positionalArguments.first;
      file.writeAsBytesSync(List<int>.generate(1024, (int i) => i));
    });
    final BufferLogger bufferLogger = context.get<Logger>();

    await residentRunner.screenshot(mockFlutterDevice);

    // disables debug banner.
    verify(mockIsolate.flutterDebugAllowBanner(false)).called(1);
    // Enables debug banner.
    verify(mockIsolate.flutterDebugAllowBanner(true)).called(1);
    expect(bufferLogger.statusText, contains('1kB'));
  }));

  test('ResidentRunner bails taking screenshot on debug device if debugAllowBanner throws pre', () => testbed.run(() async {
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockIsolate.flutterDebugAllowBanner(false)).thenThrow(Exception());
    final BufferLogger bufferLogger = context.get<Logger>();

    await residentRunner.screenshot(mockFlutterDevice);

    expect(bufferLogger.errorText, contains('Error'));
  }));

  test('ResidentRunner bails taking screenshot on debug device if debugAllowBanner throws post', () => testbed.run(() async {
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockIsolate.flutterDebugAllowBanner(true)).thenThrow(Exception());
    final BufferLogger bufferLogger = context.get<Logger>();

    await residentRunner.screenshot(mockFlutterDevice);

    expect(bufferLogger.errorText, contains('Error'));
  }));

  test('ResidentRunner bails taking screenshot on debug device if takeScreenshot throws', () => testbed.run(() async {
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockDevice.takeScreenshot(any)).thenThrow(Exception());
    final BufferLogger bufferLogger = context.get<Logger>();

    await residentRunner.screenshot(mockFlutterDevice);

    expect(bufferLogger.errorText, contains('Error'));
  }));

  test('ResidentRunner can\'t take screenshot on device without support', () => testbed.run(() {
    when(mockDevice.supportsScreenshot).thenReturn(false);

    expect(() => residentRunner.screenshot(mockFlutterDevice),
        throwsA(isInstanceOf<AssertionError>()));
  }));

  test('ResidentRunner does not toggle banner in non-debug mode', () => testbed.run(() async {
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
    );
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockDevice.takeScreenshot(any))
        .thenAnswer((Invocation invocation) async {
      final File file = invocation.positionalArguments.first;
      file.writeAsBytesSync(List<int>.generate(1024, (int i) => i));
    });
    final BufferLogger bufferLogger = context.get<Logger>();

    await residentRunner.screenshot(mockFlutterDevice);

    // doesn't disabled debug banner.
    verifyNever(mockIsolate.flutterDebugAllowBanner(false));
    // doesn't enable debug banner.
    verifyNever(mockIsolate.flutterDebugAllowBanner(true));
    expect(bufferLogger.statusText, contains('1kB'));
  }));

  test('FlutterDevice will not exit a paused isolate', () => testbed.run(() async {
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      <FlutterView>[ mockFlutterView ],
    );
    final MockServiceEvent mockServiceEvent = MockServiceEvent();
    when(mockServiceEvent.isPauseEvent).thenReturn(true);
    when(mockIsolate.pauseEvent).thenReturn(mockServiceEvent);
    when(mockDevice.supportsFlutterExit).thenReturn(true);

    await flutterDevice.exitApps();

    verifyNever(mockIsolate.flutterExit());
    verify(mockDevice.stopApp(any)).called(1);
  }));

  test('FlutterDevice will exit an un-paused isolate', () => testbed.run(() async {
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      <FlutterView> [mockFlutterView ],
    );

    final MockServiceEvent mockServiceEvent = MockServiceEvent();
    when(mockServiceEvent.isPauseEvent).thenReturn(false);
    when(mockIsolate.pauseEvent).thenReturn(mockServiceEvent);
    when(mockDevice.supportsFlutterExit).thenReturn(true);

    await flutterDevice.exitApps();

    verify(mockIsolate.flutterExit()).called(1);
  }));

  test('ResidentRunner refreshViews calls flutter device', () => testbed.run(() async {
    await residentRunner.refreshViews();

    verify(mockFlutterDevice.refreshViews()).called(1);
  }));

  test('ResidentRunner debugDumpApp calls flutter device', () => testbed.run(() async {
    await residentRunner.debugDumpApp();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpApp()).called(1);
  }));

  test('ResidentRunner debugDumpRenderTree calls flutter device', () => testbed.run(() async {
    await residentRunner.debugDumpRenderTree();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpRenderTree()).called(1);
  }));

  test('ResidentRunner debugDumpLayerTree calls flutter device', () => testbed.run(() async {
    await residentRunner.debugDumpLayerTree();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpLayerTree()).called(1);
  }));

  test('ResidentRunner debugDumpSemanticsTreeInTraversalOrder calls flutter device', () => testbed.run(() async {
    await residentRunner.debugDumpSemanticsTreeInTraversalOrder();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpSemanticsTreeInTraversalOrder()).called(1);
  }));

  test('ResidentRunner debugDumpSemanticsTreeInInverseHitTestOrder calls flutter device', () => testbed.run(() async {
    await residentRunner.debugDumpSemanticsTreeInInverseHitTestOrder();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpSemanticsTreeInInverseHitTestOrder()).called(1);
  }));

  test('ResidentRunner debugToggleDebugPaintSizeEnabled calls flutter device', () => testbed.run(() async {
    await residentRunner.debugToggleDebugPaintSizeEnabled();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleDebugPaintSizeEnabled()).called(1);
  }));

  test('ResidentRunner debugToggleDebugCheckElevationsEnabled calls flutter device', () => testbed.run(() async {
    await residentRunner.debugToggleDebugCheckElevationsEnabled();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleDebugCheckElevationsEnabled()).called(1);
  }));

  test('ResidentRunner debugTogglePerformanceOverlayOverride calls flutter device', () => testbed.run(()async {
    await residentRunner.debugTogglePerformanceOverlayOverride();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugTogglePerformanceOverlayOverride()).called(1);
  }));

  test('ResidentRunner debugToggleWidgetInspector calls flutter device', () => testbed.run(() async {
    await residentRunner.debugToggleWidgetInspector();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleWidgetInspector()).called(1);
  }));

  test('ResidentRunner debugToggleProfileWidgetBuilds calls flutter device', () => testbed.run(() async {
    await residentRunner.debugToggleProfileWidgetBuilds();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleProfileWidgetBuilds()).called(1);
  }));
}

class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockFlutterView extends Mock implements FlutterView {}
class MockVMService extends Mock implements VMService {}
class MockDevFS extends Mock implements DevFS {}
class MockIsolate extends Mock implements Isolate {}
class MockDevice extends Mock implements Device {}
class MockUsage extends Mock implements Usage {}
class MockServiceEvent extends Mock implements ServiceEvent {}
class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice(Device device, this.views)
    : super(device, buildMode: BuildMode.debug, trackWidgetCreation: false);

  @override
  final List<FlutterView> views;
}

