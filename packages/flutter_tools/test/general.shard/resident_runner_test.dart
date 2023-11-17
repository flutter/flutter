// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart' as dds;
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/command_help.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/scene_importer.dart';
import 'package:flutter_tools/src/build_system/targets/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:native_assets_cli/native_assets_cli.dart'
    hide BuildMode, Target;
import 'package:native_assets_cli/native_assets_cli.dart' as native_assets_cli;
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart';
import '../src/testbed.dart';
import 'fake_native_assets_build_runner.dart';

final vm_service.Event fakeUnpausedEvent = vm_service.Event(
  kind: vm_service.EventKind.kResume,
  timestamp: 0
);

final vm_service.Event fakePausedEvent = vm_service.Event(
  kind: vm_service.EventKind.kPauseException,
  timestamp: 0
);

final vm_service.Isolate fakeUnpausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: fakeUnpausedEvent,
  breakpoints: <vm_service.Breakpoint>[],
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
  pauseEvent: fakePausedEvent,
  breakpoints: <vm_service.Breakpoint>[
    vm_service.Breakpoint(
      breakpointNumber: 123,
      id: 'test-breakpoint',
      location: vm_service.SourceLocation(
        tokenPos: 0,
        script: vm_service.ScriptRef(id: 'test-script', uri: 'foo.dart'),
      ),
      enabled: true,
      resolved: true,
    ),
  ],
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

const FakeVmServiceRequest evict = FakeVmServiceRequest(
  method: 'ext.flutter.evict',
  args: <String, Object>{
    'value': 'asset',
    'isolateId': '1',
  }
);

const FakeVmServiceRequest evictShader = FakeVmServiceRequest(
  method: 'ext.ui.window.reinitializeShader',
  args: <String, Object>{
    'assetKey': 'foo.frag',
    'isolateId': '1',
  }
);

final Uri testUri = Uri.parse('foo://bar');

