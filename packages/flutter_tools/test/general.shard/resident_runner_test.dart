// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:dds/dds.dart' as dds;
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/command_help.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

final vm_service.Isolate fakeUnpausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kResume,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  extensionRPCs: <String>[],
  libraries: <vm_service.LibraryRef>[
    vm_service.LibraryRef(
      id: '1',
      uri: 'file:///hello_world/main.dart',
      name: '',
    ),
  ],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
);

final vm_service.Isolate fakePausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kPauseException,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[
    vm_service.Breakpoint(
      breakpointNumber: 123,
      id: 'test-breakpoint',
      location: vm_service.SourceLocation(
        tokenPos: 0,
        script: vm_service.ScriptRef(id: 'test-script', uri: 'foo.dart'),
      ),
      resolved: true,
    ),
  ],
  exceptionPauseMode: null,
  libraries: <vm_service.LibraryRef>[],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
);

final vm_service.VM fakeVM = vm_service.VM(
  isolates: <vm_service.IsolateRef>[fakeUnpausedIsolate],
  pid: 1,
  hostCPU: '',
  isolateGroups: <vm_service.IsolateGroupRef>[],
  targetCPU: '',
  startTime: 0,
  name: 'dart',
  architectureBits: 64,
  operatingSystem: '',
  version: '',
  systemIsolateGroups: <vm_service.IsolateGroupRef>[],
  systemIsolates: <vm_service.IsolateRef>[],
);

final FlutterView fakeFlutterView = FlutterView(
  id: 'a',
  uiIsolate: fakeUnpausedIsolate,
);

final FakeVmServiceRequest listViews = FakeVmServiceRequest(
  method: kListViewsMethod,
  jsonResponse: <String, Object>{
    'views': <Object>[
      fakeFlutterView.toJson(),
    ],
  },
);

const FakeVmServiceRequest setAssetBundlePath = FakeVmServiceRequest(
  method: '_flutter.setAssetBundlePath',
  args: <String, Object>{
    'viewId': 'a',
    'assetDirectory': 'build/flutter_assets',
    'isolateId': '1',
  }
);

final Uri testUri = Uri.parse('foo://bar');

