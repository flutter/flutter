// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  libraries: <vm_service.LibraryRef>[],
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
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  libraries: <vm_service.LibraryRef>[],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
);

final FlutterView fakeFlutterView = FlutterView(
  id: 'a',
  uiIsolate: fakeUnpausedIsolate,
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

  setUp(() {
    testbed = Testbed(setup: () {
      globals.fs.file('.packages').writeAsStringSync('\n');
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
    when(mockFlutterDevice.views).thenReturn(<FlutterView>[
      // NB: still using mock FlutterDevice.
      fakeFlutterView,
    ]);
    when(mockFlutterDevice.device).thenReturn(mockDevice);
    when(mockFlutterDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) async { });
    when(mockFlutterDevice.observatoryUris).thenAnswer((_) => Stream<Uri>.value(testUri));
    when(mockFlutterDevice.connect(
      reloadSources: anyNamed('reloadSources'),
      restart: anyNamed('restart'),
      compileExpression: anyNamed('compileExpression'),
    )).thenAnswer((Invocation invocation) async { });
    when(mockFlutterDevice.setupDevFS(any, any, packagesFilePath: anyNamed('packagesFilePath')))
      .thenAnswer((Invocation invocation) async {
        return testUri;
      });
    when(mockFlutterDevice.vmService).thenAnswer((Invocation invocation) {
      return fakeVmServiceHost.vmService;
    });
    when(mockFlutterDevice.refreshViews()).thenAnswer((Invocation invocation) async { });
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

  test('FlutterDevice can list views with a filter', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: kListViewsMethod,
        jsonResponse: <String, Object>{
          'views': <Object>[
            fakeFlutterView.toJson(),
          ],
        },
      ),
    ]);
    final MockDevice mockDevice = MockDevice();
    final FlutterDevice flutterDevice = FlutterDevice(
      mockDevice,
      buildInfo: BuildInfo.debug,
      viewFilter: 'b', // Does not match name of `fakeFlutterView`.
    );

    flutterDevice.vmService = fakeVmServiceHost.vmService;

    await flutterDevice.refreshViews();

    expect(flutterDevice.views, isEmpty);
  }));

  test('ResidentRunner can attach to device successfully', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
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

  test('ResidentRunner can attach to device successfully with --fast-start', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        id: '2',
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      const FakeVmServiceRequest(
        id: '3',
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        }
      ),
      FakeVmServiceRequest(
        id: '4',
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
  }));

  test('ResidentRunner can handle an RPC exception from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
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
    })).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  test('ResidentRunner can send target platform to analytics from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      // Not all requests are present due to existing mocks
      FakeVmServiceRequest(
        id: '1',
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        id: '2',
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

  test('ResidentRunner can send target platform to analytics from full restart', () => testbed.run(() async {
     // Not all requests are present due to existing mocks
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        id: '2',
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
      ),
      const FakeVmServiceRequest(
        id: '3',
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      FakeVmServiceRequest(
        id: '4',
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
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  test('ResidentRunner Can handle an RPC exception from hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
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
    })).called(1);
  }, overrides: <Type, Generator>{
    Usage: () => MockUsage(),
  }));

  test('ResidentRunner uses temp directory when there is no output dill path', () => testbed.run(() {
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

  test('ResidentRunner copies output dill to cache location during preExit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('hello');
    await residentRunner.preExit();
    final File cacheDill = globals.fs.file(globals.fs.path.join(getBuildDirectory(), 'cache.dill'));

    expect(cacheDill, exists);
    expect(cacheDill.readAsStringSync(), 'hello');
  }));

  test('ResidentRunner handles output dill missing during preExit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.preExit();
    final File cacheDill = globals.fs.file(globals.fs.path.join(getBuildDirectory(), 'cache.dill'));

    expect(cacheDill, isNot(exists));
  }));

  test('ResidentRunner printHelpDetails', () => testbed.run(() {
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
          commandHelp.w,
          commandHelp.t,
          commandHelp.L,
          commandHelp.S,
          commandHelp.U,
          commandHelp.i,
          commandHelp.p,
          commandHelp.o,
          commandHelp.z,
          commandHelp.M,
          commandHelp.v,
          commandHelp.P,
          commandHelp.a,
          'An Observatory debugger and profiler on null is available at: null',
          ''
        ].join('\n')
    ));
  }));

  test('ResidentRunner does support CanvasKit', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    expect(() => residentRunner.toggleCanvaskit(),
      throwsA(isA<Exception>()));
  }));

  test('ResidentRunner handles writeSkSL returning no data', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
       FakeVmServiceRequest(
        id: '1',
        method: kGetSkSLsMethod,
        args: <String, Object>{
          'viewId': fakeFlutterView.id,
        },
        jsonResponse: <String, Object>{
          'SkSLs': <String, Object>{}
        }
      )
    ]);
    await residentRunner.writeSkSL();

    expect(testLogger.statusText, contains('No data was receieved'));
  }));

  test('ResidentRunner can write SkSL data to a unique file with engine revision, platform, and device name', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
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

    expect(testLogger.statusText, contains('flutter_01.sksl'));
    expect(globals.fs.file('flutter_01.sksl'), exists);
    expect(json.decode(globals.fs.file('flutter_01.sksl').readAsStringSync()), <String, Object>{
      'platform': 'android',
      'name': 'test device',
      'engineRevision': '42.2', // From FakeFlutterVersion
      'data': <String, Object>{'A': 'B'}
    });
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('ResidentRunner can take screenshot on debug device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'false',
        },
      ),
      FakeVmServiceRequest(
        id: '2',
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

  test('ResidentRunner clears the screen when it should', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    const String message = 'This should be cleared';
    expect(testLogger.statusText, equals(''));
    testLogger.printStatus(message);
    expect(testLogger.statusText, equals(message + '\n'));  // printStatus makes a newline
    residentRunner.clearScreen();
    expect(testLogger.statusText, equals(''));
  }));

  test('ResidentRunner bails taking screenshot on debug device if debugAllowBanner throws RpcError', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
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

  test('ResidentRunner bails taking screenshot on debug device if debugAllowBanner during second request', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'false',
        },
      ),
      FakeVmServiceRequest(
        id: '2',
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
  }));

  test('ResidentRunner bails taking screenshot on debug device if takeScreenshot throws', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: 'ext.flutter.debugAllowBanner',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
          'enabled': 'false',
        },
      ),
      FakeVmServiceRequest(
        id: '2',
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

  test("ResidentRunner can't take screenshot on device without support", () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    when(mockDevice.supportsScreenshot).thenReturn(false);

    expect(() => residentRunner.screenshot(mockFlutterDevice),
        throwsAssertionError);
  }));

  test('ResidentRunner does not toggle banner in non-debug mode', () => testbed.run(() async {
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

  test('FlutterDevice will not exit a paused isolate', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: '_flutter.listViews',
        jsonResponse: <String, Object>{
          'views': <Object>[
            fakeFlutterView.toJson(),
          ],
        },
      ),
      FakeVmServiceRequest(
        id: '2',
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakePausedIsolate.toJson(),
      ),
    ]);
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      <FlutterView>[ fakeFlutterView ],
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;
    when(mockDevice.supportsFlutterExit).thenReturn(true);

    await flutterDevice.exitApps();

    verify(mockDevice.stopApp(any)).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('FlutterDevice will call stopApp if the exit request times out', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: '_flutter.listViews',
        jsonResponse: <String, Object>{
          'views': <Object>[
            fakeFlutterView.toJson(),
          ],
        },
      ),
      FakeVmServiceRequest(
        id: '2',
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        id: '3',
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
      <FlutterView>[ fakeFlutterView ],
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;
    when(mockDevice.supportsFlutterExit).thenReturn(true);

    await flutterDevice.exitApps(
      timeoutDelay: Duration.zero,
    );

    verify(mockDevice.stopApp(any)).called(1);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('FlutterDevice will exit an un-paused isolate', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      FakeVmServiceRequest(
        id: '1',
        method: kListViewsMethod,
        jsonResponse: <String, Object>{
          'views': <Object>[
            fakeFlutterView.toJson(),
          ],
        },
      ),
      FakeVmServiceRequest(
        id: '2',
        method: 'getIsolate',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        id: '3',
        method: 'ext.flutter.exit',
        args: <String, Object>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        close: true,
      )
    ]);
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      <FlutterView> [fakeFlutterView ],
    );
    flutterDevice.vmService = fakeVmServiceHost.vmService;

    when(mockDevice.supportsFlutterExit).thenReturn(true);

    final Future<void> exitFuture = flutterDevice.exitApps();

    await expectLater(exitFuture, completes);
    expect(fakeVmServiceHost.hasRemainingExpectations, false);
  }));

  test('ResidentRunner refreshViews calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.refreshViews();

    verify(mockFlutterDevice.refreshViews()).called(1);
  }));

  test('ResidentRunner debugDumpApp calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpApp();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpApp()).called(1);
  }));

  test('ResidentRunner debugDumpRenderTree calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpRenderTree();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpRenderTree()).called(1);
  }));

  test('ResidentRunner debugDumpLayerTree calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpLayerTree();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpLayerTree()).called(1);
  }));

  test('ResidentRunner debugDumpSemanticsTreeInTraversalOrder calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpSemanticsTreeInTraversalOrder();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpSemanticsTreeInTraversalOrder()).called(1);
  }));

  test('ResidentRunner debugDumpSemanticsTreeInInverseHitTestOrder calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugDumpSemanticsTreeInInverseHitTestOrder();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugDumpSemanticsTreeInInverseHitTestOrder()).called(1);
  }));

  test('ResidentRunner debugToggleDebugPaintSizeEnabled calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleDebugPaintSizeEnabled();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleDebugPaintSizeEnabled()).called(1);
  }));

  test('ResidentRunner debugToggleDebugCheckElevationsEnabled calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleDebugCheckElevationsEnabled();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleDebugCheckElevationsEnabled()).called(1);
  }));

  test('ResidentRunner debugTogglePerformanceOverlayOverride calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugTogglePerformanceOverlayOverride();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.debugTogglePerformanceOverlayOverride()).called(1);
  }));

  test('ResidentRunner debugToggleWidgetInspector calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleWidgetInspector();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleWidgetInspector()).called(1);
  }));

  test('ResidentRunner debugToggleProfileWidgetBuilds calls flutter device', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    await residentRunner.debugToggleProfileWidgetBuilds();

    verify(mockFlutterDevice.refreshViews()).called(1);
    verify(mockFlutterDevice.toggleProfileWidgetBuilds()).called(1);
  }));

  test('HotRunner writes vm service file when providing debugging option', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
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

  test('HotRunner unforwards device ports', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
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

  test('HotRunner handles failure to write vmservice file', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
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
  }, overrides: <Type, Generator>{
    FileSystem: () => ThrowingForwardingFileSystem(MemoryFileSystem()),
  }));


  test('ColdRunner writes vm service file when providing debugging option', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
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
  }));

  test('FlutterDevice uses dartdevc configuration when targeting web', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final MockDevice mockDevice = MockDevice();
    when(mockDevice.targetPlatform).thenAnswer((Invocation invocation) async {
      return TargetPlatform.web_javascript;
    });

    final DefaultResidentCompiler residentCompiler = (await FlutterDevice.create(
      mockDevice,
      buildInfo: BuildInfo.debug,
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
    expect(
      residentCompiler.platformDill,
      globals.fs.file(globals.artifacts.getArtifactPath(Artifact.webPlatformKernelDill, mode: BuildMode.debug))
        .absolute.uri.toString(),
    );
  }));

  test('connect sets up log reader', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final MockDevice mockDevice = MockDevice();
    final MockDeviceLogReader mockLogReader = MockDeviceLogReader();
    when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(mockLogReader);

    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      mockDevice,
      <FlutterView>[],
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
      io.CompressionOptions compression,
      Device device,
    }) async => mockVMService,
  }));

  test('nextPlatform moves through expected platforms', () {
    expect(nextPlatform('android', TestFeatureFlags()), 'iOS');
    expect(nextPlatform('iOS', TestFeatureFlags()), 'fuchsia');
    expect(nextPlatform('fuchsia', TestFeatureFlags()), 'android');
    expect(nextPlatform('fuchsia', TestFeatureFlags(isMacOSEnabled: true)), 'macOS');
    expect(() => nextPlatform('unknown', TestFeatureFlags()), throwsAssertionError);
  });
}

class MockFlutterDevice extends Mock implements FlutterDevice {}
class MockVMService extends Mock implements vm_service.VmService {}
class MockDevFS extends Mock implements DevFS {}
class MockDevice extends Mock implements Device {}
class MockDeviceLogReader extends Mock implements DeviceLogReader {}
class MockDevicePortForwarder extends Mock implements DevicePortForwarder {}
class MockUsage extends Mock implements Usage {}
class MockProcessManager extends Mock implements ProcessManager {}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice(Device device, this.views, { Stream<Uri> observatoryUris })
    : super(device, buildInfo: BuildInfo.debug) {
    _observatoryUris = observatoryUris;
  }

  @override
  final List<FlutterView> views;

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