void main() {
  late Testbed testbed;
  late FakeFlutterDevice flutterDevice;
  late FakeDevFS devFS;
  late ResidentRunner residentRunner;
  late FakeDevice device;
  FakeVmServiceHost? fakeVmServiceHost;

  setUp(() {
    testbed = Testbed(setup: () {
      globals.fs.file('.packages')
        .writeAsStringSync('\n');
      globals.fs.file(globals.fs.path.join('build', 'app.dill'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ABC');
      residentRunner = HotRunner(
        <FlutterDevice>[
          flutterDevice,
        ],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
      );
    });
    device = FakeDevice();
    devFS = FakeDevFS();
    flutterDevice = FakeFlutterDevice()
      ..testUri = testUri
      ..vmServiceHost = (() => fakeVmServiceHost)
      ..device = device
      .._devFS = devFS;
  });

  testUsingContext('ResidentRunner can attach to device successfully', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    final Future<int?> result = residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    );
    final Future<DebugConnectionInfo> connectionInfo = futureConnectionInfo.future;

    expect(await result, 0);
    expect(futureConnectionInfo.isCompleted, true);
    expect((await connectionInfo).baseUri, 'foo://bar');
    expect(futureAppStart.isCompleted, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner suppresses errors for the initial compilation', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    final FakeResidentCompiler residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 0 ,<Uri>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    flutterDevice.generator = residentCompiler;

    expect(await residentRunner.run(enableDevTools: true), 0);
    expect(residentCompiler.didSuppressErrors, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentRunner calls appFailedToStart if initial compilation fails', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeResidentCompiler residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 1 ,<Uri>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    flutterDevice.generator = residentCompiler;

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
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    flutterDevice.runColdCode = 1;

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
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    flutterDevice.runColdError = Exception('BAD STUFF');


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
    final FakeResidentCompiler residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 0 ,<Uri>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      applicationBinary: globals.fs.file('app-debug.apk'),
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    flutterDevice.generator = residentCompiler;

    expect(await residentRunner.run(enableDevTools: true), 0);
    expect(residentCompiler.didSuppressErrors, false);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can attach to device successfully with --fast-start', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
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
        flutterDevice,
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
    final Future<int?> result = residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    );
    final Future<DebugConnectionInfo> connectionInfo = futureConnectionInfo.future;

    expect(await result, 0);
    expect(futureConnectionInfo.isCompleted, true);
    expect((await connectionInfo).baseUri, 'foo://bar');
    expect(futureAppStart.isCompleted, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can handle an RPC exception from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
    flutterDevice.reportError = vm_service.RPCError('something bad happened', 666, '');

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, true);
    expect(result.code, 1);
    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'exception', parameters: CustomDimensions(
        hotEventTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        hotEventSdkName: 'Android',
        hotEventEmulator: false,
        hotEventFullRestart: false,
      )),
    ));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner fails its operation if the device initialization is not complete', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
    ));
    await futureAppStart.future;
    flutterDevice._devFS = null;

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, false);
    expect(result.code, 1);
    expect(result.message, contains('Device initialization has not completed.'));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner can handle an reload-barred exception from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
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
    flutterDevice.reportError = vm_service.RPCError('something bad happened', kIsolateReloadBarred, '');

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, true);
    expect(result.code, kIsolateReloadBarred);
    expect(result.message, contains('Unable to hot reload application due to an unrecoverable error'));

    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'reload-barred', parameters: CustomDimensions(
        hotEventTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        hotEventSdkName: 'Android',
        hotEventEmulator: false,
        hotEventFullRestart: false,
      )),
    ));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner reports hot reload event with null safety analytics', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
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
    flutterDevice.reportError = vm_service.RPCError('something bad happened', 666, '');

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, true);
    expect(result.code, 1);

    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'exception', parameters: CustomDimensions(
        hotEventTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        hotEventSdkName: 'Android',
        hotEventEmulator: false,
        hotEventFullRestart: false,
      )),
    ));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner does not reload sources if no sources changed', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolatePauseEvent',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedEvent.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
      ),
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
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
    flutterDevice.report =  UpdateFSReport(success: true);

    final OperationResult result = await residentRunner.restart();

    expect(result.code, 0);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner reports error with missing entrypoint file', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{
          'isolates': <Object>[
            fakeUnpausedIsolate.toJson(),
          ],
        })!.toJson(),
      ),
      const FakeVmServiceRequest(
        method: kReloadSourcesServiceName,
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
        method: 'getIsolatePauseEvent',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedEvent.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object?>{
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
    flutterDevice.report =  UpdateFSReport(success: true, invalidatedSourcesCount: 1);

    final OperationResult result = await residentRunner.restart();

    expect(globals.fs.file(globals.fs.path.join('lib', 'main.dart')), isNot(exists));
    expect(testLogger.errorText, contains('The entrypoint file (i.e. the file with main())'));
    expect(result.fatal, false);
    expect(result.code, 0);
  }));

   testUsingContext('ResidentRunner resets compilation time on reload reject', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{
          'isolates': <Object>[
            fakeUnpausedIsolate.toJson(),
          ],
        })!.toJson(),
      ),
      const FakeVmServiceRequest(
        method: kReloadSourcesServiceName,
        args: <String, Object>{
          'isolateId': '1',
          'pause': false,
          'rootLibUri': 'main.dart.incremental.dill',
        },
        jsonResponse: <String, Object>{
          'type': 'ReloadReport',
          'success': false,
          'notices': <Object>[
            <String, Object>{
              'message': 'Failed to hot reload',
            },
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
        args: <String, Object?>{
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
    flutterDevice.report =  UpdateFSReport(success: true, invalidatedSourcesCount: 1);

    final OperationResult result = await residentRunner.restart();

    expect(result.fatal, false);
    expect(result.message, contains('Reload rejected: Failed to hot reload')); // contains error message from reload report.
    expect(result.code, 1);
    expect(devFS.lastCompiled, null);
  }));

  testUsingContext('ResidentRunner can send target platform to analytics from hot reload', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{
          'isolates': <Object>[
            fakeUnpausedIsolate.toJson(),
          ],
        })!.toJson(),
      ),
      const FakeVmServiceRequest(
        method: kReloadSourcesServiceName,
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
        method: 'getIsolatePauseEvent',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedEvent.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object?>{
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

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, false);
    expect(result.code, 0);

    final TestUsageEvent event = (globals.flutterUsage as TestUsage).events.first;
    expect(event.category, 'hot');
    expect(event.parameter, 'reload');
    expect(event.parameters?.hotEventTargetPlatform, getNameForTargetPlatform(TargetPlatform.android_arm));
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner reports hot reload time details', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: fakeVM.toJson(),
      ),
      const FakeVmServiceRequest(
        method: kReloadSourcesServiceName,
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
            'finalLibraryCount': 42,
          },
        },
      ),
      FakeVmServiceRequest(
        method: 'getIsolatePauseEvent',
        args: <String, Object>{
          'isolateId': '1',
        },
        jsonResponse: fakeUnpausedEvent.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'ext.flutter.reassemble',
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
      ),
    ]);
    final FakeDelegateFlutterDevice flutterDevice = FakeDelegateFlutterDevice(
      device,
      BuildInfo.debug,
      FakeResidentCompiler(),
      devFS,
    )..vmService = fakeVmServiceHost!.vmService;
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    devFS.nextUpdateReport = UpdateFSReport(
      success: true,
      invalidatedSourcesCount: 1,
    );

    final Completer<DebugConnectionInfo> futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final Completer<void> futureAppStart = Completer<void>.sync();
    unawaited(residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
      enableDevTools: true,
    ));

    await futureAppStart.future;
    await residentRunner.restart();

    // The actual test: Expect to have compile, reload and reassemble times.
    expect(
        testLogger.statusText,
        contains(RegExp(r'Reloaded 1 of 42 libraries in \d+ms '
            r'\(compile: \d+ ms, reload: \d+ ms, reassemble: \d+ ms\)\.')));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    Platform: () => FakePlatform(),
    ProjectFileInvalidator: () => FakeProjectFileInvalidator(),
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner can send target platform to analytics from full restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
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
      ),
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
    expect(event.parameters?.hotEventTargetPlatform, getNameForTargetPlatform(TargetPlatform.android_arm));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner can remove breakpoints and exception-pause-mode from paused isolate during hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakePausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
      ),
      const FakeVmServiceRequest(
        method: 'setIsolatePauseMode',
        args: <String, String>{
          'isolateId': '1',
          'exceptionPauseMode': 'None',
        }
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
        ),
      ),
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
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner will alternative the name of the dill file uploaded for a hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
      listViews,
      FakeVmServiceRequest(
        method: 'getIsolate',
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
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
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
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
        args: <String, Object?>{
          'isolateId': fakeUnpausedIsolate.id,
        },
        jsonResponse: fakeUnpausedIsolate.toJson(),
      ),
      FakeVmServiceRequest(
        method: 'getVM',
        jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
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

    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('ResidentRunner Can handle an RPC exception from hot restart', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
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
    flutterDevice.reportError = vm_service.RPCError('something bad happened', 666, '');

    final OperationResult result = await residentRunner.restart(fullRestart: true);
    expect(result.fatal, true);
    expect(result.code, 1);

    expect((globals.flutterUsage as TestUsage).events, contains(
      TestUsageEvent('hot', 'exception', parameters: CustomDimensions(
        hotEventTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        hotEventSdkName: 'Android',
        hotEventEmulator: false,
        hotEventFullRestart: true,
      )),
    ));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    Usage: () => TestUsage(),
  }));

  testUsingContext('ResidentRunner uses temp directory when there is no output dill path', () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    expect(residentRunner.artifactDirectory.path, contains('flutter_tool.'));

    final ResidentRunner otherRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
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

    // Create necessary files for [DartPluginRegistrantTarget]
    final File packageConfig = globals.fs.directory('.dart_tool')
        .childFile('package_config.json');
    packageConfig.createSync(recursive: true);
    packageConfig.writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "path_provider_linux",
      "rootUri": "../../../path_provider_linux",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''');
    // Start from an empty dart_plugin_registrant.dart file.
    globals.fs.directory('.dart_tool').childDirectory('flutter_build').childFile('dart_plugin_registrant.dart').createSync(recursive: true);

    await residentRunner.runSourceGenerators();

    expect(testLogger.errorText, isEmpty);
    expect(testLogger.statusText, isEmpty);
  }));

  testUsingContext('generated main uses correct target', () => testbed.run(() async {
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
    globals.fs.file('pubspec.yaml').writeAsStringSync('''
flutter:
  generate: true

dependencies:
  flutter:
    sdk: flutter
  path_provider_linux: 1.0.0
''');

    // Create necessary files for [DartPluginRegistrantTarget], including a
    // plugin that will trigger generation.
    final File packageConfig = globals.fs.directory('.dart_tool')
        .childFile('package_config.json');
    packageConfig.createSync(recursive: true);
    packageConfig.writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "path_provider_linux",
      "rootUri": "../path_provider_linux",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''');
    globals.fs.file('.packages').writeAsStringSync('''
path_provider_linux:/path_provider_linux/lib/
''');
    final Directory fakePluginDir = globals.fs.directory('path_provider_linux');
    final File pluginPubspec = fakePluginDir.childFile('pubspec.yaml');
    pluginPubspec.createSync(recursive: true);
    pluginPubspec.writeAsStringSync('''
name: path_provider_linux

flutter:
  plugin:
    implements: path_provider
    platforms:
      linux:
        dartPluginClass: PathProviderLinux
''');

    residentRunner = HotRunner(
        <FlutterDevice>[
          flutterDevice,
        ],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'custom_main.dart',
        devtoolsHandler: createNoOpHandler,
      );
    await residentRunner.runSourceGenerators();

    final File generatedMain = globals.fs.directory('.dart_tool')
        .childDirectory('flutter_build')
        .childFile('dart_plugin_registrant.dart');

    expect(generatedMain.existsSync(), isTrue);
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

  testUsingContext('ResidentRunner generates files when l10n.yaml exists', () => testbed.run(() async {
    globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
      .createSync(recursive: true);
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

    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeResidentCompiler residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 1 ,<Uri>[]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    flutterDevice.generator = residentCompiler;

    await residentRunner.run();

    final File generatedLocalizationsFile = globals.fs.directory('.dart_tool')
      .childDirectory('flutter_gen')
      .childDirectory('gen_l10n')
      .childFile('app_localizations.dart');
    expect(generatedLocalizationsFile.existsSync(), isTrue);

    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  }));

  testUsingContext('ResidentRunner printHelpDetails hot runner', () => testbed.run(() {
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
          commandHelp.v,
          commandHelp.s,
          commandHelp.w,
          commandHelp.t,
          commandHelp.L,
          commandHelp.f,
          commandHelp.S,
          commandHelp.U,
          commandHelp.i,
          commandHelp.p,
          commandHelp.I,
          commandHelp.o,
          commandHelp.b,
          commandHelp.P,
          commandHelp.a,
          commandHelp.M,
          commandHelp.g,
          commandHelp.j,
          commandHelp.hWithDetails,
          commandHelp.c,
          commandHelp.q,
          '',
          'A Dart VM Service on FakeDevice is available at: null',
          '',
        ].join('\n')
    ));
  }));

  testUsingContext('ResidentRunner printHelp hot runner', () => testbed.run(() {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    residentRunner.printHelp(details: false);

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
          commandHelp.hWithoutDetails,
          commandHelp.c,
          commandHelp.q,
          '',
          'A Dart VM Service on FakeDevice is available at: null',
          '',
        ].join('\n')
    ));
  }));

  testUsingContext('ResidentRunner printHelpDetails cold runner', () => testbed.run(() {
    fakeVmServiceHost = null;
    residentRunner = ColdRunner(
      <FlutterDevice>[
        flutterDevice,
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
          commandHelp.v,
          commandHelp.s,
          commandHelp.hWithDetails,
          commandHelp.c,
          commandHelp.q,
          '',
        ].join('\n')
    ));
  }));

  testUsingContext('ResidentRunner printHelp cold runner', () => testbed.run(() {
    fakeVmServiceHost = null;
    residentRunner = ColdRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.printHelp(details: false);

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
          commandHelp.hWithoutDetails,
          commandHelp.c,
          commandHelp.q,
          '',
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
          'SkSLs': <String, Object>{},
        }
      ),
    ]);
    await residentRunner.writeSkSL();

    expect(testLogger.statusText, contains('No data was received'));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
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
          },
        },
      ),
    ]);
    await residentRunner.writeSkSL();

    expect(testLogger.statusText, contains('flutter_01.sksl.json'));
    expect(globals.fs.file('flutter_01.sksl.json'), exists);
    expect(json.decode(globals.fs.file('flutter_01.sksl.json').readAsStringSync()), <String, Object>{
      'platform': 'android',
      'name': 'FakeDevice',
      'engineRevision': 'abcdefg',
      'data': <String, Object>{'A': 'B'},
    });
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystemUtils: () => FileSystemUtils(
      fileSystem: globals.fs,
      platform: globals.platform,
    ),
    FlutterVersion: () => FakeFlutterVersion(engineRevision: 'abcdefg'),
  }));

  testUsingContext('ResidentRunner ignores DevtoolsLauncher when attaching with enableDevTools: false - cold mode', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    residentRunner = ColdRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    final Future<int?> result = residentRunner.attach();
    expect(await result, 0);
  }));

  testUsingContext('FlutterDevice can exit from a release mode isolate with no VmService', () => testbed.run(() async {
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
    );

    await flutterDevice.exitApps();

    expect(device.appStopped, true);
  }));

  testUsingContext('FlutterDevice will exit an un-paused isolate using stopApp', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
    );
    flutterDevice.vmService = fakeVmServiceHost!.vmService;

    final Future<void> exitFuture = flutterDevice.exitApps();

    await expectLater(exitFuture, completes);
    expect(device.appStopped, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('HotRunner writes vm service file when providing debugging option', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    await residentRunner.run(enableDevTools: true);

    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    expect(await globals.fs.file('foo').readAsString(), testUri.toString());
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          null,
          treeShakeIcons: false,
        )
      ),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join('build', 'cache.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with dart defines', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
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

    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join(
      'build', '187ef4436122d1cc2f40dc2b92f0eba0.cache.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with null safety', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          extraFrontEndOptions: <String>['--enable-experiment=non-nullable']
        )
      ),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join(
      'build', 'cache.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with track-widget-creation', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join(
      'build', 'cache.dill.track.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner does not copy app.dill if a dillOutputPath is given', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      dillOutputPath: 'test',
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run(enableDevTools: true);

    expect(globals.fs.file(globals.fs.path.join('build', 'cache.dill')), isNot(exists));
  }));

  testUsingContext('HotRunner copies compiled app.dill to cache during startup with --track-widget-creation', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
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

    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file(globals.fs.path.join('build', 'cache.dill.track.dill')).readAsString(), 'ABC');
  }));

  testUsingContext('HotRunner calls device dispose', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    await residentRunner.run();
    expect(device.disposed, true);
  }));

  testUsingContext('HotRunner handles failure to write vmservice file', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      listViews,
    ]);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    await residentRunner.run(enableDevTools: true);

    expect(testLogger.errorText, contains('Failed to write vmservice-out-file at foo'));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    FileSystem: () => ThrowingForwardingFileSystem(MemoryFileSystem.test()),
  }));

  testUsingContext('ColdRunner writes vm service file when providing debugging option', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
    ], wsAddress: testUri);
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = ColdRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    await residentRunner.run(enableDevTools: true);

    expect(await globals.fs.file('foo').readAsString(), testUri.toString());
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  }));

  testUsingContext('FlutterDevice uses dartdevc configuration when targeting web', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice(targetPlatform: TargetPlatform.web_javascript);
    final DefaultResidentCompiler? residentCompiler = (await FlutterDevice.create(
      device,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        nullSafetyMode: NullSafetyMode.unsound,
      ),
      target: null,
      platform: FakePlatform(),
    )).generator as DefaultResidentCompiler?;

    expect(residentCompiler!.initializeFromDill,
      globals.fs.path.join(getBuildDirectory(), 'fbbe6a61fb7a1de317d381f8df4814e5.cache.dill'));
    expect(residentCompiler.librariesSpec,
      globals.fs.file(globals.artifacts!.getHostArtifact(HostArtifact.flutterWebLibrariesJson))
        .uri.toString());
    expect(residentCompiler.targetModel, TargetModel.dartdevc);
    expect(residentCompiler.sdkRoot,
      '${globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path}/');
    expect(residentCompiler.platformDill, 'file:///HostArtifact.webPlatformKernelFolder/ddc_outline.dill');
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('FlutterDevice uses dartdevc configuration when targeting web with null-safety autodetected', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice(targetPlatform: TargetPlatform.web_javascript);

    final DefaultResidentCompiler? residentCompiler = (await FlutterDevice.create(
      device,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>['--enable-experiment=non-nullable'],
      ),
      target: null,
      platform: FakePlatform(),
    )).generator as DefaultResidentCompiler?;

    expect(residentCompiler!.initializeFromDill,
      globals.fs.path.join(getBuildDirectory(), '80b1a4cf4e7b90e1ab5f72022a0bc624.cache.dill'));
    expect(residentCompiler.librariesSpec,
      globals.fs.file(globals.artifacts!.getHostArtifact(HostArtifact.flutterWebLibrariesJson))
        .uri.toString());
    expect(residentCompiler.targetModel, TargetModel.dartdevc);
    expect(residentCompiler.sdkRoot,
      '${globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path}/');
    expect(residentCompiler.platformDill, 'file:///HostArtifact.webPlatformKernelFolder/ddc_outline_sound.dill');
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('FlutterDevice passes alternative-invalidation-strategy flag', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice();


    final DefaultResidentCompiler? residentCompiler = (await FlutterDevice.create(
      device,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>[],
      ),
      target: null, platform: FakePlatform(),
    )).generator as DefaultResidentCompiler?;

    expect(residentCompiler!.extraFrontEndOptions,
      contains('--enable-experiment=alternative-invalidation-strategy'));
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('FlutterDevice passes initializeFromDill parameter if specified', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice();

    final DefaultResidentCompiler? residentCompiler = (await FlutterDevice.create(
      device,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>[],
        initializeFromDill: '/foo/bar.dill',
      ),
      target: null, platform: FakePlatform(),
    )).generator as DefaultResidentCompiler?;

    expect(residentCompiler!.initializeFromDill, '/foo/bar.dill');
    expect(residentCompiler.assumeInitializeFromDillUpToDate, false);
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

   testUsingContext('FlutterDevice passes assumeInitializeFromDillUpToDate parameter if specified', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice();

    final DefaultResidentCompiler? residentCompiler = (await FlutterDevice.create(
      device,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>[],
        assumeInitializeFromDillUpToDate: true,
      ),
      target: null, platform: FakePlatform(),
    )).generator as DefaultResidentCompiler?;

    expect(residentCompiler!.assumeInitializeFromDillUpToDate, true);
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('FlutterDevice passes frontendServerStarterPath parameter if specified', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice();

    final DefaultResidentCompiler? residentCompiler = (await FlutterDevice.create(
      device,
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        frontendServerStarterPath: '/foo/bar/frontend_server_starter.dart',
      ),
      target: null, platform: FakePlatform(),
    )).generator as DefaultResidentCompiler?;

    expect(residentCompiler!.frontendServerStarterPath, '/foo/bar/frontend_server_starter.dart');
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Handle existing VM service clients DDS error', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice()
      ..dds = DartDevelopmentService();
    ddsLauncherCallback = (Uri uri, {bool enableAuthCodes = true, bool ipv6 = false, Uri? serviceUri, List<String> cachedUserTags = const <String>[], dds.UriConverter? uriConverter}) {
      expect(uri, Uri(scheme: 'foo', host: 'bar'));
      expect(enableAuthCodes, isTrue);
      expect(ipv6, isFalse);
      expect(serviceUri, Uri(scheme: 'http', host: '127.0.0.1', port: 0));
      expect(cachedUserTags, isEmpty);
      expect(uriConverter, isNull);
      throw FakeDartDevelopmentServiceException(message:
        'Existing VM service clients prevent DDS from taking control.',
      );
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
      vmServiceUris: Stream<Uri>.value(testUri),
    );
    bool caught = false;
    final Completer<void>done = Completer<void>();
    runZonedGuarded(() {
      flutterDevice.connect(allowExistingDdsInstance: true).then((_) => done.complete());
    }, (Object e, StackTrace st) {
      expect(e, isA<ToolExit>());
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
      ReloadSources? reloadSources,
      Restart? restart,
      CompileExpression? compileExpression,
      GetSkSLMethod? getSkSLMethod,
      FlutterProject? flutterProject,
      PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
      io.CompressionOptions? compression,
      Device? device,
      required Logger logger,
    }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
  }));

  testUsingContext('Uses existing DDS URI from exception field', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice()
      ..dds = DartDevelopmentService();
    ddsLauncherCallback = (Uri uri, {bool enableAuthCodes = true, bool ipv6 = false, Uri? serviceUri, List<String> cachedUserTags = const <String>[], dds.UriConverter? uriConverter}) {
      throw dds.DartDevelopmentServiceException.existingDdsInstance(
        'Existing DDS at http://localhost/existingDdsInMessage.',
        ddsUri: Uri.parse('http://localhost/existingDdsInField'),
      );
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
      vmServiceUris: Stream<Uri>.value(testUri),
    );
    final Completer<void> done = Completer<void>();
    await runZonedGuarded(
      () => flutterDevice.connect(allowExistingDdsInstance: true).then((_) => done.complete()),
      (_, __) => done.complete(),
    );
    await done.future;
    expect(device.dds.uri, Uri.parse('http://localhost/existingDdsInField'));
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources? reloadSources,
      Restart? restart,
      CompileExpression? compileExpression,
      GetSkSLMethod? getSkSLMethod,
      FlutterProject? flutterProject,
      PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
      io.CompressionOptions? compression,
      Device? device,
      required Logger logger,
    }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
  }));

  testUsingContext('Falls back to existing DDS URI from exception message', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice()
      ..dds = DartDevelopmentService();
    ddsLauncherCallback = (Uri uri, {bool enableAuthCodes = true, bool ipv6 = false, Uri? serviceUri, List<String> cachedUserTags = const <String>[], dds.UriConverter? uriConverter}) {
      throw dds.DartDevelopmentServiceException.existingDdsInstance(
        'Existing DDS at http://localhost/existingDdsInMessage.',
      );
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
      vmServiceUris: Stream<Uri>.value(testUri),
    );
    final Completer<void>done = Completer<void>();
    await runZonedGuarded(
      () => flutterDevice.connect(allowExistingDdsInstance: true).then((_) => done.complete()),
      (_, __) => done.complete(),
    );
    await done.future;
    expect(device.dds.uri, Uri.parse('http://localhost/existingDdsInMessage'));
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources? reloadSources,
      Restart? restart,
      CompileExpression? compileExpression,
      GetSkSLMethod? getSkSLMethod,
      FlutterProject? flutterProject,
      PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
      io.CompressionOptions? compression,
      Device? device,
      required Logger logger,
    }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
  }));

  testUsingContext('Host VM service ipv6 defaults', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice()
      ..dds = DartDevelopmentService();
    final Completer<void>done = Completer<void>();
    ddsLauncherCallback = (Uri uri, {bool enableAuthCodes = true, bool ipv6 = false, Uri? serviceUri, List<String> cachedUserTags = const <String>[], dds.UriConverter? uriConverter}) async {
      expect(uri, Uri(scheme: 'foo', host: 'bar'));
      expect(enableAuthCodes, isFalse);
      expect(ipv6, isTrue);
      expect(serviceUri, Uri(scheme: 'http', host: '::1', port: 0));
      expect(cachedUserTags, isEmpty);
      expect(uriConverter, isNull);
      done.complete();
      return FakeDartDevelopmentService();
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
      vmServiceUris: Stream<Uri>.value(testUri),
    );
    await flutterDevice.connect(allowExistingDdsInstance: true, ipv6: true, disableServiceAuthCodes: true);
    await done.future;
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources? reloadSources,
      Restart? restart,
      CompileExpression? compileExpression,
      GetSkSLMethod? getSkSLMethod,
      FlutterProject? flutterProject,
      PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
      io.CompressionOptions? compression,
      Device? device,
      required Logger logger,
    }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
  }));

  testUsingContext('Context includes URI converter', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final FakeDevice device = FakeDevice()
      ..dds = DartDevelopmentService();
    final Completer<void>done = Completer<void>();
    ddsLauncherCallback = (
      Uri uri, {
      bool enableAuthCodes = false,
      bool ipv6 = false,
      Uri? serviceUri,
      List<String> cachedUserTags = const <String>[],
      dds.UriConverter? uriConverter,
    }) async {
      expect(uri, Uri(scheme: 'foo', host: 'bar'));
      expect(enableAuthCodes, isFalse);
      expect(ipv6, isTrue);
      expect(serviceUri, Uri(scheme: 'http', host: '::1', port: 0));
      expect(cachedUserTags, isEmpty);
      expect(uriConverter, isNotNull);
      done.complete();
      return FakeDartDevelopmentService();
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
      vmServiceUris: Stream<Uri>.value(testUri),
    );
    await flutterDevice.connect(allowExistingDdsInstance: true, ipv6: true, disableServiceAuthCodes: true);
    await done.future;
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources? reloadSources,
      Restart? restart,
      CompileExpression? compileExpression,
      GetSkSLMethod? getSkSLMethod,
      FlutterProject? flutterProject,
      PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
      io.CompressionOptions compression = io.CompressionOptions.compressionDefault,
      Device? device,
      required Logger logger,
    }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
    dds.UriConverter: () => (String uri) => 'test',
  }));

  testUsingContext('Failed DDS start outputs error message', () => testbed.run(() async {
    // See https://github.com/flutter/flutter/issues/72385 for context.
    final FakeDevice device = FakeDevice()
      ..dds = DartDevelopmentService();
    ddsLauncherCallback = (
      Uri uri, {
      bool enableAuthCodes = false,
      bool ipv6 = false,
      Uri? serviceUri,
      List<String> cachedUserTags = const <String>[],
      dds.UriConverter? uriConverter,
    }) {
      expect(uri, Uri(scheme: 'foo', host: 'bar'));
      expect(enableAuthCodes, isTrue);
      expect(ipv6, isFalse);
      expect(serviceUri, Uri(scheme: 'http', host: '127.0.0.1', port: 0));
      expect(cachedUserTags, isEmpty);
      expect(uriConverter, isNull);
      throw FakeDartDevelopmentServiceException(message: 'No URI');
    };
    final TestFlutterDevice flutterDevice = TestFlutterDevice(
      device,
      vmServiceUris: Stream<Uri>.value(testUri),
    );
    bool caught = false;
    final Completer<void>done = Completer<void>();
    runZonedGuarded(() {
      flutterDevice.connect(allowExistingDdsInstance: true).then((_) => done.complete());
    }, (Object e, StackTrace st) {
      expect(e, isA<StateError>());
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
      ReloadSources? reloadSources,
      Restart? restart,
      CompileExpression? compileExpression,
      GetSkSLMethod? getSkSLMethod,
      FlutterProject? flutterProject,
      PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
      io.CompressionOptions compression = io.CompressionOptions.compressionDefault,
      Device? device,
      required Logger logger,
    }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
  }));

  testUsingContext('nextPlatform moves through expected platforms', () {
    expect(nextPlatform('android'), 'iOS');
    expect(nextPlatform('iOS'), 'windows');
    expect(nextPlatform('windows'), 'macOS');
    expect(nextPlatform('macOS'), 'linux');
    expect(nextPlatform('linux'), 'fuchsia');
    expect(nextPlatform('fuchsia'), 'android');
    expect(() => nextPlatform('unknown'), throwsAssertionError);
  });

  testUsingContext('cleanupAtFinish shuts down resident devtools handler', () => testbed.run(() async {
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );
    await residentRunner.cleanupAtFinish();

    expect((residentRunner.residentDevtoolsHandler! as NoOpDevtoolsHandler).wasShutdown, true);
  }));

  testUsingContext('HotRunner sets asset directory when first evict assets', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      setAssetBundlePath,
      evict,
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'asset'};

    expect(flutterDevice.devFS!.hasSetAssetDirectory, isFalse);
    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, isTrue);
    expect(fakeVmServiceHost!.hasRemainingExpectations, isFalse);
  }));

  testUsingContext('HotRunner sets asset directory when first evict shaders', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      setAssetBundlePath,
      evictShader,
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    (flutterDevice.devFS! as FakeDevFS).shaderPathsToEvict = <String>{'foo.frag'};

    expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, true);
    expect(fakeVmServiceHost!.hasRemainingExpectations, false);
  }));

  testUsingContext('HotRunner does not sets asset directory when no assets to evict', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
    expect(fakeVmServiceHost!.hasRemainingExpectations, false);
  }));

  testUsingContext('HotRunner does not set asset directory if it has been set before', () => testbed.run(() async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      listViews,
      evict,
    ]);
    residentRunner = HotRunner(
      <FlutterDevice>[
        flutterDevice,
      ],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      devtoolsHandler: createNoOpHandler,
    );

    (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'asset'};
    flutterDevice.devFS!.hasSetAssetDirectory = true;

    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, true);
    expect(fakeVmServiceHost!.hasRemainingExpectations, false);
  }));

  testUsingContext(
      'native assets',
      () => testbed.run(() async {
        final FileSystem fileSystem = globals.fs;
        final Environment environment = Environment.test(
          fileSystem.currentDirectory,
          inputs: <String, String>{},
          artifacts: Artifacts.test(),
          processManager: FakeProcessManager.empty(),
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
        );
        final Uri projectUri = environment.projectDir.uri;

        final FakeDevice device = FakeDevice(
          targetPlatform: TargetPlatform.darwin,
          sdkNameAndVersion: 'Macos',
        );
        final FakeFlutterDevice flutterDevice = FakeFlutterDevice()
          ..testUri = testUri
          ..vmServiceHost = (() => fakeVmServiceHost)
          ..device = device
          .._devFS = devFS
          ..targetPlatform = TargetPlatform.darwin;

        fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
          listViews,
          listViews,
        ]);
        globals.fs
            .file(globals.fs.path.join('lib', 'main.dart'))
            .createSync(recursive: true);
        final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <Package>[
            Package('bar', projectUri),
          ],
          dryRunResult: FakeNativeAssetsBuilderResult(
            assets: <Asset>[
              Asset(
                id: 'package:bar/bar.dart',
                linkMode: LinkMode.dynamic,
                target: native_assets_cli.Target.macOSArm64,
                path: AssetAbsolutePath(Uri.file('bar.dylib')),
              ),
            ],
          ),
        );
        residentRunner = HotRunner(
          <FlutterDevice>[
            flutterDevice,
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
          buildRunner: buildRunner,
        );

        final int? result = await residentRunner.run();
        expect(result, 0);

        expect(buildRunner.buildInvocations, 0);
        expect(buildRunner.dryRunInvocations, 1);
        expect(buildRunner.hasPackageConfigInvocations, 1);
        expect(buildRunner.packagesWithNativeAssetsInvocations, 1);
      }),
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
      });
}