void main() {
  Testbed testbed;
  MockFlutterDevice mockFlutterDevice;
  MockVMService mockVMService;
  MockDevFS mockDevFS;
  ResidentRunner residentRunner;
  FakeDevice mockDevice;
  FakeVmServiceHost fakeVmServiceHost;
  MockDevtoolsLauncher mockDevtoolsLauncher;

  setUp(() {
    testbed = Testbed(setup: () {
      globals.fs.file('.packages')
        .writeAsStringSync('\n');
      globals.fs.file(globals.fs.path.join('build', 'app.dill'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ABC');
      residentRunner = HotRunner(
        <FlutterDevice>[
          mockFlutterDevice,
        ],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
      );
    });
    mockFlutterDevice = MockFlutterDevice();
    mockDevice = FakeDevice();
    mockVMService = MockVMService();
    mockDevFS = MockDevFS();
    mockDevtoolsLauncher = MockDevtoolsLauncher();

    // DevFS Mocks
    when(mockDevFS.lastCompiled).thenReturn(DateTime(2000));
    when(mockDevFS.sources).thenReturn(<Uri>[]);
    when(mockDevFS.baseUri).thenReturn(Uri());
    when(mockDevFS.destroy()).thenAnswer((Invocation invocation) async { });
    when(mockDevFS.assetPathsToEvict).thenReturn(<String>{});
    // FlutterDevice Mocks.
    when(mockFlutterDevice.updateDevFS(
      invalidatedFiles: anyNamed('invalidatedFiles'),
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      bundleDirty: anyNamed('bundleDirty'),
      fullRestart: anyNamed('fullRestart'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      dillOutputPath: anyNamed('dillOutputPath'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return UpdateFSReport(
        success: true,
        syncedBytes: 0,
        invalidatedSourcesCount: 1,
      );
    });
    when(mockFlutterDevice.devFS).thenReturn(mockDevFS);
    when(mockFlutterDevice.device).thenReturn(mockDevice);
    when(mockFlutterDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) async { });
    when(mockFlutterDevice.observatoryUris).thenAnswer((_) => Stream<Uri>.value(testUri));
    when(mockFlutterDevice.connect(
      reloadSources: anyNamed('reloadSources'),
      restart: anyNamed('restart'),
      compileExpression: anyNamed('compileExpression'),
      getSkSLMethod: anyNamed('getSkSLMethod'),
      allowExistingDdsInstance: anyNamed('allowExistingDdsInstance'),
    )).thenAnswer((Invocation invocation) async { });
    when(mockFlutterDevice.setupDevFS(any, any))
      .thenAnswer((Invocation invocation) async {
        return testUri;
      });
    when(mockFlutterDevice.vmService).thenAnswer((Invocation invocation) {
      return fakeVmServiceHost?.vmService;
    });
  });

  testUsingContext('ResidentRunner can attach to device successfully', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    final Future<int> result = residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    );
    final Future<DebugConnectionInfo> connectionInfo = futureConnectionInfo.future;

    expect(await result, 0);

    verify(mockFlutterDevice.initLogReader()).called(1);

    expect(futureConnectionInfo.isCompleted, true);
    expect((await connectionInfo).baseUri, 'foo://bar');
    expect(futureAppStart.isCompleted, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner suppresses errors for the initial compilation', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.generator).thenReturn(residentCompiler);
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
      suppressErrors: true,
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('foo', 0 ,<Uri>[]);
    });
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });

    expect(await residentRunner.run(enableDevTools: true), 0);
    verify(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
      suppressErrors: true,
    )).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentRunner calls appFailedToStart if initial compilation fails', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.generator).thenReturn(residentCompiler);
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
      suppressErrors: true,
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('foo', 1 ,<Uri>[]);
    });
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });

    expect(await residentRunner.run(), 1);
    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  }));

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentRunner calls appFailedToStart if initial compilation fails - cold mode', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.runCold(
      coldRunner: anyNamed('coldRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 1;
    });

    expect(await residentRunner.run(), 1);
    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  }));

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentRunner calls appFailedToStart if exception is thrown - cold mode', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.runCold(
      coldRunner: anyNamed('coldRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      throw Exception('BAD STUFF');
    });

    expect(await residentRunner.run(), 1);
    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  }));

  testUsingContext('ResidentRunner does not suppressErrors if running with an applicationBinary', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      applicationBinary: globals.fs.file('app.apk'),
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.generator).thenReturn(residentCompiler);
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
      suppressErrors: false,
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('foo', 0, <Uri>[]);
    });
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });

    expect(await residentRunner.run(enableDevTools: true), 0);
    verify(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
      suppressErrors: false,
    )).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner can attach to device successfully with --fast-start', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        }
      ),
      FakeVmServiceRequest(
        method: kRunInViewMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
          'mainScript': 'main.dart.dill',
          'assetDirectory': 'build/flutter_assets',
        }
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Isolate',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventKind.kIsolateRunnable,
        )
      ),
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        BuildInfo.debug,
        fastStart: true,
        startPaused: true,
      ),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    final Future<int> result = residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    );
    final Future<DebugConnectionInfo> connectionInfo = futureConnectionInfo.future;

    expect(await result, 0);

    verify(mockFlutterDevice.initLogReader()).called(1);

    expect(futureConnectionInfo.isCompleted, true);
    expect((await connectionInfo).baseUri, 'foo://bar');
    expect(futureAppStart.isCompleted, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner can handle an RPC exception from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
      listViews,
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.updateDevFS(
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
    )).thenThrow(vm_service.RPCError('something bad happened', 666, ''));

    final OperationResult result = await residentRunner.restart(fullRestart: false);
    expect(result.fatal, true);
    expect(result.code, 1);
    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'exception', parameters: <String, String>{
        cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
        cdKey(CustomDimensions.hotEventSdkName): 'Android',
        cdKey(CustomDimensions.hotEventEmulator): 'false',
        cdKey(CustomDimensions.hotEventFullRestart): 'false',
      }),
    ));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner fails its operation if the device initialization is not complete', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.devFS).thenReturn(null);

    final OperationResult result = await residentRunner.restart(fullRestart: false);
    expect(result.fatal, false);
    expect(result.code, 1);
    expect(result.message, contains('Device initialization has not completed.'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can handle an reload-barred exception from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
      listViews,
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.updateDevFS(
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
    )).thenThrow(vm_service.RPCError('something bad happened', kIsolateReloadBarred, ''));

    final OperationResult result = await residentRunner.restart(fullRestart: false);
    expect(result.fatal, true);
    expect(result.code, kIsolateReloadBarred);
    expect(result.message, contains('Unable to hot reload application due to an unrecoverable error'));

    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'reload-barred', parameters: <String, String>{
        cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
        cdKey(CustomDimensions.hotEventSdkName): 'Android',
        cdKey(CustomDimensions.hotEventEmulator): 'false',
        cdKey(CustomDimensions.hotEventFullRestart): 'false',
      }),
    ));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner reports hot reload event with null safety analytics', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
      listViews,
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      target: 'main.dart',
      debuggingOptions: DebuggingOptions.enabled(const BuildInfo(
        BuildMode.debug, '', treeShakeIcons: false, extraFrontEndOptions: <String>[
        '--enable-experiment=non-nullable',
        ],
      )),
      devtoolsHandler: createNoOpHandler,
    );
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.updateDevFS(
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
    )).thenThrow(vm_service.RPCError('something bad happened', 666, ''));

    final OperationResult result = await residentRunner.restart(fullRestart: false);
    expect(result.fatal, true);
    expect(result.code, 1);

    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'exception', parameters: <String, String>{
        cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
        cdKey(CustomDimensions.hotEventSdkName): 'Android',
        cdKey(CustomDimensions.hotEventEmulator): 'false',
        cdKey(CustomDimensions.hotEventFullRestart): 'false',
      }),
    ));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner does not reload sources if no sources changed', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
     listViews,
      listViews,
      setAssetBundlePath,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
      ),
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.updateDevFS(
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation _) async {
      return UpdateFSReport(success: true, invalidatedSourcesCount: 0);
    });

    final OperationResult result = await residentRunner.restart(fullRestart: false);

    expect(result.code, 0);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner reports error with missing entrypoint file', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{
          'isolates': <Object>[
            fakeUnpausedIsolate.toJson(),
          ],
        }).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'reloadSources',
        args: <String, Object>{
          'isolateId': '1',
          'pause': false,
          'rootLibUri': 'main.dart.incremental.dill'
        },
        jsonResponse: <String, Object>{
          'type': 'ReloadReport',
          'success': true,
          'details': <String, Object>{
            'loadedLibraryCount': 1,
          },
        },
      ),
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
      ),
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.updateDevFS(
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return UpdateFSReport(success: true, invalidatedSourcesCount: 1);
    });

    final OperationResult result = await residentRunner.restart(fullRestart: false);

    expect(globals.fs.file(globals.fs.path.join('lib', 'main.dart')), isNot(exists));
    expect(testLogger.errorText, contains('The entrypoint file (i.e. the file with main())'));
    expect(result.fatal, false);
    expect(result.code, 0);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

   testUsingContext('ResidentRunner resets compilation time on reload reject', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{
          'isolates': <Object>[
            fakeUnpausedIsolate.toJson(),
          ],
        }).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'reloadSources',
        args: <String, Object>{
          'isolateId': '1',
          'pause': false,
          'rootLibUri': 'main.dart.incremental.dill'
        },
        jsonResponse: <String, Object>{
          'type': 'ReloadReport',
          'success': false,
          'notices': <Object>[
            <String, Object>{
              'message': 'Failed to hot reload'
            }
          ],
          'details': <String, Object>{},
        },
      ),
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
      ),
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.updateDevFS(
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return UpdateFSReport(success: true, invalidatedSourcesCount: 1);
    });

    final OperationResult result = await residentRunner.restart(fullRestart: false);

    expect(result.fatal, false);
    expect(result.message, contains('Reload rejected: Failed to hot reload')); // contains error message from reload report.
    expect(result.code, 1);
    verify(mockDevFS.resetLastCompiled()).called(1); // compilation time is reset.
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner can send target platform to analytics from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{
          'isolates': <Object>[
            fakeUnpausedIsolate.toJson(),
          ],
        }).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'reloadSources',
        args: <String, Object>{
          'isolateId': '1',
          'pause': false,
          'rootLibUri': 'main.dart.incremental.dill'
        },
        jsonResponse: <String, Object>{
          'type': 'ReloadReport',
          'success': true,
          'details': <String, Object>{
            'loadedLibraryCount': 1,
          },
        },
      ),
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
      ),
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;

    final OperationResult result = await residentRunner.restart(fullRestart: false);
    expect(result.fatal, false);
    expect(result.code, 0);

    final TestUsageEvent event = (globals.flutterUsage as TestUsage).events.first;
    expect(event.category, 'hot');
    expect(event.parameter, 'reload');
    expect(event.parameters, containsPair(
                  cdKey(CustomDimensions.hotEventTargetPlatform),
                  getNameForTargetPlatform(TargetPlatform.android_arm),
                ));
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner can perform fast reassemble', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      listViews,
      setAssetBundlePath,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'reloadSources',
        args: <String, Object>{
          'isolateId': '1',
          'pause': false,
          'rootLibUri': 'main.dart.incremental.dill',
        },
        jsonResponse: <String, Object>{
          'type': 'ReloadReport',
          'success': true,
          'details': <String, Object>{
            'loadedLibraryCount': 1,
          },
        },
      ),
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.fastReassemble',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'className': 'FOO',
        },
      ),
    ]);
    final FakeFlutterDevice flutterDevice =  FakeFlutterDevice(
      mockDevice,
      BuildInfo.debug,
      FakeResidentCompiler(),
      mockDevFS,
    )..vmService = fakeVmServiceHost.vmService;
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockDevFS.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation invocation) async {
      return UpdateFSReport(
        success: true,
        fastReassembleClassName: 'FOO',
        invalidatedSourcesCount: 1,
      );
    });

    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));

    await futureAppStart.future;
    final OperationResult result = await residentRunner.restart(fullRestart: false);

    expect(result.fatal, false);
    expect(result.code, 0);

    final TestUsageEvent event = (globals.flutterUsage as TestUsage).events.first;
    expect(event.category, 'hot');
    expect(event.parameter, 'reload');
    expect(event.parameters, containsPair(
      cdKey(CustomDimensions.fastReassemble), 'true',
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    Platform: () => FakePlatform(operatingSystem: 'linux'),
    ProjectFileInvalidator: () => FakeProjectFileInvalidator(),
    Usage: () => TestUsage(),
    FeatureFlags: () => TestFeatureFlags(isSingleWidgetReloadEnabled: true),
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner can send target platform to analytics from full restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      setAssetBundlePath,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      FakeVmServiceRequest(
        method: kRunInViewMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
          'mainScript': 'main.dart.dill',
          'assetDirectory': 'build/flutter_assets',
        },
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Isolate',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventKind.kIsolateRunnable,
        )
      )
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));

    final OperationResult result = await residentRunner.restart(fullRestart: true);
    expect(result.fatal, false);
    expect(result.code, 0);

    final TestUsageEvent event = (globals.flutterUsage as TestUsage).events.first;
    expect(event.category, 'hot');
    expect(event.parameter, 'restart');
    expect(event.parameters, containsPair(
      cdKey(CustomDimensions.hotEventTargetPlatform), getNameForTargetPlatform(TargetPlatform.android_arm),
    ));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner can remove breakpoints from paused isolate during hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      setAssetBundlePath,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakePausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'removeBreakpoint',
        args: <String, String>{
          'isolateId': '1',
          'breakpointId': 'test-breakpoint',
        }
      ),
      const FakeVmServiceRequest(
        method: 'resume',
        args: <String, String>{
          'isolateId': '1',
        }
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      FakeVmServiceRequest(
        method: kRunInViewMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
          'mainScript': 'main.dart.dill',
          'assetDirectory': 'build/flutter_assets',
        },
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Isolate',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventKind.kIsolateRunnable,
        )
      )
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));

    final OperationResult result = await residentRunner.restart(fullRestart: true);

    expect(result.isOk, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner will alternative the name of the dill file uploaded for a hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      setAssetBundlePath,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      FakeVmServiceRequest(
        method: kRunInViewMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
          'mainScript': 'main.dart.dill',
          'assetDirectory': 'build/flutter_assets',
        },
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Isolate',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventKind.kIsolateRunnable,
        ),
      ),
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      FakeVmServiceRequest(
        method: kRunInViewMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
          'mainScript': 'main.dart.swap.dill',
          'assetDirectory': 'build/flutter_assets',
        },
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Isolate',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventKind.kIsolateRunnable,
        ),
      ),
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      listViews,
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      FakeVmServiceRequest(
        method: kRunInViewMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
          'mainScript': 'main.dart.dill',
          'assetDirectory': 'build/flutter_assets',
        },
      ),
      FakeVmServiceStreamResponse(
        streamId: 'Isolate',
        event: vm_service.Event(
          timestamp: 0,
          kind: vm_service.EventKind.kIsolateRunnable,
        ),
      )
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));

    await residentRunner.restart(fullRestart: true);
    await residentRunner.restart(fullRestart: true);
    await residentRunner.restart(fullRestart: true);

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner Can handle an RPC exception from hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));
    await futureAppStart.future;
    when(mockFlutterDevice.updateDevFS(
      mainUri: anyNamed('mainUri'),
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
      packageConfig: anyNamed('packageConfig'),
    )).thenThrow(vm_service.RPCError('something bad happened', 666, ''));

    final OperationResult result = await residentRunner.restart(fullRestart: true);
    expect(result.fatal, true);
    expect(result.code, 1);

    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'exception', parameters: <String, String>{
        cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
        cdKey(CustomDimensions.hotEventSdkName): 'Android',
        cdKey(CustomDimensions.hotEventEmulator): 'false',
        cdKey(CustomDimensions.hotEventFullRestart): 'true',
      }),
    ));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner uses temp directory when there is no output dill path', () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    expect(residentRunner.artifactDirectory.path, contains('flutter_tool.'));

    final ResidentRunner otherRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      dillOutputPath: globals.fs.path.join('foobar', 'app.dill'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    expect(otherRunner.artifactDirectory.path, contains('foobar'));
  }));

  testUsingContext('ResidentRunner deletes artifact directory on preExit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner.artifactDirectory.childFile('app.dill').createSync();
    await residentRunner.preExit();

    expect(residentRunner.artifactDirectory, isNot(exists));
  }));

  testUsingContext('ResidentRunner can run source generation', () => testbed.run(() async {
    final File arbFile = globals.fs.file(globals.fs.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    globals.fs.file('l10n.yaml').createSync();
    globals.fs.file('pubspec.yaml').writeAsStringSync('flutter:\n  generate: true\n');

    await residentRunner.runSourceGenerators();

    expect(testLogger.errorText, isEmpty);
    expect(testLogger.statusText, isEmpty);
  }));

  testUsingContext('ResidentRunner can run source generation - generation fails', () => testbed.run(() async {
    // Intentionally define arb file with wrong name. generate_localizations defaults
    // to app_en.arb.
    final File arbFile = globals.fs.file(globals.fs.path.join('lib', 'l10n', 'foo.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    globals.fs.file('l10n.yaml').createSync();
    globals.fs.file('pubspec.yaml').writeAsStringSync('flutter:\n  generate: true\n');

    await residentRunner.runSourceGenerators();

    expect(testLogger.errorText, allOf(contains('Exception')));
    expect(testLogger.statusText, isEmpty);
  }));

  testUsingContext('ResidentRunner printHelpDetails', () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    residentRunner.printHelp(details: true);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // supports service protocol
    expect(residentRunner.supportsServiceProtocol, true);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, true);
    // does support SkSL
    expect(residentRunner.supportsWriteSkSL, true);
    // commands
    expect(testLogger.statusText, equals(
        <dynamic>[
          'Flutter run key commands.',
          commandHelp.r,
          commandHelp.R,
          commandHelp.h,
          commandHelp.c,
          commandHelp.q,
          commandHelp.s,
          commandHelp.b,
          commandHelp.w,
          commandHelp.t,
          commandHelp.L,
          commandHelp.S,
          commandHelp.U,
          commandHelp.i,
          commandHelp.I,
          commandHelp.p,
          commandHelp.o,
          commandHelp.z,
          commandHelp.g,
          commandHelp.M,
          commandHelp.v,
          commandHelp.P,
          commandHelp.a,
          '',
          '💪 Running with sound null safety 💪',
          '',
          'An Observatory debugger and profiler on FakeDevice is available at: null',
          '',
        ].join('\n')
    ));
  }));

  testUsingContext('ResidentRunner printHelpDetails cold runner', () => testbed.run(() {
    fakeVmServiceHost = null;
    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.printHelp(details: true);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // does not supports service protocol
    expect(residentRunner.supportsServiceProtocol, false);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, false);
    // does support SkSL
    expect(residentRunner.supportsWriteSkSL, false);
    // commands
    expect(testLogger.statusText, equals(
        <dynamic>[
          'Flutter run key commands.',
          commandHelp.s,
          commandHelp.h,
          commandHelp.c,
          commandHelp.q,
          ''
        ].join('\n')
    ));
  }));

  testUsingContext('ResidentRunner handles writeSkSL returning no data', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: kGetSkSLsMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
        },
        jsonResponse: <String, Object>{
          'SkSLs': <String, Object>{}
        }
      ),
    ]);
    await residentRunner.writeSkSL();

    expect(testLogger.statusText, contains('No data was received'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can write SkSL data to a unique file with engine revision, platform, and device name', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: kGetSkSLsMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
        },
        jsonResponse: <String, Object>{
          'SkSLs': <String, Object>{
            'A': 'B',
          }
        }
      )
    ]);
    await residentRunner.writeSkSL();

    expect(testLogger.statusText, contains('flutter_01.sksl.json'));
    expect(globals.fs.file('flutter_01.sksl.json'), exists);
    expect(json.decode(globals.fs.file('flutter_01.sksl.json').readAsStringSync()), <String, Object>{
      'platform': 'android',
      'name': 'FakeDevice',
      'engineRevision': '42.2', // From FakeFlutterVersion
      'data': <String, Object>{'A': 'B'}
    });
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystemUtils: () => FileSystemUtils(
      fileSystem: globals.fs,
      platform: globals.platform,
    )
  }));

  testUsingContext('ResidentRunner ignores DevToolsLauncher when attaching with enableDevTools: false', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    final Future<int> result = residentRunner.attach(enableDevTools: false);
    expect(await result, 0);

    // Verify DevTools was served.
    verifyNever(mockDevtoolsLauncher.serve());
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner ignores DevtoolsLauncher when attaching with enableDevTools: false - cold mode', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.runCold(
      coldRunner: anyNamed('coldRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });

    final Future<int> result = residentRunner.attach(enableDevTools: false);
    expect(await result, 0);

    // Verify DevTools was served.
    verifyNever(mockDevtoolsLauncher.serve());
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('ResidentRunner can take screenshot on debug device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'false',
        },
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'true',
        },
      )
    ]);
    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.statusText, contains('1kB'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can take screenshot on release device', () => testbed.run(() async {
    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.statusText, contains('1kB'));
  }));

  testUsingContext('ResidentRunner clears the screen when it should', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    const String message = 'This should be cleared';
    expect(testLogger.statusText, equals(''));
    testLogger.printStatus(message);
    expect(testLogger.statusText, equals(message + '\n'));  // printStatus makes a newline
    residentRunner.clearScreen();
    expect(testLogger.statusText, equals(''));
  }));

  testUsingContext('ResidentRunner bails taking screenshot on debug device if debugAllowBanner throws RpcError', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'false',
        },
        // Failed response,
        errorCode: RPCErrorCodes.kInternalError,
      )
    ]);
    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.errorText, contains('Error'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner bails taking screenshot on debug device if debugAllowBanner during second request', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'false',
        },
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'true',
        },
        // Failed response,
        errorCode: RPCErrorCodes.kInternalError,
      )
    ]);
    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.errorText, contains('Error'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner bails taking screenshot on debug device if takeScreenshot throws', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'false',
        },
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'true',
        },
      ),
    ]);
    // Ensure that takeScreenshot will throw an exception.
    mockDevice.failScreenshot = true;

    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.errorText, contains('Error'));
  }));

  testUsingContext("ResidentRunner can't take screenshot on device without support", () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    mockDevice.supportsScreenshot = false;

    expect(() => residentRunner.screenshot(mockFlutterDevice),
        throwsAssertionError);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner does not toggle banner in non-debug mode', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.statusText, contains('1kB'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('FlutterDevice will not exit a paused isolate', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        method: '_flutter.listViews',
        jsonResponse: <String, Object>{
          'views': <Object>[
            fakeFlutterView.toJson(),
          ],
        },
      ),
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakePausedIsolate.toJson(),
      ),
    ]);
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;

    await flutterDevice.exitApps();

    expect(mockDevice.appStopped, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('FlutterDevice can exit from a release mode isolate with no VmService', () => testbed.run(() async {
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
    );

    await flutterDevice.exitApps();

    expect(mockDevice.appStopped, true);
  }));

  testUsingContext('FlutterDevice will call stopApp if the exit request times out', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        method: '_flutter.listViews',
        jsonResponse: <String, Object>{
          'views': <Object>[
            fakeFlutterView.toJson(),
          ],
        },
      ),
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.exit',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        // Intentionally do not close isolate.
        close: false,
      )
    ]);
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;

    await flutterDevice.exitApps(
      timeoutDelay: Duration.zero,
    );

    expect(mockDevice.appStopped, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('FlutterDevice will exit an un-paused isolate', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        method: kListViewsMethod,
        jsonResponse: <String, Object>{
          'views': <Object>[
            fakeFlutterView.toJson(),
          ],
        },
      ),
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.exit',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        close: true,
      )
    ]);
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;

    final Future<void> exitFuture = flutterDevice.exitApps();

    await expectLater(exitFuture, completes);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner debugDumpApp calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugDumpApp(), true);
    verify(mockFlutterDevice.debugDumpApp()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpApp does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugDumpApp(), false);
    verifyNever(mockFlutterDevice.debugDumpApp());
  }));

  testUsingContext('ResidentRunner debugDumpRenderTree calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugDumpRenderTree(), true);
    verify(mockFlutterDevice.debugDumpRenderTree()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpRenderTree does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugDumpRenderTree(), false);
    verifyNever(mockFlutterDevice.debugDumpRenderTree());
  }));

  testUsingContext('ResidentRunner debugDumpLayerTree calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugDumpLayerTree(), true);
    verify(mockFlutterDevice.debugDumpLayerTree()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpLayerTree does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugDumpLayerTree(), false);
    verifyNever(mockFlutterDevice.debugDumpLayerTree());
  }));

  testUsingContext('ResidentRunner debugDumpSemanticsTreeInTraversalOrder calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugDumpSemanticsTreeInTraversalOrder(), true);
    verify(mockFlutterDevice.debugDumpSemanticsTreeInTraversalOrder()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpSemanticsTreeInTraversalOrder does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugDumpSemanticsTreeInTraversalOrder(), false);
    verifyNever(mockFlutterDevice.debugDumpSemanticsTreeInTraversalOrder());
  }));

  testUsingContext('ResidentRunner debugDumpSemanticsTreeInInverseHitTestOrder calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugDumpSemanticsTreeInInverseHitTestOrder(), true);
    verify(mockFlutterDevice.debugDumpSemanticsTreeInInverseHitTestOrder()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpSemanticsTreeInInverseHitTestOrder does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugDumpSemanticsTreeInInverseHitTestOrder(), false);
    verifyNever(mockFlutterDevice.debugDumpSemanticsTreeInInverseHitTestOrder());
  }));

  testUsingContext('ResidentRunner debugToggleDebugPaintSizeEnabled calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugToggleDebugPaintSizeEnabled(), true);
    verify(mockFlutterDevice.toggleDebugPaintSizeEnabled()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleDebugPaintSizeEnabled does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugToggleDebugPaintSizeEnabled(), false);
    verifyNever(mockFlutterDevice.toggleDebugPaintSizeEnabled());
  }));

  testUsingContext('ResidentRunner debugToggleBrightness calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugToggleBrightness(), true);
    verify(mockFlutterDevice.toggleBrightness()).called(2);
  }));

  testUsingContext('ResidentRunner debugToggleBrightness does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugToggleBrightness(), false);
    verifyNever(mockFlutterDevice.toggleBrightness());
  }));

  testUsingContext('FlutterDevice.toggleBrightness invokes correct VM service request', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      const FakeVmServiceRequest(
        method: 'ext.flutter.brightnessOverride',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: <String, Object>{
          'value': 'Brightness.dark'
        },
      ),
    ]);
    final FlutterDevice flutterDevice = FlutterDevice(
      mockDevice,
      buildInfo: BuildInfo.debug,
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;

    expect(await flutterDevice.toggleBrightness(), Brightness.dark);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner debugToggleInvertOversizedImages calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugToggleInvertOversizedImages(), true);
    verify(mockFlutterDevice.toggleInvertOversizedImages()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleInvertOversizedImages does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugToggleInvertOversizedImages(), false);
    verifyNever(mockFlutterDevice.toggleInvertOversizedImages());
  }));

  testUsingContext('ResidentRunner debugToggleInvertOversizedImages does not call flutter device if in profile mode', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugToggleInvertOversizedImages(), false);
    verifyNever(mockFlutterDevice.toggleInvertOversizedImages());
  }));

  testUsingContext('FlutterDevice.toggleInvertOversizedImages invokes correct VM service request', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      const FakeVmServiceRequest(
        method: 'ext.flutter.invertOversizedImages',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: <String, Object>{
          'value': 'false'
        },
      ),
    ]);
    final FlutterDevice flutterDevice = FlutterDevice(
      mockDevice,
      buildInfo: BuildInfo.debug,
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;

    await flutterDevice.toggleInvertOversizedImages();
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner debugToggleDebugCheckElevationsEnabled calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugToggleDebugCheckElevationsEnabled(), true);
    verify(mockFlutterDevice.toggleDebugCheckElevationsEnabled()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleDebugCheckElevationsEnabled does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugToggleDebugCheckElevationsEnabled(), false);
    verifyNever(mockFlutterDevice.toggleDebugCheckElevationsEnabled());
  }));

  testUsingContext('ResidentRunner debugTogglePerformanceOverlayOverride calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugTogglePerformanceOverlayOverride(), true);
    verify(mockFlutterDevice.debugTogglePerformanceOverlayOverride()).called(1);
  }));

  testUsingContext('ResidentRunner debugTogglePerformanceOverlayOverride does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugTogglePerformanceOverlayOverride(), false);
    verifyNever(mockFlutterDevice.debugTogglePerformanceOverlayOverride());
  }));


  testUsingContext('ResidentRunner debugToggleWidgetInspector calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(await residentRunner.debugToggleWidgetInspector(), true);
    verify(mockFlutterDevice.toggleWidgetInspector()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleWidgetInspector does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugToggleWidgetInspector(), false);
    verifyNever(mockFlutterDevice.toggleWidgetInspector());
  }));

  testUsingContext('ResidentRunner debugToggleProfileWidgetBuilds calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleProfileWidgetBuilds();

    verify(mockFlutterDevice.toggleProfileWidgetBuilds()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleProfileWidgetBuilds does not call flutter device if service protocol is unsupported', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(await residentRunner.debugToggleProfileWidgetBuilds(), false);
    verifyNever(mockFlutterDevice.toggleProfileWidgetBuilds());
  }));

  testUsingContext('HotRunner writes vm service file when providing debugging option', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
    expect(await globals.fs.file('foo').readAsString(), testUri.toString());
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('HotRunner copies compiled app.dill to cache during startup', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join('build', 'cache.dill')).readAsString(), 'ABC');
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with dart defines', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          dartDefines: <String>['a', 'b'],
        )
      ),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join(
      'build', '187ef4436122d1cc2f40dc2b92f0eba0.cache.dill')).readAsString(), 'ABC');
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with null safety', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          extraFrontEndOptions: <String>['--enable-experiment=non-nullable>']
        )
      ),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join(
      'build', '3416d3007730479552122f01c01e326d.cache.dill')).readAsString(), 'ABC');
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('HotRunner does not copy app.dill if a dillOutputPath is given', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      dillOutputPath: 'test',
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(globals.fs.file(globals.fs.path.join('build', 'cache.dill')), isNot(exists));
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with --track-widget-creation', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        trackWidgetCreation: true,
      )),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join('build', 'cache.dill.track.dill')).readAsString(), 'ABC');
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('HotRunner calls device dispose', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });

    await residentRunner.run();
    expect(mockDevice.disposed, true);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('HotRunner handles failure to write vmservice file', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      setAssetBundlePath,
    ]);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(testLogger.errorText, contains('Failed to write vmservice-out-file at foo'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => ThrowingForwardingFileSystem(MemoryFileSystem.test()),
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });


  testUsingContext('ColdRunner writes vm service file when providing debugging option', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
    ]);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    when(mockFlutterDevice.runCold(
      coldRunner: anyNamed('coldRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file('foo').readAsString(), testUri.toString());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }), overrides: <Type, Generator>{
    DevtoolsLauncher: () => mockDevtoolsLauncher,
  });

  testUsingContext('FlutterDevice uses dartdevc configuration when targeting web', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice mockDevice = FakeDevice(targetPlatform: TargetPlatform.web_javascript);
    final DefaultResidentCompiler residentCompiler = (await FlutterDevice.create(
      mockDevice,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        nullSafetyMode: NullSafetyMode.unsound,
      ),
      target: null,
      platform: FakePlatform(operatingSystem: 'linux'),
    )).generator as DefaultResidentCompiler;

    expect(residentCompiler.initializeFromDill,
      globals.fs.path.join(getBuildDirectory(), 'fbbe6a61fb7a1de317d381f8df4814e5.cache.dill'));
    expect(residentCompiler.librariesSpec,
      globals.fs.file(globals.artifacts.getArtifactPath(Artifact.flutterWebLibrariesJson))
        .uri.toString());
    expect(residentCompiler.targetModel, TargetModel.dartdevc);
    expect(residentCompiler.sdkRoot,
      globals.artifacts.getArtifactPath(Artifact.flutterWebSdk, mode: BuildMode.debug) + '/');
    expect(residentCompiler.platformDill, 'file:///Artifact.webPlatformKernelDill.debug');
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('FlutterDevice uses dartdevc configuration when targeting web with null-safety autodetected', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice mockDevice = FakeDevice(targetPlatform: TargetPlatform.web_javascript);

    final DefaultResidentCompiler residentCompiler = (await FlutterDevice.create(
      mockDevice,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>['--enable-experiment=non-nullable'],
      ),
      target: null,
      platform: FakePlatform(operatingSystem: 'linux'),
    )).generator as DefaultResidentCompiler;

    expect(residentCompiler.initializeFromDill,
      globals.fs.path.join(getBuildDirectory(), '825b8f791aa86c5057fff6f064542c54.cache.dill'));
    expect(residentCompiler.librariesSpec,
      globals.fs.file(globals.artifacts.getArtifactPath(Artifact.flutterWebLibrariesJson))
        .uri.toString());
    expect(residentCompiler.targetModel, TargetModel.dartdevc);
    expect(residentCompiler.sdkRoot,
      globals.artifacts.getArtifactPath(Artifact.flutterWebSdk, mode: BuildMode.debug) + '/');
    expect(residentCompiler.platformDill, 'file:///Artifact.webPlatformSoundKernelDill.debug');
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  }, skip: true); // TODO(jonahwilliams): null safe autodetection does not work on the web.

  testUsingContext('FlutterDevice passes flutter-widget-cache flag when feature is enabled', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice mockDevice = FakeDevice(targetPlatform: TargetPlatform.android_arm);

    final DefaultResidentCompiler residentCompiler = (await FlutterDevice.create(
      mockDevice,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>[],
      ),
      target: null, platform: null,
    )).generator as DefaultResidentCompiler;

    expect(residentCompiler.extraFrontEndOptions,
      contains('--flutter-widget-cache'));
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isSingleWidgetReloadEnabled: true)
  });

   testUsingContext('FlutterDevice passes alternative-invalidation-strategy flag when feature is enabled', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice mockDevice = FakeDevice(targetPlatform: TargetPlatform.android_arm);


    final DefaultResidentCompiler residentCompiler = (await FlutterDevice.create(
      mockDevice,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>[],
      ),
      target: null, platform: null,
    )).generator as DefaultResidentCompiler;

    expect(residentCompiler.extraFrontEndOptions,
      contains('--enable-experiment=alternative-invalidation-strategy'));
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isExperimentalInvalidationStrategyEnabled: true)
  });

  testUsingContext('connect sets up log reader', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final MockDevice mockDevice = MockDevice();
    final MockDartDevelopmentService mockDds = MockDartDevelopmentService();
    final MockDeviceLogReader mockLogReader = MockDeviceLogReader();
    final Completer<void> noopCompleter = Completer<void>();
    when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(mockLogReader);
    when(mockDevice.dds).thenReturn(mockDds);
    when(mockDds.startDartDevelopmentService(any, any, any, any)).thenReturn(null);
    when(mockDds.uri).thenReturn(Uri.parse('http://localhost:8181'));
    when(mockDds.done).thenAnswer((_) => noopCompleter.future);

    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      observatoryUris: Stream<Uri>.value(testUri),
    );

    await flutterDevice.connect(allowExistingDdsInstance: true);
    verify(mockLogReader.connectedVMService = mockVMService);
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      GetSkSLMethod getSkSLMethod,
      PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
      io.CompressionOptions compression,
      Device device,
    }) async => mockVMService,
  }));

  testUsingContext('FlutterDevice handles existing DDS instance', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final MockDevice mockDevice = MockDevice();
    final MockDartDevelopmentService mockDds = MockDartDevelopmentService();
    final MockDeviceLogReader mockLogReader = MockDeviceLogReader();
    final Completer<void> noopCompleter = Completer<void>();
    when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(mockLogReader);
    when(mockDevice.dds).thenReturn(mockDds);
    when(mockDds.startDartDevelopmentService(any, any, any, any)).thenThrow(FakeDartDevelopmentServiceException());
    when(mockDds.uri).thenReturn(Uri.parse('http://localhost:1234'));
    when(mockDds.done).thenAnswer((_) => noopCompleter.future);

    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      observatoryUris: Stream<Uri>.value(testUri),
    );
    await flutterDevice.connect(allowExistingDdsInstance: true);
    verify(mockLogReader.connectedVMService = mockVMService);
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      GetSkSLMethod getSkSLMethod,
      PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
      io.CompressionOptions compression,
      Device device,
    }) async => mockVMService,
  }));

  testUsingContext('Handle existing VM service clients DDS error', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice mockDevice = FakeDevice()
      ..dds = DartDevelopmentService(logger: testLogger);
    ddsLauncherCallback = (Uri uri, {bool enableAuthCodes, bool ipv6, Uri serviceUri}) {
      throw FakeDartDevelopmentServiceException(message:
        'Existing VM service clients prevent DDS from taking control.',
      );
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      observatoryUris: Stream<Uri>.value(testUri),
    );
    bool caught = false;
    final Completer<void>done = Completer<void>();
    runZonedGuarded(() {
      flutterDevice.connect(allowExistingDdsInstance: true).then((_) => done.complete());
    }, (Object e, StackTrace st) {
      expect(e is ToolExit, true);
      expect((e as ToolExit).message,
        contains('Existing VM service clients prevent DDS from taking control.',
      ));
      done.complete();
      caught = true;
    });
    await done.future;
    if (!caught) {
      fail('Expected ToolExit to be thrown.');
    }
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      GetSkSLMethod getSkSLMethod,
      PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
      io.CompressionOptions compression,
      Device device,
    }) async => mockVMService,
  }));

  testUsingContext('Failed DDS start outputs error message', () => testbed.run(() async {
    // See https://github.com/flutter/flutter/issues/72385 for context.
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice mockDevice = FakeDevice()
      ..dds = DartDevelopmentService(logger: testLogger);
    ddsLauncherCallback = (Uri uri, {bool enableAuthCodes, bool ipv6, Uri serviceUri}) {
      throw FakeDartDevelopmentServiceException(message: 'No URI');
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      observatoryUris: Stream<Uri>.value(testUri),
    );
    bool caught = false;
    final Completer<void>done = Completer<void>();
    runZonedGuarded(() {
      flutterDevice.connect(allowExistingDdsInstance: true).then((_) => done.complete());
    }, (Object e, StackTrace st) {
      expect(e is StateError, true);
      expect((e as StateError).message, contains('No URI'));
      expect(testLogger.errorText, contains(
        'DDS has failed to start and there is not an existing DDS instance',
      ));
      done.complete();
      caught = true;
    });
    await done.future;
    if (!caught) {
      fail('Expected a StateError to be thrown.');
    }
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      GetSkSLMethod getSkSLMethod,
      PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
      io.CompressionOptions compression,
      Device device,
    }) async => mockVMService,
  }));

  testUsingContext('nextPlatform moves through expected platforms', () {
    expect(nextPlatform('android', TestFeatureFlags()), 'iOS');
    expect(nextPlatform('iOS', TestFeatureFlags()), 'fuchsia');
    expect(nextPlatform('fuchsia', TestFeatureFlags()), 'android');
    expect(nextPlatform('fuchsia', TestFeatureFlags(isMacOSEnabled: true)), 'macOS');
    expect(() => nextPlatform('unknown', TestFeatureFlags()), throwsAssertionError);
  });
}

