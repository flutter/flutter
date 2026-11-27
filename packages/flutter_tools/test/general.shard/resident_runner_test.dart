// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/command_help.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart';
import '../src/package_config.dart';
import '../src/test_build_system.dart';
import 'resident_runner_helpers.dart';

void main() {
  late BufferLogger logger;
  late FakeToolContext toolContext;
  late Config config;
  late FileSystem fs;
  late FakeFlutterDevice flutterDevice;
  late FakeDevFS devFS;
  late ResidentRunner residentRunner;
  late FakeDevice device;
  late FakeAnalytics fakeAnalytics;
  FakeVmServiceHost? fakeVmServiceHost;

  setUp(() {
    config = Config.test();
    fs = MemoryFileSystem.test();
    logger = BufferLogger.test();
    toolContext = FakeToolContext(config: config, fs: fs, logger: logger);
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fakeFlutterVersion: FakeFlutterVersion(),
      fs: MemoryFileSystem.test(),
    );
    device = FakeDevice();
    devFS = FakeDevFS();
    flutterDevice = FakeFlutterDevice()
      ..testUri = testUri
      ..vmServiceHost = (() => fakeVmServiceHost)
      ..device = device
      ..fakeDevFS = devFS;
    fs.file(fs.path.join('build', 'app.dill'))
      ..createSync(recursive: true)
      ..writeAsStringSync('ABC');
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
  });

  test('ResidentRunner can attach to device successfully', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    final Future<int?> result = residentRunner.attach(
      appStartedCompleter: futureAppStart,
      connectionInfoCompleter: futureConnectionInfo,
    );
    final Future<DebugConnectionInfo> connectionInfo = futureConnectionInfo.future;

    expect(await result, 0);
    expect(futureConnectionInfo.isCompleted, true);
    expect((await connectionInfo).baseUri, 'foo://bar');
    expect(futureAppStart.isCompleted, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner reports whether detach() was used', () async {
    expect(residentRunner.stopAppDuringCleanup, true);
    await residentRunner.detach();
    expect(residentRunner.stopAppDuringCleanup, false);
  });

  test('ResidentRunner suppresses errors for the initial compilation', () async {
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
    final residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 0, <Uri>[]);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    flutterDevice.generator = residentCompiler;

    expect(await residentRunner.run(), 0);
    expect(residentCompiler.didSuppressErrors, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  test('ResidentRunner calls appFailedToStart if initial compilation fails', () async {
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 1, <Uri>[]);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    flutterDevice.generator = residentCompiler;

    expect(await residentRunner.run(), 1);
    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  test('ResidentRunner calls appFailedToStart if initial compilation fails - cold mode', () async {
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = createColdRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      target: 'main.dart',
      toolContext: toolContext,
    );
    flutterDevice.runColdCode = 1;

    expect(await residentRunner.run(), 1);
    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  test('ResidentRunner calls appFailedToStart if exception is thrown - cold mode', () async {
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = createColdRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      target: 'main.dart',
      toolContext: toolContext,
    );
    flutterDevice.runColdError = Exception('BAD STUFF');

    expect(await residentRunner.run(), 1);
    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  });

  test('ResidentRunner does not suppressErrors if running with an applicationBinary', () async {
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
    final residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 0, <Uri>[]);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      applicationBinary: fs.file('app-debug.apk'),
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    flutterDevice.generator = residentCompiler;

    expect(await residentRunner.run(), 0);
    expect(residentCompiler.didSuppressErrors, false);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner can handle an RPC exception from hot reload', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews, listViews],
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.reportError = vm_service.RPCError('something bad happened', 666, '');

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, true);
    expect(result.code, 1);
    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.hotRunnerInfo(
          label: 'exception',
          targetPlatform: TargetPlatform.android_arm.getName(),
          sdkName: 'Android',
          emulator: false,
          fullRestart: false,
        ),
      ),
    );
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner fails its operation if the device initialization is not complete', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.fakeDevFS = null;

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, false);
    expect(result.code, 1);
    expect(result.message, contains('Device initialization has not completed.'));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner can handle an reload-barred exception from hot reload', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews, listViews],
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.reportError = vm_service.RPCError(
      'something bad happened',
      kIsolateReloadBarred,
      '',
    );

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, true);
    expect(result.code, kIsolateReloadBarred);
    expect(
      result.message,
      contains('Unable to hot reload application due to an unrecoverable error'),
    );

    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.hotRunnerInfo(
          label: 'reload-barred',
          targetPlatform: TargetPlatform.android_arm.getName(),
          sdkName: 'Android',
          emulator: false,
          fullRestart: false,
        ),
      ),
    );
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner reports hot reload event with null safety analytics', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews, listViews],
    );
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      target: 'main.dart',
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          extraFrontEndOptions: <String>['--enable-experiment=non-nullable'],
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        enableDevTools: false,
      ),
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.reportError = vm_service.RPCError('something bad happened', 666, '');

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, true);
    expect(result.code, 1);

    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.hotRunnerInfo(
          label: 'exception',
          targetPlatform: TargetPlatform.android_arm.getName(),
          sdkName: 'Android',
          emulator: false,
          fullRestart: false,
        ),
      ),
    );
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner does not reload sources if no sources changed', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        listViews,
        listViews,
        FakeVmServiceRequest(
          method: 'getIsolatePauseEvent',
          args: <String, Object>{'isolateId': '1'},
          jsonResponse: fakeUnpausedEvent.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'ext.flutter.reassemble',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
        ),
      ],
    );
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.report = UpdateFSReport(success: true);

    final OperationResult result = await residentRunner.restart();

    expect(result.code, 0);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner reports error with missing entrypoint file', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        listViews,
        listViews,
        getVm([fakeUnpausedIsolate]),
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
            'details': <String, Object>{'loadedLibraryCount': 1},
          },
        ),
        FakeVmServiceRequest(
          method: 'getIsolatePauseEvent',
          args: <String, Object>{'isolateId': '1'},
          jsonResponse: fakeUnpausedEvent.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'ext.flutter.reassemble',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
        ),
      ],
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.report = UpdateFSReport(success: true, invalidatedSourcesCount: 1);

    final OperationResult result = await residentRunner.restart();

    expect(fs.file(fs.path.join('lib', 'main.dart')), isNot(exists));
    expect(logger.errorText, contains('The entrypoint file (i.e. the file with main())'));
    expect(result.fatal, false);
    expect(result.code, 0);
  });

  test('ResidentRunner resets compilation time on reload reject', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        listViews,
        listViews,
        getVm([fakeUnpausedIsolate]),
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
              <String, Object>{'message': 'Failed to hot reload'},
            ],
            'details': <String, Object>{},
          },
        ),
        listViews,
        FakeVmServiceRequest(
          method: 'getIsolate',
          args: <String, Object>{'isolateId': '1'},
          jsonResponse: fakeUnpausedIsolate.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'ext.flutter.reassemble',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
        ),
      ],
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.report = UpdateFSReport(success: true, invalidatedSourcesCount: 1);

    final OperationResult result = await residentRunner.restart();

    expect(result.fatal, false);
    expect(
      result.message,
      contains('Reload rejected: Failed to hot reload'),
    ); // contains error message from reload report.
    expect(result.code, 1);
    expect(devFS.lastCompiled, null);
  });

  test('ResidentRunner can send target platform to analytics from hot reload', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        listViews,
        listViews,
        getVm([fakeUnpausedIsolate]),
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
            'details': <String, Object>{'loadedLibraryCount': 1},
          },
        ),
        FakeVmServiceRequest(
          method: 'getIsolatePauseEvent',
          args: <String, Object>{'isolateId': '1'},
          jsonResponse: fakeUnpausedEvent.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'ext.flutter.reassemble',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
        ),
      ],
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;

    final OperationResult result = await residentRunner.restart();
    expect(result.fatal, false);
    expect(result.code, 0);

    final Event event = fakeAnalytics.sentEvents.first;
    expect(event.eventName.label, 'hot_runner_info');
    expect(event.eventData['label'], 'reload');
    expect(event.eventData['targetPlatform'], TargetPlatform.android_arm.getName());
  });

  test('ResidentRunner reports hot reload time details', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        listViews,
        listViews,
        FakeVmServiceRequest(method: 'getVM', jsonResponse: fakeVM.toJson()),
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
            'details': <String, Object>{'loadedLibraryCount': 1, 'finalLibraryCount': 42},
          },
        ),
        FakeVmServiceRequest(
          method: 'getIsolatePauseEvent',
          args: <String, Object>{'isolateId': '1'},
          jsonResponse: fakeUnpausedEvent.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'ext.flutter.reassemble',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
        ),
      ],
    );
    final flutterDevice = FakeDelegateFlutterDevice(
      device,
      BuildInfo.debug,
      FakeResidentCompiler(),
      devFS,
    )..vmService = fakeVmServiceHost!.vmService;
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      projectFileInvalidator: FakeProjectFileInvalidator(),
      toolContext: toolContext,
    );
    devFS.nextUpdateReport = UpdateFSReport(success: true, invalidatedSourcesCount: 1);

    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );

    await futureAppStart.future;
    await residentRunner.restart();

    // The actual test: Expect to have compile, reload and reassemble times.
    expect(
      logger.statusText,
      contains(
        RegExp(
          r'Reloaded 1 of 42 libraries in \d+ms '
          r'\(compile: \d+ ms, reload: \d+ ms, reassemble: \d+ ms\)\.',
        ),
      ),
    );
  });

  test('ResidentRunner can send target platform to analytics from full restart', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        listViews,
        listViews,
        FakeVmServiceRequest(
          method: 'getIsolate',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
          jsonResponse: fakeUnpausedIsolate.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'setIsolatePauseMode',
          args: <String, Object?>{
            'isolateId': fakeUnpausedIsolate.id,
            'exceptionPauseMode': vm_service.ExceptionPauseMode.kNone,
          },
          jsonResponse: vm_service.Success().toJson(),
        ),
        getVm(),
        listViews,
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{'streamId': 'Isolate'},
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
          event: vm_service.Event(timestamp: 0, kind: vm_service.EventKind.kIsolateRunnable),
        ),
      ],
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );

    final OperationResult result = await residentRunner.restart(fullRestart: true);
    expect(result.fatal, false);
    expect(result.code, 0);

    expect(fakeVmServiceHost?.hasRemainingExpectations, false);

    final List<Event> hotRunnerInfoEvents = fakeAnalytics.sentEvents
        .where((Event e) => e.eventName.label == 'hot_runner_info')
        .toList();
    expect(hotRunnerInfoEvents, hasLength(1));
    final Event newEvent = hotRunnerInfoEvents.first;
    expect(newEvent.eventData['label'], 'restart');
    expect(newEvent.eventData['targetPlatform'], TargetPlatform.android_arm.getName());
  });

  test('ResidentRunner can remove breakpoints and exception-pause-mode from paused isolate during hot restart', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        listViews,
        listViews,
        FakeVmServiceRequest(
          method: 'getIsolate',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
          jsonResponse: fakePausedIsolate.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'setIsolatePauseMode',
          args: <String, Object?>{
            'isolateId': fakeUnpausedIsolate.id,
            'exceptionPauseMode': vm_service.ExceptionPauseMode.kNone,
          },
          jsonResponse: vm_service.Success().toJson(),
        ),
        FakeVmServiceRequest(
          method: 'removeBreakpoint',
          args: <String, Object?>{
            'isolateId': fakeUnpausedIsolate.id,
            'breakpointId': 'test-breakpoint',
          },
        ),
        FakeVmServiceRequest(
          method: 'resume',
          args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
        ),
        getVm(),
        listViews,
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{'streamId': 'Isolate'},
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
          event: vm_service.Event(timestamp: 0, kind: vm_service.EventKind.kIsolateRunnable),
        ),
      ],
    );
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );

    final OperationResult result = await residentRunner.restart(fullRestart: true);

    expect(result.isOk, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test(
    'ResidentRunner will alternative the name of the dill file uploaded for a hot restart',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          listViews,
          listViews,
          listViews,
          FakeVmServiceRequest(
            method: 'getIsolate',
            args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
            jsonResponse: fakeUnpausedIsolate.toJson(),
          ),
          FakeVmServiceRequest(
            method: 'setIsolatePauseMode',
            args: <String, Object?>{
              'isolateId': fakeUnpausedIsolate.id,
              'exceptionPauseMode': vm_service.ExceptionPauseMode.kNone,
            },
            jsonResponse: vm_service.Success().toJson(),
          ),
          getVm(),
          listViews,
          const FakeVmServiceRequest(
            method: 'streamListen',
            args: <String, Object>{'streamId': 'Isolate'},
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
            event: vm_service.Event(timestamp: 0, kind: vm_service.EventKind.kIsolateRunnable),
          ),
          listViews,
          FakeVmServiceRequest(
            method: 'getIsolate',
            args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
            jsonResponse: fakeUnpausedIsolate.toJson(),
          ),
          FakeVmServiceRequest(
            method: 'setIsolatePauseMode',
            args: <String, Object?>{
              'isolateId': fakeUnpausedIsolate.id,
              'exceptionPauseMode': vm_service.ExceptionPauseMode.kNone,
            },
            jsonResponse: vm_service.Success().toJson(),
          ),
          getVm(),
          listViews,
          const FakeVmServiceRequest(
            method: 'streamListen',
            args: <String, Object>{'streamId': 'Isolate'},
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
            event: vm_service.Event(timestamp: 0, kind: vm_service.EventKind.kIsolateRunnable),
          ),
          listViews,
          FakeVmServiceRequest(
            method: 'getIsolate',
            args: <String, Object?>{'isolateId': fakeUnpausedIsolate.id},
            jsonResponse: fakeUnpausedIsolate.toJson(),
          ),
          FakeVmServiceRequest(
            method: 'setIsolatePauseMode',
            args: <String, Object?>{
              'isolateId': fakeUnpausedIsolate.id,
              'exceptionPauseMode': vm_service.ExceptionPauseMode.kNone,
            },
            jsonResponse: vm_service.Success().toJson(),
          ),
          getVm(),
          listViews,
          const FakeVmServiceRequest(
            method: 'streamListen',
            args: <String, Object>{'streamId': 'Isolate'},
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
            event: vm_service.Event(timestamp: 0, kind: vm_service.EventKind.kIsolateRunnable),
          ),
        ],
      );
      final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
      final futureAppStart = Completer<void>.sync();
      unawaited(
        residentRunner.attach(
          appStartedCompleter: futureAppStart,
          connectionInfoCompleter: futureConnectionInfo,
        ),
      );

      await residentRunner.restart(fullRestart: true);
      await residentRunner.restart(fullRestart: true);
      await residentRunner.restart(fullRestart: true);

      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    },
  );

  test('ResidentRunner Can handle an RPC exception from hot restart', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
    final futureConnectionInfo = Completer<DebugConnectionInfo>.sync();
    final futureAppStart = Completer<void>.sync();
    unawaited(
      residentRunner.attach(
        appStartedCompleter: futureAppStart,
        connectionInfoCompleter: futureConnectionInfo,
      ),
    );
    await futureAppStart.future;
    flutterDevice.reportError = vm_service.RPCError('something bad happened', 666, '');

    final OperationResult result = await residentRunner.restart(fullRestart: true);
    expect(result.fatal, true);
    expect(result.code, 1);

    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.hotRunnerInfo(
          label: 'exception',
          targetPlatform: TargetPlatform.android_arm.getName(),
          sdkName: 'Android',
          emulator: false,
          fullRestart: true,
        ),
      ),
    );
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ResidentRunner uses temp directory when there is no output dill path', () {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    expect(residentRunner.artifactDirectory.path, contains('flutter_tool.'));

    final ResidentRunner otherRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      dillOutputPath: fs.path.join('foobar', 'app.dill'),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    expect(otherRunner.artifactDirectory.path, contains('foobar'));
  });

  test('ResidentRunner deletes artifact directory on preExit', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner.artifactDirectory.childFile('app.dill').createSync();
    await residentRunner.preExit();

    expect(residentRunner.artifactDirectory, isNot(exists));
  });

  test('ResidentRunner can run source generation', () async {
    final File arbFile = fs.file(fs.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fs.file('l10n.yaml').createSync();
    fs.file('pubspec.yaml').writeAsStringSync('''
name: my_app
flutter:
  generate: true''');

    // Create necessary files for [DartPluginRegistrantTarget]
    writePackageConfigFiles(
      directory: fs.currentDirectory,
      mainLibName: 'my_app',
      packages: <String, String>{'path_provider_linux': 'path_provider_linux'},
    );

    // Start from an empty dart_plugin_registrant.dart file.
    fs
        .directory('.dart_tool')
        .childDirectory('flutter_build')
        .childFile('dart_plugin_registrant.dart')
        .createSync(recursive: true);

    await residentRunner.runSourceGenerators();

    expect(logger.errorText, isEmpty);
    expect(logger.statusText, isEmpty);
  });

  test('generated main uses correct target', () async {
    final File arbFile = fs.file(fs.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fs.file('l10n.yaml').createSync();
    fs.file('pubspec.yaml').writeAsStringSync('''
name: my_app
flutter:
  generate: true

dependencies:
  flutter:
    sdk: flutter
  path_provider_linux: 1.0.0
''');

    // Create necessary files for [DartPluginRegistrantTarget], including a
    // plugin that will trigger generation.
    writePackageConfigFiles(
      directory: fs.currentDirectory,
      mainLibName: 'my_app',
      packages: <String, String>{'path_provider_linux': 'path_provider_linux'},
    );

    final Directory fakePluginDir = fs.directory('path_provider_linux');
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

    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'custom_main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    await residentRunner.runSourceGenerators();

    final File generatedMain = fs
        .directory('.dart_tool')
        .childDirectory('flutter_build')
        .childFile('dart_plugin_registrant.dart');

    expect(generatedMain.existsSync(), isTrue);
    expect(logger.errorText, isEmpty);
    expect(logger.statusText, isEmpty);
  });

  test('ResidentRunner can run source generation - generation fails', () async {
    // Intentionally define arb file with wrong name. generate_localizations defaults
    // to app_en.arb.
    final File arbFile = fs.file(fs.path.join('lib', 'l10n', 'foo.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fs.file('l10n.yaml').createSync();
    fs.file('pubspec.yaml').writeAsStringSync('flutter:\n  generate: true\n');

    await residentRunner.runSourceGenerators();

    expect(logger.errorText, contains('Error'));
    expect(logger.statusText, isEmpty);
  });

  test('ResidentRunner generates files when l10n.yaml exists', () async {
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    final File arbFile = fs.file(fs.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fs.file('l10n.yaml').createSync();
    fs.file('pubspec.yaml').writeAsStringSync('flutter:\n  generate: true\n');

    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final residentCompiler = FakeResidentCompiler()
      ..nextOutput = const CompilerOutput('foo', 1, <Uri>[]);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    flutterDevice.generator = residentCompiler;

    await residentRunner.run();

    final File generatedLocalizationsFile = fs
        .directory('lib')
        .childDirectory('l10n')
        .childFile('app_localizations.dart');
    expect(generatedLocalizationsFile, exists);

    // Completing this future ensures that the daemon can exit correctly.
    expect(await residentRunner.waitForAppToFinish(), 1);
  });

  test('ResidentRunner printHelpDetails hot runner', () {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    residentRunner.printHelp(details: true);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // supports service protocol
    expect(residentRunner.supportsServiceProtocol, true);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, true);
    // commands
    expect(
      logger.statusText,
      equals(
        <dynamic>[
          'Flutter run key commands.',
          commandHelp.r,
          commandHelp.R,
          commandHelp.s,
          commandHelp.v,
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
          commandHelp.g,
          commandHelp.hWithDetails,
          commandHelp.d,
          commandHelp.c,
          commandHelp.q,
          '',
          'A Dart VM Service on FakeDevice is available at: null',
          '',
        ].join('\n'),
      ),
    );
  });

  test('ResidentRunner printHelp hot runner', () {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

    residentRunner.printHelp(details: false);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // supports service protocol
    expect(residentRunner.supportsServiceProtocol, true);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, true);
    // commands
    expect(
      logger.statusText,
      equals(
        <dynamic>[
          'Flutter run key commands.',
          commandHelp.r,
          commandHelp.R,
          commandHelp.hWithoutDetails,
          commandHelp.d,
          commandHelp.c,
          commandHelp.q,
          '',
          'A Dart VM Service on FakeDevice is available at: null',
          '',
        ].join('\n'),
      ),
    );
  });

  test('ResidentRunner printHelpDetails cold runner', () {
    fakeVmServiceHost = null;
    residentRunner = createColdRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      toolContext: toolContext,
    );
    residentRunner.printHelp(details: true);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // does not supports service protocol
    expect(residentRunner.supportsServiceProtocol, false);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, false);
    // commands
    expect(
      logger.statusText,
      equals(
        <dynamic>[
          'Flutter run key commands.',
          commandHelp.s,
          commandHelp.hWithDetails,
          commandHelp.c,
          commandHelp.q,
          '\n',
        ].join('\n'),
      ),
    );
  });

  test('ResidentRunner printHelp cold runner', () {
    fakeVmServiceHost = null;
    residentRunner = createColdRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      target: 'main.dart',
      toolContext: toolContext,
    );
    residentRunner.printHelp(details: false);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    // does not supports service protocol
    expect(residentRunner.supportsServiceProtocol, false);
    // isRunningDebug
    expect(residentRunner.isRunningDebug, false);
    // commands
    expect(
      logger.statusText,
      equals(
        <dynamic>[
          'Flutter run key commands.',
          commandHelp.hWithoutDetails,
          commandHelp.c,
          commandHelp.q,
          '\n',
        ].join('\n'),
      ),
    );
  });

  test('ResidentRunner printHelpDetails hides v on web in profile mode', () async {
    final FlutterDevice flutterDevice = await FlutterDevice.create(
      FakeDevice(targetPlatform: TargetPlatform.web_javascript),
      toolContext: FakeToolContext(artifacts: Artifacts.test()),
      buildInfo: BuildInfo.profile,
      target: 'lib/main.dart',
    );

    final ResidentRunner residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.profile),
      target: 'lib/main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    residentRunner.printHelp(details: true);

    final CommandHelp commandHelp = residentRunner.commandHelp;

    expect(residentRunner.isRunningDebug, false);
    expect(logger.statusText, isNot(contains(commandHelp.v)));
  });

  test(
    'ResidentRunner ignores DevtoolsLauncher when attaching with enableDevTools: false - cold mode',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
      residentRunner = createColdRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.profile,
          vmserviceOutFile: 'foo',
          enableDevTools: false,
        ),
        target: 'main.dart',
        toolContext: toolContext,
      );

      final Future<int?> result = residentRunner.attach();
      expect(await result, 0);
    },
  );

  test('FlutterDevice can exit from a release mode isolate with no VmService', () async {
    final flutterDevice = TestFlutterDevice(device);

    await flutterDevice.exitApps();

    expect(device.appStopped, true);
  });

  test('FlutterDevice will exit an un-paused isolate using stopApp', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final flutterDevice = TestFlutterDevice(device);
    flutterDevice.vmService = fakeVmServiceHost!.vmService;

    final Future<void> exitFuture = flutterDevice.exitApps();

    await expectLater(exitFuture, completes);
    expect(device.appStopped, true);
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('HotRunner writes vm service file when providing debugging option', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews],
      wsAddress: testUri,
    );
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    await residentRunner.run();

    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    expect(await fs.file('foo').readAsString(), testUri.toString());
  });

  test('HotRunner copies compiled app.dill to cache during startup', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews],
      wsAddress: testUri,
    );
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          null,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run();

    final String expectedPath = getDefaultCachedKernelPath(
      fileSystem: fs,
      trackWidgetCreation: residentRunner.trackWidgetCreation,
      dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
      extraFrontEndOptions: residentRunner.debuggingOptions.buildInfo.extraFrontEndOptions,
      config: config,
      targetModel: TargetModel.fromTargetPlatform(flutterDevice.targetPlatform),
    );
    expect(await fs.file(expectedPath).readAsString(), 'ABC');
  });

  test('HotRunner copies compiled app.dill to cache during startup with dart defines', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews],
      wsAddress: testUri,
    );
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          dartDefines: <String>['a', 'b'],
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run();

    final String expectedPath = getDefaultCachedKernelPath(
      fileSystem: fs,
      trackWidgetCreation: residentRunner.trackWidgetCreation,
      dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
      extraFrontEndOptions: residentRunner.debuggingOptions.buildInfo.extraFrontEndOptions,
      config: config,
      targetModel: TargetModel.fromTargetPlatform(flutterDevice.targetPlatform),
    );
    expect(await fs.file(expectedPath).readAsString(), 'ABC');
  });

  test('HotRunner copies compiled app.dill to cache during startup with null safety', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews],
      wsAddress: testUri,
    );
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          extraFrontEndOptions: <String>['--enable-experiment=non-nullable'],
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run();

    final String expectedPath = getDefaultCachedKernelPath(
      fileSystem: fs,
      trackWidgetCreation: residentRunner.trackWidgetCreation,
      dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
      extraFrontEndOptions: residentRunner.debuggingOptions.buildInfo.extraFrontEndOptions,
      config: config,
      targetModel: TargetModel.fromTargetPlatform(flutterDevice.targetPlatform),
    );
    expect(await fs.file(expectedPath).readAsString(), 'ABC');
  });

  test(
    'HotRunner copies compiled app.dill to cache during startup with track-widget-creation',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = createHotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
        toolContext: toolContext,
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      final String expectedPath = getDefaultCachedKernelPath(
        fileSystem: fs,
        trackWidgetCreation: residentRunner.trackWidgetCreation,
        dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
        extraFrontEndOptions: residentRunner.debuggingOptions.buildInfo.extraFrontEndOptions,
        config: config,
        targetModel: TargetModel.fromTargetPlatform(flutterDevice.targetPlatform),
      );
      expect(await fs.file(expectedPath).readAsString(), 'ABC');
    },
  );

  test('HotRunner does not copy app.dill if a dillOutputPath is given', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews],
      wsAddress: testUri,
    );
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      dillOutputPath: 'test',
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );
    residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

    await residentRunner.run();

    expect(fs.file(fs.path.join('build', 'cache.dill')), isNot(exists));
  });

  test(
    'HotRunner copies compiled app.dill to cache during startup with --track-widget-creation',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = createHotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(
            BuildMode.debug,
            '',
            treeShakeIcons: false,
            trackWidgetCreation: true,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        target: 'main.dart',
        analytics: fakeAnalytics,
        toolContext: toolContext,
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      final String expectedPath = getDefaultCachedKernelPath(
        fileSystem: fs,
        trackWidgetCreation: residentRunner.trackWidgetCreation,
        dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
        extraFrontEndOptions: residentRunner.debuggingOptions.buildInfo.extraFrontEndOptions,
        config: config,
        targetModel: TargetModel.fromTargetPlatform(flutterDevice.targetPlatform),
      );
      expect(await fs.file(expectedPath).readAsString(), 'ABC');
    },
  );

  test('HotRunner calls device dispose', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, listViews],
      wsAddress: testUri,
    );
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    await residentRunner.run();
    expect(device.disposed, true);
  });

  test('HotRunner handles failure to write vmservice file', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: FakeToolContext(
        config: config,
        fs: ThrowingForwardingFileSystem(fs),
        logger: logger,
      ),
    );

    await residentRunner.run();

    expect(logger.errorText, contains('Failed to write vmservice-out-file at foo'));
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('ColdRunner writes vm service file when providing debugging option', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews],
      wsAddress: testUri,
    );
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createColdRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile, vmserviceOutFile: 'foo'),
      target: 'main.dart',
      toolContext: toolContext,
    );

    await residentRunner.run();

    expect(await fs.file('foo').readAsString(), testUri.toString());
    expect(fakeVmServiceHost?.hasRemainingExpectations, false);
  });

  test('FlutterDevice uses dartdevc configuration when targeting web', () async {
    final artifacts = Artifacts.test();
    final toolContext = FakeToolContext(
      artifacts: artifacts,
      config: config,
      fs: fs,
      processManager: FakeProcessManager.any(),
    );
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final device = FakeDevice(targetPlatform: TargetPlatform.web_javascript);
    final residentCompiler =
        (await FlutterDevice.create(
              device,
              toolContext: toolContext,
              buildInfo: const BuildInfo(
                BuildMode.debug,
                '',
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
              target: null,
            )).generator
            as DefaultResidentCompiler?;

    final String expectedPath = getDefaultCachedKernelPath(
      fileSystem: fs,
      trackWidgetCreation: false,
      dartDefines: const <String>[],
      config: config,
      targetModel: TargetModel.dartdevc,
      extraFrontEndOptions: kDdcLibraryBundleFlags,
    );
    expect(residentCompiler!.initializeFromDill, expectedPath);
    expect(
      residentCompiler.librariesSpec,
      fs.file(artifacts.getHostArtifact(HostArtifact.flutterWebLibrariesJson)).uri.toString(),
    );
    expect(residentCompiler.targetModel, TargetModel.dartdevc);
    expect(
      residentCompiler.sdkRoot,
      '${artifacts.getHostArtifact(HostArtifact.flutterWebSdk).path}/',
    );
    expect(
      residentCompiler.platformDill,
      'file:///HostArtifact.webPlatformKernelFolder/ddc_outline.dill',
    );
  });

  test('FlutterDevice passes alternative-invalidation-strategy flag', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final device = FakeDevice();

    final residentCompiler =
        (await FlutterDevice.create(
              device,
              toolContext: FakeToolContext(),
              buildInfo: const BuildInfo(
                BuildMode.debug,
                '',
                treeShakeIcons: false,
                extraFrontEndOptions: <String>[],
                packageConfigPath: '.dart_tool/package_config.json',
              ),
              target: null,
            )).generator
            as DefaultResidentCompiler?;

    expect(
      residentCompiler!.extraFrontEndOptions,
      contains('--enable-experiment=alternative-invalidation-strategy'),
    );
  });

  test('FlutterDevice passes initializeFromDill parameter if specified', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final device = FakeDevice();

    final residentCompiler =
        (await FlutterDevice.create(
              device,
              toolContext: FakeToolContext(),
              buildInfo: const BuildInfo(
                BuildMode.debug,
                '',
                treeShakeIcons: false,
                extraFrontEndOptions: <String>[],
                initializeFromDill: '/foo/bar.dill',
                packageConfigPath: '.dart_tool/package_config.json',
              ),
              target: null,
            )).generator
            as DefaultResidentCompiler?;

    expect(residentCompiler!.initializeFromDill, '/foo/bar.dill');
    expect(residentCompiler.assumeInitializeFromDillUpToDate, false);
  });

  test('FlutterDevice passes assumeInitializeFromDillUpToDate parameter if specified', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final device = FakeDevice();

    final residentCompiler =
        (await FlutterDevice.create(
              device,
              toolContext: FakeToolContext(),
              buildInfo: const BuildInfo(
                BuildMode.debug,
                '',
                treeShakeIcons: false,
                extraFrontEndOptions: <String>[],
                assumeInitializeFromDillUpToDate: true,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
              target: null,
            )).generator
            as DefaultResidentCompiler?;

    expect(residentCompiler!.assumeInitializeFromDillUpToDate, true);
  });

  test('FlutterDevice passes frontendServerStarterPath parameter if specified', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final device = FakeDevice();

    final residentCompiler =
        (await FlutterDevice.create(
              device,
              toolContext: FakeToolContext(),
              buildInfo: const BuildInfo(
                BuildMode.debug,
                '',
                treeShakeIcons: false,
                frontendServerStarterPath: '/foo/bar/frontend_server_starter.dart',
                packageConfigPath: '.dart_tool/package_config.json',
              ),
              target: null,
            )).generator
            as DefaultResidentCompiler?;

    expect(residentCompiler!.frontendServerStarterPath, '/foo/bar/frontend_server_starter.dart');
  });

  test('Uses existing DDS URI from exception field', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    final device = FakeDevice()..dds = DartDevelopmentService(logger: logger);
    ddsLauncherCallback =
        ({
          required Uri remoteVmServiceUri,
          String? appName = 'Fake App',
          Uri? serviceUri,
          bool enableAuthCodes = true,
          bool serveDevTools = false,
          Uri? devToolsServerAddress,
          bool enableServicePortFallback = false,
          List<String> cachedUserTags = const <String>[],
          String? dartExecutable,
          String? google3WorkspaceRoot,
        }) {
          throw DartDevelopmentServiceException.existingDdsInstance(
            'Existing DDS at http://localhost/existingDdsInMessage.',
            ddsUri: Uri.parse('http://localhost/existingDdsInField'),
          );
        };
    final flutterDevice = FlutterDevice(
      device,
      toolContext: FakeToolContext(artifacts: Artifacts.test()),
      generator: FakeResidentCompiler(),
      targetPlatform: .unsupported,
      buildInfo: BuildInfo.debug,
      developmentShaderCompiler: const FakeShaderCompiler(),
      vmServiceConnector: (
        Uri httpUri, {
        ReloadSources? reloadSources,
        Restart? restart,
        CompileExpression? compileExpression,
        FlutterProject? flutterProject,
        FlutterVersion? flutterVersion,
        PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
        io.CompressionOptions compression = io.CompressionOptions.compressionDefault,
        Device? device,
        required Logger logger,
      }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
    )..vmServiceUri = Future<Uri>.value(testUri);
    final done = Completer<void>();
    unawaited(
      runZonedGuarded(
        () => flutterDevice
            .connect(
              vmServiceUri: testUri,
              debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
            )
            .then((_) => done.complete()),
        (_, _) => done.complete(),
      ),
    );
    await done.future;
    expect(device.dds.uri, Uri.parse('http://localhost/existingDdsInField'));
  });

  test('Host VM service ipv6 defaults', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{'streamId': 'Isolate'},
        ),
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{'streamId': 'Isolate'},
        ),
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{'streamId': 'Isolate'},
        ),
      ],
    );
    final device = FakeDevice()..dds = DartDevelopmentService(logger: logger);
    final done = Completer<void>();
    ddsLauncherCallback =
        ({
          required Uri remoteVmServiceUri,
          String? appName = 'Fake App',
          Uri? serviceUri,
          bool enableAuthCodes = true,
          bool serveDevTools = false,
          Uri? devToolsServerAddress,
          bool enableServicePortFallback = false,
          List<String> cachedUserTags = const <String>[],
          String? dartExecutable,
          String? google3WorkspaceRoot,
        }) async {
          expect(remoteVmServiceUri, Uri(scheme: 'foo', host: 'bar'));
          expect(appName, contains('Kind: Flutter'));
          expect(appName, contains('Device: FakeDevice'));
          expect(enableAuthCodes, isFalse);
          expect(serviceUri, Uri(scheme: 'http', host: '::1', port: 0));
          expect(cachedUserTags, isEmpty);
          done.complete();
          return FakeDartDevelopmentServiceLauncher(uri: remoteVmServiceUri);
        };
    final flutterDevice = FlutterDevice(
      device,
      toolContext: FakeToolContext(artifacts: Artifacts.test()),
      generator: FakeResidentCompiler(),
      targetPlatform: .unsupported,
      buildInfo: BuildInfo.debug,
      developmentShaderCompiler: const FakeShaderCompiler(),
      vmServiceConnector: (
        Uri httpUri, {
        ReloadSources? reloadSources,
        Restart? restart,
        CompileExpression? compileExpression,
        FlutterProject? flutterProject,
        FlutterVersion? flutterVersion,
        PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
        io.CompressionOptions compression = io.CompressionOptions.compressionDefault,
        Device? device,
        required Logger logger,
      }) async => fakeVmServiceHost!.vmService,
    )..vmServiceUri = Future<Uri>.value(testUri);
    await flutterDevice.connect(
      vmServiceUri: testUri,
      debuggingOptions: DebuggingOptions.enabled(
        BuildInfo.debug,
        disableServiceAuthCodes: true,
        ipv6: true,
      ),
    );
    await done.future;
  });

  test('nextPlatform moves through expected platforms', () {
    expect(nextPlatform('android'), 'iOS');
    expect(nextPlatform('iOS'), 'windows');
    expect(nextPlatform('windows'), 'macOS');
    expect(nextPlatform('macOS'), 'linux');
    expect(nextPlatform('linux'), 'fuchsia');
    expect(nextPlatform('fuchsia'), 'android');
    expect(() => nextPlatform('unknown'), throwsAssertionError);
  });

  test('HotRunner sets asset directory when first evict assets', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, setAssetBundlePath, evict],
    );
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'asset'};

    expect(flutterDevice.devFS!.hasSetAssetDirectory, isFalse);
    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, isTrue);
    expect(fakeVmServiceHost!.hasRemainingExpectations, isFalse);
  });

  test('HotRunner sets asset directory when first evict shaders', () async {
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listViews, setAssetBundlePath, evictShader],
    );
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    (flutterDevice.devFS! as FakeDevFS).shaderPathsToEvict = <String>{'foo.frag'};

    expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, true);
    expect(fakeVmServiceHost!.hasRemainingExpectations, false);
  });

  test(
    'HotRunner reinitializes Flutter GPU shader libraries for changed .shaderbundle assets',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, setAssetBundlePath, reinitializeShaderLibrary],
      );
      residentRunner = createHotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
        toolContext: toolContext,
      );

      // A `.shaderbundle` asset reloads the compiled Flutter GPU ShaderLibrary
      // instead of going through the generic asset eviction.
      (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'foo.shaderbundle'};

      await (residentRunner as HotRunner).evictDirtyAssets();
      expect(fakeVmServiceHost!.hasRemainingExpectations, false);
    },
  );

  test('HotRunner evicts a changed .shaderbundle asset generically on web', () async {
    final webFlutterDevice = FakeFlutterDevice()
      ..vmServiceHost = (() => fakeVmServiceHost)
      ..fakeDevFS = devFS
      ..targetPlatform = TargetPlatform.web_javascript;
    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[
        listViews,
        setAssetBundlePath,
        const FakeVmServiceRequest(
          method: 'ext.flutter.evict',
          args: <String, Object>{'value': 'foo.shaderbundle', 'isolateId': '1'},
        ),
      ],
    );
    residentRunner = createHotRunner(
      <FlutterDevice>[webFlutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    // The Flutter GPU reload extension is unavailable on web, so the bundle
    // falls back to the generic asset eviction.
    (webFlutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'foo.shaderbundle'};

    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(fakeVmServiceHost!.hasRemainingExpectations, false);
  });

  test('HotRunner does not sets asset directory when no assets to evict', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
    expect(fakeVmServiceHost!.hasRemainingExpectations, false);
  });

  test('HotRunner does not set asset directory if it has been set before', () async {
    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, evict]);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'asset'};
    flutterDevice.devFS!.hasSetAssetDirectory = true;

    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, true);
    expect(fakeVmServiceHost!.hasRemainingExpectations, false);
  });

  test('HotRunner evictDirtyAssets correctly finds UI isolate and view ID when multiple views are present and the first view has no isolate', () async {
    final viewWithoutIsolate = FlutterView(id: 'view_empty', uiIsolate: null);
    final viewWithIsolate = FlutterView(id: 'view_active', uiIsolate: fakeUnpausedIsolate);

    final listMultipleViews = FakeVmServiceRequest(
      method: kListViewsMethod,
      jsonResponse: <String, Object>{
        'views': <Object>[viewWithoutIsolate.toJson(), viewWithIsolate.toJson()],
      },
    );

    const setAssetBundlePathForActiveView = FakeVmServiceRequest(
      method: '_flutter.setAssetBundlePath',
      args: <String, Object>{
        'viewId': 'view_active',
        'assetDirectory': 'build/flutter_assets',
        'isolateId': '1',
      },
    );

    fakeVmServiceHost = FakeVmServiceHost(
      requests: <VmServiceExpectation>[listMultipleViews, setAssetBundlePathForActiveView, evict],
    );
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      target: 'main.dart',
      analytics: fakeAnalytics,
      toolContext: toolContext,
    );

    (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'asset'};

    expect(flutterDevice.devFS!.hasSetAssetDirectory, isFalse);
    await (residentRunner as HotRunner).evictDirtyAssets();
    expect(flutterDevice.devFS!.hasSetAssetDirectory, isTrue);
    expect(fakeVmServiceHost!.hasRemainingExpectations, isFalse);
  });

  test('use the nativeAssetsYamlFile when provided', () async {
    final device = FakeDevice(targetPlatform: TargetPlatform.darwin, sdkNameAndVersion: 'Macos');
    final residentCompiler = FakeResidentCompiler();
    final flutterDevice = FakeFlutterDevice()
      ..testUri = testUri
      ..vmServiceHost = (() => fakeVmServiceHost)
      ..device = device
      ..fakeDevFS = devFS
      ..targetPlatform = TargetPlatform.darwin
      ..generator = residentCompiler;

    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    residentRunner = createHotRunner(
      <FlutterDevice>[flutterDevice],
      stayResident: false,
      debuggingOptions: DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          '',
          treeShakeIcons: false,
          trackWidgetCreation: true,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      ),
      target: 'main.dart',
      analytics: fakeAnalytics,
      nativeAssetsYamlFile: 'foo.yaml',
      toolContext: toolContext,
    );

    final int result = await residentRunner.run();
    expect(result, 0);

    expect(residentCompiler.recompileCalled, true);
    expect(residentCompiler.receivedNativeAssetsYaml, fs.path.toUri('foo.yaml'));
  });

  test('ResidentRunner delays on connection failure to allow logs to flush', () async {
    flutterDevice.connectError = Exception('Failed to connect');
    flutterDevice.logFlushDelay = const Duration(milliseconds: 100);

    final stopwatch = Stopwatch()..start();
    final int result = await residentRunner.attach();
    stopwatch.stop();

    expect(result, 2);
    expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
  });
  group('ResidentRunner cached Initial Dill Compilation', () {
    late Config localConfig;
    late FileSystem localFs;
    late FakeFlutterDevice flutterDevice;
    late FakeDevFS devFS;
    late TestHotRunner residentRunner;
    late FakeDevice device;

    setUp(() {
      localConfig = Config.test();
      localFs = MemoryFileSystem.test();
      final FakeAnalytics localAnalytics = getInitializedFakeAnalyticsInstance(
        fakeFlutterVersion: FakeFlutterVersion(),
        fs: MemoryFileSystem.test(),
      );
      device = FakeDevice();
      devFS = FakeDevFS();
      flutterDevice = FakeFlutterDevice()
        ..testUri = testUri
        ..device = device
        ..fakeDevFS = devFS;
      residentRunner = TestHotRunner(
        <FlutterDevice>[flutterDevice],
        applicationPackageFactory: FlutterApplicationPackageFactory(
          androidSdkBuilder: () => null,
          plistParserBuilder: FakePlistParser.new,
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
          toolContext: FakeToolContext(config: localConfig, fs: localFs),
        ),
        assetBundleFactory: AssetBundleFactory.defaultInstance(
          fileSystem: localFs,
          flutterRoot: getFlutterRoot(),
          logger: BufferLogger.test(),
          platform: FakePlatform(),
        ),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        buildTargets: const BuildTargetsImpl(),
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        toolContext: FakeToolContext(config: localConfig, fs: localFs),
        xcode: null,
        analytics: localAnalytics,
      );
      // Write the source dill file
      localFs.file(residentRunner.dillOutputPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('ABC');
    });

    test('correctly caches Web Device compilation', () {
      flutterDevice.targetPlatform = TargetPlatform.web_javascript;
      residentRunner.testCacheInitialDillCompilation();

      final String expectedPath = getDefaultCachedKernelPath(
        fileSystem: localFs,
        trackWidgetCreation: residentRunner.trackWidgetCreation,
        dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
        extraFrontEndOptions: kDdcLibraryBundleFlags,
        config: localConfig,
        targetModel: TargetModel.dartdevc,
      );

      expect(localFs.file(expectedPath), exists);
      expect(localFs.file(expectedPath).readAsStringSync(), 'ABC');
    });

    test('correctly caches Fuchsia Device compilation', () {
      flutterDevice.targetPlatform = TargetPlatform.fuchsia_arm64;
      residentRunner.testCacheInitialDillCompilation();

      final String expectedPath = getDefaultCachedKernelPath(
        fileSystem: localFs,
        trackWidgetCreation: residentRunner.trackWidgetCreation,
        dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
        extraFrontEndOptions: residentRunner.debuggingOptions.buildInfo.extraFrontEndOptions,
        config: localConfig,
        targetModel: TargetModel.flutterRunner,
      );

      expect(localFs.file(expectedPath), exists);
      expect(localFs.file(expectedPath).readAsStringSync(), 'ABC');
    });

    test('correctly caches Android Device compilation', () {
      flutterDevice.targetPlatform = TargetPlatform.android_arm;
      residentRunner.testCacheInitialDillCompilation();

      final String expectedPath = getDefaultCachedKernelPath(
        fileSystem: localFs,
        trackWidgetCreation: residentRunner.trackWidgetCreation,
        dartDefines: residentRunner.debuggingOptions.buildInfo.dartDefines,
        extraFrontEndOptions: residentRunner.debuggingOptions.buildInfo.extraFrontEndOptions,
        config: localConfig,
        targetModel: TargetModel.flutter,
      );

      expect(localFs.file(expectedPath), exists);
      expect(localFs.file(expectedPath).readAsStringSync(), 'ABC');
    });
  });

  test('FlutterDevice.create uses provided ResidentCompilerFactory', () async {
    final expectedCompiler = FakeResidentCompiler();
    final compilerFactory = _FakeResidentCompilerFactory(expectedCompiler);
    final device = FakeDevice();
    final FlutterDevice flutterDevice = await FlutterDevice.create(
      device,
      toolContext: FakeToolContext(
        artifacts: Artifacts.test(),
        config: config,
        fs: fs,
        processManager: FakeProcessManager.any(),
      ),
      buildInfo: BuildInfo.debug,
      target: null,
      residentCompilerFactory: compilerFactory,
      targetModelOverride: TargetModel.flutterRunner,
    );

    expect(flutterDevice.generator, same(expectedCompiler));
    expect(compilerFactory.lastTargetPlatform, TargetPlatform.android_arm);
    expect(compilerFactory.lastTargetModelOverride, TargetModel.flutterRunner);
  });
}