// This implements [dds.DartDevelopmentService], not the [DartDevelopmentService]
// interface from package:flutter_tools.
class FakeDartDevelopmentService extends Fake implements dds.DartDevelopmentService {
  @override
  Future<void> get done => Future<void>.value();

  @override
  Uri? get uri => null;
}

class FakeDartDevelopmentServiceException implements dds.DartDevelopmentServiceException {
  FakeDartDevelopmentServiceException({this.message = defaultMessage});

  @override
  final int errorCode = dds.DartDevelopmentServiceException.existingDdsInstanceError;

  @override
  final String message;
  static const String defaultMessage = 'A DDS instance is already connected at http://localhost:8181';
}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice(super.device, { Stream<Uri>? vmServiceUris })
    : _vmServiceUris = vmServiceUris, super(buildInfo: BuildInfo.debug, developmentShaderCompiler: const FakeShaderCompiler());

  final Stream<Uri>? _vmServiceUris;

  @override
  Stream<Uri> get vmServiceUris => _vmServiceUris!;
}

class ThrowingForwardingFileSystem extends ForwardingFileSystem {
  ThrowingForwardingFileSystem(super.delegate);

  @override
  File file(dynamic path) {
    if (path == 'foo') {
      throw const FileSystemException();
    }
    return delegate.file(path);
  }
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  FakeVmServiceHost? Function()? vmServiceHost;
  Uri? testUri;
  UpdateFSReport report = UpdateFSReport(
    success: true,
    invalidatedSourcesCount: 1,
  );
  Exception? reportError;
  Exception? runColdError;
  int runHotCode = 0;
  int runColdCode = 0;