class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockDartDevelopmentService extends Mock implements DartDevelopmentService {}
class MockVMService extends Mock implements vm_service.VmService {}
class MockDevFS extends Mock implements DevFS {}
class MockDeviceLogReader extends Mock implements DeviceLogReader {}
class MockDevtoolsLauncher extends Mock implements DevtoolsLauncher {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}
class MockDevice extends Mock implements Device {}

class FakeDartDevelopmentServiceException implements dds.DartDevelopmentServiceException {
  FakeDartDevelopmentServiceException({this.message = defaultMessage});

  @override
  final int errorCode = dds.DartDevelopmentServiceException.existingDdsInstanceError;

  @override
  final String message;
  static const String defaultMessage = 'A DDS instance is already connected at http://localhost:8181';
}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice(Device device, { Stream<Uri> observatoryUris })
    : super(device, buildInfo: BuildInfo.debug) {
    _observatoryUris = observatoryUris;
  }

  @override
  Stream<Uri> get observatoryUris => _observatoryUris;
  Stream<Uri> _observatoryUris;
}

class ThrowingForwardingFileSystem extends ForwardingFileSystem {
  ThrowingForwardingFileSystem(FileSystem delegate) : super(delegate);

  @override
  File file(dynamic path) {
    if (path == 'foo') {
      throw const FileSystemException();
    }
    return delegate.file(path);
  }
}

