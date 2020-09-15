// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/widget_cache.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
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
import 'package:flutter_tools/src/project.dart';
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
        script: vm_service.ScriptRef(id: 'test-script', uri: 'lib/foo.dart'),
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

void main() {
  final Uri testUri = Uri.parse('foo://bar');
  Testbed testbed;
  MockFlutterDevice mockFlutterDevice;
  MockVMService mockVMService;
  MockDevFS mockDevFS;
  ResidentRunner residentRunner;
  MockDevice mockDevice;
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
      );
    });
    mockFlutterDevice = MockFlutterDevice();
    mockDevice = MockDevice();
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
        invalidatedSourcesCount: 0,
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
    )).thenAnswer((Invocation invocation) async { });
    when(mockFlutterDevice.setupDevFS(any, any, packagesFilePath: anyNamed('packagesFilePath')))
      .thenAnswer((Invocation invocation) async {
        return testUri;
      });
    when(mockFlutterDevice.vmService).thenAnswer((Invocation invocation) {
      return fakeVmServiceHost?.vmService;
    });
    when(mockFlutterDevice.reloadSources(any, pause: anyNamed('pause'))).thenAnswer((Invocation invocation) async {
      return <Future<vm_service.ReloadReport>>[
        Future<vm_service.ReloadReport>.value(vm_service.ReloadReport.parse(<String, dynamic>{
          'type': 'ReloadReport',
          'success': true,
          'details': <String, dynamic>{
            'loadedLibraryCount': 1,
            'finalLibraryCount': 1,
            'receivedLibraryCount': 1,
            'receivedClassesCount': 1,
            'receivedProceduresCount': 1,
          },
        })),
      ];
    });
  });

  testUsingContext('ResidentRunner can attach to device successfully', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
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
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner suppresses errors for the initial compilation', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
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

    expect(await residentRunner.run(), 0);
    verify(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
      suppressErrors: true,
    )).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

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
    ]);
    final MockResidentCompiler residentCompiler = MockResidentCompiler();
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      applicationBinary: globals.fs.file('app.apk'),
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
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

    expect(await residentRunner.run(), 0);
    verify(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packageConfig: anyNamed('packageConfig'),
      suppressErrors: false,
    )).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can attach to device successfully with --fast-start', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
          'mainScript': 'lib/main.dart.dill',
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
    when(mockDevice.supportsHotRestart).thenReturn(true);
    when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation invocation) async {
      return 'Example';
    });
    when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.android_arm;
    });
    when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) async {
      return false;
    });
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
    );
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
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can handle an RPC exception from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
    ]);
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
    verify(globals.flutterUsage.sendEvent('hot', 'exception', parameters: <String, String>{
      cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
      cdKey(CustomDimensions.hotEventSdkName): 'Example',
      cdKey(CustomDimensions.hotEventEmulator): 'false',
      cdKey(CustomDimensions.hotEventFullRestart): 'false',
      cdKey(CustomDimensions.nullSafety): 'false',
    })).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  testUsingContext('ResidentRunner reports hot reload event with null safety analytics', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(const BuildInfo(
        BuildMode.debug, '', treeShakeIcons: false, extraFrontEndOptions: <String>[
        '--enable-experiment=non-nullable',
        ],
      )),
    );
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
    verify(globals.flutterUsage.sendEvent('hot', 'exception', parameters: <String, String>{
      cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
      cdKey(CustomDimensions.hotEventSdkName): 'Example',
      cdKey(CustomDimensions.hotEventEmulator): 'false',
      cdKey(CustomDimensions.hotEventFullRestart): 'false',
      cdKey(CustomDimensions.nullSafety): 'true',
    })).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  testUsingContext('ResidentRunner reports error with missing entrypoint file', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
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
      return UpdateFSReport(success: true);
    });

    final OperationResult result = await residentRunner.restart(fullRestart: false);

    expect(globals.fs.file(globals.fs.path.join('lib', 'main.dart')), isNot(exists));
    expect(testLogger.errorText, contains('The entrypoint file (i.e. the file with main())'));
    expect(result.fatal, false);
    expect(result.code, 0);
  }));


  testUsingContext('ResidentRunner can send target platform to analytics from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
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
    expect(verify(globals.flutterUsage.sendEvent('hot', 'reload',
                  parameters: captureAnyNamed('parameters'))).captured[0],
      containsPair(cdKey(CustomDimensions.hotEventTargetPlatform),
                   getNameForTargetPlatform(TargetPlatform.android_arm)),
    );
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  testUsingContext('ResidentRunner can perform fast reassemble', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'evaluate',
        args: <String, String>{
          'isolateId': '1',
          'targetId': '1',
          'expression': '((){debugFastReassembleMethod=(Object _fastReassembleParam) => _fastReassembleParam is FakeWidget})()',
        }
      ),
      listViews,
      const FakeVmServiceRequest(
        method: '_flutter.setAssetBundlePath',
        args: <String, Object>{
          'viewId': 'a',
          'assetDirectory': 'build/flutter_assets',
          'isolateId': '1',
        }
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'reloadSources',
        args: <String, Object>{
          'isolateId': '1',
          'pause': false,
          'rootLibUri': 'lib/main.dart.incremental.dill',
        },
        jsonResponse: <String, Object>{
          'type': 'ReloadReport',
          'success': true,
          'details': <String, Object>{
            'loadedLibraryCount': 1,
          },
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
        method: 'ext.flutter.fastReassemble',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
      ),
    ]);
    final FakeFlutterDevice flutterDevice =  FakeFlutterDevice(
      mockDevice,
      BuildInfo.debug,
      FakeWidgetCache(),
      FakeResidentCompiler(),
      mockDevFS,
    )..vmService = fakeVmServiceHost.vmService;
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
    );
    when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation invocation) async {
      return 'Example';
    });
    when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.android_arm;
    });
    when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) async {
      return false;
    });
    when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(NoOpDeviceLogReader('test'));
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
      return UpdateFSReport(success: true);
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
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    Platform: () => FakePlatform(operatingSystem: 'linux'),
    ProjectFileInvalidator: () => FakeProjectFileInvalidator(),
  }));

  testUsingContext('ResidentRunner bails out of fast reassemble if evaluation fails', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'evaluate',
        args: <String, String>{
          'isolateId': '1',
          'targetId': '1',
          'expression': '((){debugFastReassembleMethod=(Object _fastReassembleParam) => _fastReassembleParam is FakeWidget})()',
        },
        errorCode: 500,
      ),
      listViews,
      const FakeVmServiceRequest(
        method: '_flutter.setAssetBundlePath',
        args: <String, Object>{
          'viewId': 'a',
          'assetDirectory': 'build/flutter_assets',
          'isolateId': '1',
        }
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'reloadSources',
        args: <String, Object>{
          'isolateId': '1',
          'pause': false,
          'rootLibUri': 'lib/main.dart.incremental.dill',
        },
        jsonResponse: <String, Object>{
          'type': 'ReloadReport',
          'success': true,
          'details': <String, Object>{
            'loadedLibraryCount': 1,
          },
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
    final FakeFlutterDevice flutterDevice =  FakeFlutterDevice(
      mockDevice,
      BuildInfo.debug,
      FakeWidgetCache(),
      FakeResidentCompiler(),
      mockDevFS,
    )..vmService = fakeVmServiceHost.vmService;
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
    );
    when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation invocation) async {
      return 'Example';
    });
    when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.android_arm;
    });
    when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) async {
      return false;
    });
    when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(NoOpDeviceLogReader('test'));
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
      return UpdateFSReport(success: true);
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
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    Platform: () => FakePlatform(operatingSystem: 'linux'),
    ProjectFileInvalidator: () => FakeProjectFileInvalidator(),
  }));


  testUsingContext('ResidentRunner can send target platform to analytics from full restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
          'mainScript': 'lib/main.dart.dill',
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
    expect(verify(globals.flutterUsage.sendEvent('hot', 'restart',
                  parameters: captureAnyNamed('parameters'))).captured[0],
      containsPair(cdKey(CustomDimensions.hotEventTargetPlatform),
                   getNameForTargetPlatform(TargetPlatform.android_arm)),
    );
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  testUsingContext('ResidentRunner can remove breakpoints from paused isolate during hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
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
          'mainScript': 'lib/main.dart.dill',
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

    expect(result.isOk, true);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner will alternative the name of the dill file uploaded for a hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
          'mainScript': 'lib/main.dart.dill',
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
          'mainScript': 'lib/main.dart.swap.dill',
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
          'mainScript': 'lib/main.dart.dill',
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

    await residentRunner.restart(fullRestart: true);
    await residentRunner.restart(fullRestart: true);
    await residentRunner.restart(fullRestart: true);

    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner Can handle an RPC exception from hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
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
    verify(globals.flutterUsage.sendEvent('hot', 'exception', parameters: <String, String>{
      cdKey(CustomDimensions.hotEventTargetPlatform):
        getNameForTargetPlatform(TargetPlatform.android_arm),
      cdKey(CustomDimensions.hotEventSdkName): 'Example',
      cdKey(CustomDimensions.hotEventEmulator): 'false',
      cdKey(CustomDimensions.hotEventFullRestart): 'true',
      cdKey(CustomDimensions.nullSafety): 'false',
    })).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

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
    arbFile.writeAsStringSync('''{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    globals.fs.file('l10n.yaml').createSync();
    globals.fs.file('pubspec.yaml').writeAsStringSync('flutter:\n  generate: true\n');

    await residentRunner.runSourceGenerators();

    expect(testLogger.errorText, isEmpty);
    expect(testLogger.statusText, contains('use the --untranslated-messages-file'));
  }));

  testUsingContext('ResidentRunner can run source generation - generation fails', () => testbed.run(() async {
    // Intentionally define arb file with wrong name. generate_localizations defaults
    // to app_en.arb.
    final File arbFile = globals.fs.file(globals.fs.path.join('lib', 'l10n', 'foo.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''{
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
    when(mockDevice.supportsHotRestart).thenReturn(true);
    when(mockDevice.supportsScreenshot).thenReturn(true);

    residentRunner.printHelp(details: true);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // supports service protocol
    expect(residentRunner.supportsServiceProtocol, true);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, true);
    // does not support CanvasKit
    expect(residentRunner.supportsCanvasKit, false);
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
          'An Observatory debugger and profiler on null is available at: null',
          ''
        ].join('\n')
    ));
  }));

  testUsingContext('ResidentRunner printHelpDetails cold runner', () => testbed.run(() {
    when(mockDevice.supportsHotRestart).thenReturn(true);
    when(mockDevice.supportsScreenshot).thenReturn(true);
    fakeVmServiceHost = null;
    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
    );
    residentRunner.printHelp(details: true);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // does not supports service protocol
    expect(residentRunner.supportsServiceProtocol, false);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, false);
    // does not support CanvasKit
    expect(residentRunner.supportsCanvasKit, false);
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

  testUsingContext('ResidentRunner does support CanvasKit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    expect(residentRunner.toggleCanvaskit,
      throwsA(isA<Exception>()));
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

    expect(testLogger.statusText, contains('No data was receieved'));
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
    when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.android_arm;
    });
    when(mockDevice.name).thenReturn('test device');
    await residentRunner.writeSkSL();

    expect(testLogger.statusText, contains('flutter_01.sksl.json'));
    expect(globals.fs.file('flutter_01.sksl.json'), exists);
    expect(json.decode(globals.fs.file('flutter_01.sksl.json').readAsStringSync()), <String, Object>{
      'platform': 'android',
      'name': 'test device',
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

  testUsingContext('ResidentRunner invokes DevtoolsLauncher when launching and shutting down Devtools', () => testbed.run(() async {
    when(mockFlutterDevice.vmService).thenReturn(fakeVmServiceHost.vmService);
    setHttpAddress(testUri, fakeVmServiceHost.vmService);
    await residentRunner.launchDevTools();
    verify(mockDevtoolsLauncher.launch(testUri)).called(1);

    await residentRunner.shutdownDevtools();
    verify(mockDevtoolsLauncher.close()).called(1);
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
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockDevice.takeScreenshot(any))
      .thenAnswer((Invocation invocation) async {
        final File file = invocation.positionalArguments.first as File;
        file.writeAsBytesSync(List<int>.generate(1024, (int i) => i));
      });

    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.statusText, contains('1kB'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can take screenshot on release device', () => testbed.run(() async {
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockDevice.takeScreenshot(any))
      .thenAnswer((Invocation invocation) async {
        final File file = invocation.positionalArguments.first as File;
        file.writeAsBytesSync(List<int>.generate(1024, (int i) => i));
      });

    residentRunner = ColdRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
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
    when(mockDevice.supportsScreenshot).thenReturn(true);
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
    when(mockDevice.supportsScreenshot).thenReturn(true);
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
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockDevice.takeScreenshot(any)).thenThrow(Exception());

    await residentRunner.screenshot(mockFlutterDevice);

    expect(testLogger.errorText, contains('Error'));
  }));

  testUsingContext("ResidentRunner can't take screenshot on device without support", () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    when(mockDevice.supportsScreenshot).thenReturn(false);

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
    );
    when(mockDevice.supportsScreenshot).thenReturn(true);
    when(mockDevice.takeScreenshot(any))
      .thenAnswer((Invocation invocation) async {
        final File file = invocation.positionalArguments.first as File;
        file.writeAsBytesSync(List<int>.generate(1024, (int i) => i));
      });

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
    when(mockDevice.supportsFlutterExit).thenReturn(true);

    await flutterDevice.exitApps();

    verify(mockDevice.stopApp(any, userIdentifier: anyNamed('userIdentifier'))).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('FlutterDevice can exit from a release mode isolate with no VmService', () => testbed.run(() async {
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
    );
    when(mockDevice.supportsFlutterExit).thenReturn(true);

    await flutterDevice.exitApps();

    verify(mockDevice.stopApp(any, userIdentifier: anyNamed('userIdentifier'))).called(1);
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
    when(mockDevice.supportsFlutterExit).thenReturn(true);

    await flutterDevice.exitApps(
      timeoutDelay: Duration.zero,
    );

    verify(mockDevice.stopApp(any, userIdentifier: anyNamed('userIdentifier'))).called(1);
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

    when(mockDevice.supportsFlutterExit).thenReturn(true);

    final Future<void> exitFuture = flutterDevice.exitApps();

    await expectLater(exitFuture, completes);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner debugDumpApp calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpApp();

    verify(mockFlutterDevice.debugDumpApp()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpRenderTree calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpRenderTree();

    verify(mockFlutterDevice.debugDumpRenderTree()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpLayerTree calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpLayerTree();

    verify(mockFlutterDevice.debugDumpLayerTree()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpSemanticsTreeInTraversalOrder calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpSemanticsTreeInTraversalOrder();

    verify(mockFlutterDevice.debugDumpSemanticsTreeInTraversalOrder()).called(1);
  }));

  testUsingContext('ResidentRunner debugDumpSemanticsTreeInInverseHitTestOrder calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpSemanticsTreeInInverseHitTestOrder();

    verify(mockFlutterDevice.debugDumpSemanticsTreeInInverseHitTestOrder()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleDebugPaintSizeEnabled calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleDebugPaintSizeEnabled();

    verify(mockFlutterDevice.toggleDebugPaintSizeEnabled()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleBrightness calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleBrightness();

    verify(mockFlutterDevice.toggleBrightness()).called(2);
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
    final FlutterDevice device = FlutterDevice(
      mockDevice,
      buildInfo: BuildInfo.debug,
    );
    device.vmService = fakeVmServiceHost.vmService;

    expect(await device.toggleBrightness(), Brightness.dark);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner debugToggleInvertOversizedImages calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleInvertOversizedImages();

    verify(mockFlutterDevice.toggleInvertOversizedImages()).called(1);
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
    final FlutterDevice device = FlutterDevice(
      mockDevice,
      buildInfo: BuildInfo.debug,
    );
    device.vmService = fakeVmServiceHost.vmService;

    await device.toggleInvertOversizedImages();
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner debugToggleDebugCheckElevationsEnabled calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleDebugCheckElevationsEnabled();

    verify(mockFlutterDevice.toggleDebugCheckElevationsEnabled()).called(1);
  }));

  testUsingContext('ResidentRunner debugTogglePerformanceOverlayOverride calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugTogglePerformanceOverlayOverride();

    verify(mockFlutterDevice.debugTogglePerformanceOverlayOverride()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleWidgetInspector calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleWidgetInspector();

    verify(mockFlutterDevice.toggleWidgetInspector()).called(1);
  }));

  testUsingContext('ResidentRunner debugToggleProfileWidgetBuilds calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleProfileWidgetBuilds();

    verify(mockFlutterDevice.toggleProfileWidgetBuilds()).called(1);
  }));

  testUsingContext('HotRunner writes vm service file when providing debugging option', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
    );
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(await globals.fs.file('foo').readAsString(), testUri.toString());
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    setWsAddress(testUri, fakeVmServiceHost.vmService);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(await globals.fs.file(globals.fs.path.join('build', 'cache.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with dart defines', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(await globals.fs.file(globals.fs.path.join(
      'build', '187ef4436122d1cc2f40dc2b92f0eba0.cache.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with null safety', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(await globals.fs.file(globals.fs.path.join(
      'build', '3416d3007730479552122f01c01e326d.cache.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner does not copy app.dill if a dillOutputPath is given', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(globals.fs.file(globals.fs.path.join('build', 'cache.dill')), isNot(exists));
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with --track-widget-creation', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(await globals.fs.file(globals.fs.path.join('build', 'cache.dill.track.dill')).readAsString(), 'ABC');
  }));


  testUsingContext('HotRunner unforwards device ports', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    final MockDevicePortForwarder mockPortForwarder = MockDevicePortForwarder();
    when(mockDevice.portForwarder).thenReturn(mockPortForwarder);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
    );
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });

    when(mockDevice.dispose()).thenAnswer((Invocation invocation) async {
      await mockDevice.portForwarder.dispose();
    });

    await residentRunner.run();

    verify(mockPortForwarder.dispose()).called(1);
  }));

  testUsingContext('HotRunner handles failure to write vmservice file', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        mockFlutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
    );
    when(mockFlutterDevice.runHot(
      hotRunner: anyNamed('hotRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(testLogger.errorText, contains('Failed to write vmservice-out-file at foo'));
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => ThrowingForwardingFileSystem(MemoryFileSystem()),
  }));


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
    );
    when(mockFlutterDevice.runCold(
      coldRunner: anyNamed('coldRunner'),
      route: anyNamed('route'),
    )).thenAnswer((Invocation invocation) async {
      return 0;
    });
    await residentRunner.run();

    expect(await globals.fs.file('foo').readAsString(), testUri.toString());
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  testUsingContext('FlutterDevice uses dartdevc configuration when targeting web', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final MockDevice mockDevice = MockDevice();
    when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.web_javascript;
    });

    final DefaultResidentCompiler residentCompiler = (await FlutterDevice.create(
      mockDevice,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        nullSafetyMode: NullSafetyMode.unsound,
      ),
      flutterProject: FlutterProject.current(),
      target: null,
    )).generator as DefaultResidentCompiler;

    expect(residentCompiler.initializeFromDill,
      globals.fs.path.join(getBuildDirectory(), 'cache.dill'));
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
    final MockDevice mockDevice = MockDevice();
    when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.web_javascript;
    });

    final DefaultResidentCompiler residentCompiler = (await FlutterDevice.create(
      mockDevice,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>['--enable-experiment=non-nullable'],
      ),
      flutterProject: FlutterProject.current(),
      target: null,
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
  });

  testUsingContext('connect sets up log reader', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final MockDevice mockDevice = MockDevice();
    final MockDartDevelopmentService mockDds = MockDartDevelopmentService();
    final MockDeviceLogReader mockLogReader = MockDeviceLogReader();
    when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(mockLogReader);
    when(mockDevice.dds).thenReturn(mockDds);
    when(mockDds.startDartDevelopmentService(any, any)).thenReturn(null);

    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      observatoryUris: Stream<Uri>.value(testUri),
    );

    await flutterDevice.connect();
    verify(mockLogReader.connectedVMService = mockVMService);
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      ReloadMethod reloadMethod,
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
class MockDevice extends Mock implements Device {}
class MockDeviceLogReader extends Mock implements DeviceLogReader {}
class MockDevicePortForwarder extends Mock implements DevicePortForwarder {}
class MockDevtoolsLauncher extends Mock implements DevtoolsLauncher {}
class MockUsage extends Mock implements Usage {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}

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

class FakeWidgetCache implements WidgetCache {
  @override
  Future<String> validateLibrary(Uri libraryUri) async {
    return 'FakeWidget';
  }
}

class FakeFlutterDevice extends FlutterDevice {
  FakeFlutterDevice(
    Device device,
    BuildInfo buildInfo,
    WidgetCache widgetCache,
    ResidentCompiler residentCompiler,
    this.fakeDevFS,
  ) : super(device, buildInfo: buildInfo, widgetCache:widgetCache, generator: residentCompiler);

  @override
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    bool disableDds = false,
    bool ipv6 = false,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
    GetSkSLMethod getSkSLMethod,
    PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
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