  @override
  ResidentCompiler? generator;

  @override
  DevelopmentShaderCompiler get developmentShaderCompiler => const FakeShaderCompiler();

  @override
  TargetPlatform targetPlatform = TargetPlatform.android;

  @override
  Stream<Uri?> get vmServiceUris => Stream<Uri?>.value(testUri);

  @override
  FlutterVmService? get vmService => vmServiceHost?.call()?.vmService;

  DevFS? _devFS;

  @override
  DevFS? get devFS => _devFS;

  @override
  set devFS(DevFS? value) { }

  @override
  Device? device;

  @override
  Future<void> stopEchoingDeviceLog() async { }

  @override
  Future<void> initLogReader() async { }

  @override
  Future<Uri> setupDevFS(String fsName, Directory rootDirectory) async {
    return testUri!;
  }

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    return runHotCode;
  }

  @override
  Future<int> runCold({required ColdRunner coldRunner, String? route}) async {
    if (runColdError != null) {
      throw runColdError!;
    }
    return runColdCode;
  }

  @override
  Future<void> connect({
    ReloadSources? reloadSources,
    Restart? restart,
    CompileExpression? compileExpression,
    GetSkSLMethod? getSkSLMethod,
    FlutterProject? flutterProject,
    PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
    int? hostVmServicePort,
    int? ddsPort,
    bool disableServiceAuthCodes = false,
    bool enableDds = true,
    bool cacheStartupProfile = false,
    required bool allowExistingDdsInstance,
    bool ipv6 = false,
  }) async { }

  @override
  Future<UpdateFSReport> updateDevFS({
    required Uri mainUri,
    String? target,
    AssetBundle? bundle,
    DateTime? firstBuildTime,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String? projectRootPath,
    required String pathToReload,
    required String dillOutputPath,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
  }) async {
    if (reportError != null) {
      throw reportError!;
    }
    return report;
  }

  @override
  Future<void> updateReloadStatus(bool wasReloadSuccessful) async { }
}