class FakeFlutterDevice extends FlutterDevice {
  FakeFlutterDevice(
    Device device,
    BuildInfo buildInfo,
    ResidentCompiler residentCompiler,
    this.fakeDevFS,
  ) : super(device, buildInfo: buildInfo, generator: residentCompiler);

  @override
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    bool disableDds = false,
    bool disableServiceAuthCodes = false,
    bool ipv6 = false,
    CompileExpression compileExpression,
    GetSkSLMethod getSkSLMethod,
    int hostVmServicePort,
    int ddsPort,
    PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
    bool allowExistingDdsInstance = false,
  }) async { }


  final DevFS fakeDevFS;

  @override
  DevFS get devFS => fakeDevFS;

  @override
  set devFS(DevFS value) {}
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  @override
  Future<CompilerOutput> recompile(
    Uri mainUri,
    List<Uri> invalidatedFiles, {
    @required String outputPath,
    @required PackageConfig packageConfig,
    bool suppressErrors = false,
  }) async {
    return const CompilerOutput('foo.dill', 0, <Uri>[]);
  }

  @override
  void accept() { }

  @override
  void reset() { }
}

class FakeProjectFileInvalidator extends Fake implements ProjectFileInvalidator {
  @override
  Future<InvalidationResult> findInvalidated({
    @required DateTime lastCompiled,
    @required List<Uri> urisToMonitor,
    @required String packagesPath,
    @required PackageConfig packageConfig,
    bool asyncScanning = false,
  }) async {
    return InvalidationResult(
      packageConfig: packageConfig ?? PackageConfig.empty,
      uris: <Uri>[Uri.parse('file:///hello_world/main.dart'),
    ]);
  }
}