class _FakeResidentCompilerFactory implements ResidentCompilerFactory {
  _FakeResidentCompilerFactory(this._compiler);

  final ResidentCompiler _compiler;
  TargetPlatform? lastTargetPlatform;
  TargetModel? lastTargetModelOverride;

  @override
  ResidentCompiler create({
    required TargetPlatform targetPlatform,
    required BuildInfo buildInfo,
    required Logger logger,
    required ProcessManager processManager,
    required Artifacts artifacts,
    required Platform platform,
    required FileSystem fileSystem,
    required ShutdownHooks shutdownHooks,
    required Config config,
    bool testCompilation = false,
    TargetModel? targetModelOverride,
  }) {
    lastTargetPlatform = targetPlatform;
    lastTargetModelOverride = targetModelOverride;
    return _compiler;
  }
}

class TestHotRunner extends HotRunner {
  TestHotRunner(
    super.flutterDevices, {
    required super.analytics,
    required super.applicationPackageFactory,
    required super.assetBundleFactory,
    required super.buildSystem,
    required super.buildTargets,
    required super.debuggingOptions,
    required super.stayResident,
    required super.target,
    required super.toolContext,
    required super.xcode,
    FeatureFlags? featureFlags,
  }) : super(featureFlags: featureFlags ?? TestFeatureFlags());

  void testCacheInitialDillCompilation() {
    cacheInitialDillCompilation();
  }
}