class FakeDelegateFlutterDevice extends FlutterDevice {
  FakeDelegateFlutterDevice(
    super.device,
    BuildInfo buildInfo,
    ResidentCompiler residentCompiler,
    this.fakeDevFS,
  ) : super(buildInfo: buildInfo, generator: residentCompiler, developmentShaderCompiler: const FakeShaderCompiler());

  @override
  Future<void> connect({
    ReloadSources? reloadSources,
    Restart? restart,
    bool enableDds = true,
    bool cacheStartupProfile = false,
    bool disableServiceAuthCodes = false,
    bool ipv6 = false,
    CompileExpression? compileExpression,
    GetSkSLMethod? getSkSLMethod,
    FlutterProject? flutterProject,
    int? hostVmServicePort,
    int? ddsPort,
    PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
    bool allowExistingDdsInstance = false,
  }) async { }


  final DevFS fakeDevFS;

  @override
  DevFS? get devFS => fakeDevFS;

  @override
  set devFS(DevFS? value) {}
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  CompilerOutput? nextOutput;
  bool didSuppressErrors = false;

  @override
  Future<CompilerOutput?> recompile(
    Uri mainUri,
    List<Uri>? invalidatedFiles, {
    required String outputPath,
    required PackageConfig packageConfig,
    String? projectRootPath,
    required FileSystem fs,
    bool suppressErrors = false,
    bool checkDartPluginRegistry = false,
    File? dartPluginRegistrant,
    Uri? nativeAssetsYaml,
  }) async {
    didSuppressErrors = suppressErrors;
    return nextOutput ?? const CompilerOutput('foo.dill', 0, <Uri>[]);
  }