class FakeDevice extends Fake implements Device {
  FakeDevice({
    String sdkNameAndVersion = 'Android',
    TargetPlatform targetPlatform = TargetPlatform.android_arm,
    bool isLocalEmulator = false,
    this.supportsHotRestart = true,
    this.supportsScreenshot = true,
    this.supportsFlutterExit = true,
  }) : _isLocalEmulator = isLocalEmulator,
       _targetPlatform = targetPlatform,
       _sdkNameAndVersion = sdkNameAndVersion;

  final bool _isLocalEmulator;
  final TargetPlatform _targetPlatform;
  final String _sdkNameAndVersion;

  bool disposed = false;
  bool appStopped = false;
  bool failScreenshot = false;

  @override
  bool supportsHotRestart;

  @override
  bool supportsScreenshot;

  @override
  bool supportsFlutterExit;

  @override
  PlatformType get platformType => _targetPlatform == TargetPlatform.web_javascript
    ? PlatformType.web
    : PlatformType.android;

  @override
  Future<String> get sdkNameAndVersion async => _sdkNameAndVersion;

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  Future<bool> get isLocalEmulator async => _isLocalEmulator;

  @override
  String get name => 'FakeDevice';

  @override
  DartDevelopmentService dds;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<bool> stopApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    appStopped = true;
    return true;
  }

  @override
  Future<void> takeScreenshot(File outputFile) async {
    if (failScreenshot) {
      throw Exception();
    }
    outputFile.writeAsBytesSync(List<int>.generate(1024, (int i) => i));
  }

  @override
  FutureOr<DeviceLogReader> getLogReader({
    covariant ApplicationPackage app,
    bool includePastLogs = false,
  }) => NoOpDeviceLogReader(name);

  @override
  DevicePortForwarder portForwarder = const NoOpDevicePortForwarder();
}