  @override
  void accept() { }

  @override
  void reset() { }
}

class FakeProjectFileInvalidator extends Fake implements ProjectFileInvalidator {
  @override
  Future<InvalidationResult> findInvalidated({
    required DateTime? lastCompiled,
    required List<Uri> urisToMonitor,
    required String packagesPath,
    required PackageConfig packageConfig,
    bool asyncScanning = false,
  }) async {
    return InvalidationResult(
      packageConfig: packageConfig,
      uris: <Uri>[Uri.parse('file:///hello_world/main.dart'),
    ]);
  }
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
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
  late DartDevelopmentService dds;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
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
    ApplicationPackage? app,
    bool includePastLogs = false,
  }) => NoOpDeviceLogReader(name);

  @override
  DevicePortForwarder portForwarder = const NoOpDevicePortForwarder();
}

class FakeDevFS extends Fake implements DevFS {
  @override
  DateTime? lastCompiled = DateTime(2000);

  @override
  PackageConfig? lastPackageConfig = PackageConfig.empty;

  @override
  List<Uri> sources = <Uri>[];

  @override
  Uri baseUri = Uri();

  @override
  Future<void> destroy() async { }

  @override
  Set<String> assetPathsToEvict = <String>{};

  @override
  Set<String> shaderPathsToEvict = <String>{};

  @override
  Set<String> scenePathsToEvict = <String>{};

  @override
  bool didUpdateFontManifest = false;

  UpdateFSReport nextUpdateReport = UpdateFSReport(success: true);

  @override
  bool hasSetAssetDirectory = false;

  @override
  Future<Uri> create() async {
    return Uri();
  }

  @override
  void resetLastCompiled() {
    lastCompiled = null;
  }

  @override
  Future<UpdateFSReport> update({
    required Uri mainUri,
    required ResidentCompiler generator,
    required bool trackWidgetCreation,
    required String pathToReload,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
    required String dillOutputPath,
    required DevelopmentShaderCompiler shaderCompiler,
    DevelopmentSceneImporter? sceneImporter,
    DevFSWriter? devFSWriter,
    String? target,
    AssetBundle? bundle,
    DateTime? firstBuildTime,
    bool bundleFirstUpload = false,
    bool fullRestart = false,
    String? projectRootPath,
    File? dartPluginRegistrant,
  }) async {
    return nextUpdateReport;
  }
}

class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler();

  @override
  void configureCompiler(
    TargetPlatform? platform, {
    required ImpellerStatus impellerStatus,
  }) { }

  @override
  Future<DevFSContent> recompileShader(DevFSContent inputShader) {
    throw UnimplementedError();
  }
}
