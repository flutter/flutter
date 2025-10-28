// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/command_help.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart';
import '../src/package_config.dart';
import '../src/testbed.dart';
import '../src/throwing_pub.dart';
import 'resident_runner_helpers.dart';

FakeAnalytics get fakeAnalytics => globals.analytics as FakeAnalytics;

void main() {
  late TestBed testbed;
  late FakeFlutterDevice flutterDevice;
  late FakeDevFS devFS;
  late ResidentRunner residentRunner;
  late FakeDevice device;
  FakeVmServiceHost? fakeVmServiceHost;

  setUp(() {
    testbed = TestBed(
      setup: () {
        globals.fs.file(globals.fs.path.join('build', 'app.dill'))
          ..createSync(recursive: true)
          ..writeAsStringSync('ABC');
        residentRunner = HotRunner(
          <FlutterDevice>[flutterDevice],
          stayResident: false,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          target: 'main.dart',
          analytics: fakeAnalytics,
        );
      },
      overrides: <Type, Generator>{
        Analytics: () => getInitializedFakeAnalyticsInstance(
          fakeFlutterVersion: FakeFlutterVersion(),
          fs: MemoryFileSystem.test(),
        ),
      },
    );
    device = FakeDevice();
    devFS = FakeDevFS();
    flutterDevice = FakeFlutterDevice()
      ..testUri = testUri
      ..vmServiceHost = (() => fakeVmServiceHost)
      ..device = device
      ..fakeDevFS = devFS;
  });

  testUsingContext(
    'ResidentRunner can attach to device successfully',
    () => testbed.run(() async {
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
    }),
  );

  testUsingContext(
    'ResidentRunner reports whether detach() was used',
    () => testbed.run(() async {
      expect(residentRunner.stopAppDuringCleanup, true);
      await residentRunner.detach();
      expect(residentRunner.stopAppDuringCleanup, false);
    }),
  );

  testUsingContext(
    'ResidentRunner suppresses errors for the initial compilation',
    () => testbed.run(() async {
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
      final residentCompiler = FakeResidentCompiler()
        ..nextOutput = const CompilerOutput('foo', 0, <Uri>[]);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: globals.analytics,
      );
      flutterDevice.generator = residentCompiler;

      expect(await residentRunner.run(), 0);
      expect(residentCompiler.didSuppressErrors, true);
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }),
  );

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext(
    'ResidentRunner calls appFailedToStart if initial compilation fails',
    () => testbed.run(() async {
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final residentCompiler = FakeResidentCompiler()
        ..nextOutput = const CompilerOutput('foo', 1, <Uri>[]);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: globals.analytics,
      );
      flutterDevice.generator = residentCompiler;

      expect(await residentRunner.run(), 1);
      // Completing this future ensures that the daemon can exit correctly.
      expect(await residentRunner.waitForAppToFinish(), 1);
    }),
  );

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext(
    'ResidentRunner calls appFailedToStart if initial compilation fails - cold mode',
    () => testbed.run(() async {
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      residentRunner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
        target: 'main.dart',
      );
      flutterDevice.runColdCode = 1;

      expect(await residentRunner.run(), 1);
      // Completing this future ensures that the daemon can exit correctly.
      expect(await residentRunner.waitForAppToFinish(), 1);
    }),
  );

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext(
    'ResidentRunner calls appFailedToStart if exception is thrown - cold mode',
    () => testbed.run(() async {
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      residentRunner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
        target: 'main.dart',
      );
      flutterDevice.runColdError = Exception('BAD STUFF');

      expect(await residentRunner.run(), 1);
      // Completing this future ensures that the daemon can exit correctly.
      expect(await residentRunner.waitForAppToFinish(), 1);
    }),
  );

  testUsingContext(
    'ResidentRunner does not suppressErrors if running with an applicationBinary',
    () => testbed.run(() async {
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
      final residentCompiler = FakeResidentCompiler()
        ..nextOutput = const CompilerOutput('foo', 0, <Uri>[]);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        applicationBinary: globals.fs.file('app-debug.apk'),
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: globals.analytics,
      );
      flutterDevice.generator = residentCompiler;

      expect(await residentRunner.run(), 0);
      expect(residentCompiler.didSuppressErrors, false);
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }),
  );

  testUsingContext(
    'ResidentRunner can handle an RPC exception from hot reload',
    () => testbed.run(() async {
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
        (globals.analytics as FakeAnalytics).sentEvents,
        contains(
          Event.hotRunnerInfo(
            label: 'exception',
            targetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
            sdkName: 'Android',
            emulator: false,
            fullRestart: false,
          ),
        ),
      );
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }, overrides: <Type, Generator>{Usage: () => TestUsage()}),
  );

  testUsingContext(
    'ResidentRunner fails its operation if the device initialization is not complete',
    () => testbed.run(() async {
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
    }),
  );

  testUsingContext(
    'ResidentRunner can handle an reload-barred exception from hot reload',
    () => testbed.run(() async {
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
            targetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
            sdkName: 'Android',
            emulator: false,
            fullRestart: false,
          ),
        ),
      );
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }, overrides: <Type, Generator>{Usage: () => TestUsage()}),
  );

  testUsingContext(
    'ResidentRunner reports hot reload event with null safety analytics',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews, listViews],
      );
      residentRunner = HotRunner(
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
            targetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
            sdkName: 'Android',
            emulator: false,
            fullRestart: false,
          ),
        ),
      );
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }, overrides: <Type, Generator>{Usage: () => TestUsage()}),
  );

  testUsingContext(
    'ResidentRunner does not reload sources if no sources changed',
    () => testbed.run(() async {
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
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
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
    }),
  );

  testUsingContext(
    'ResidentRunner reports error with missing entrypoint file',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          listViews,
          listViews,
          listViews,
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{
              'isolates': <Object>[fakeUnpausedIsolate.toJson()],
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

      expect(globals.fs.file(globals.fs.path.join('lib', 'main.dart')), isNot(exists));
      expect(testLogger.errorText, contains('The entrypoint file (i.e. the file with main())'));
      expect(result.fatal, false);
      expect(result.code, 0);
    }),
  );

  testUsingContext(
    'ResidentRunner resets compilation time on reload reject',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          listViews,
          listViews,
          listViews,
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{
              'isolates': <Object>[fakeUnpausedIsolate.toJson()],
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
    }),
  );

  testUsingContext(
    'ResidentRunner can send target platform to analytics from hot reload',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          listViews,
          listViews,
          listViews,
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{
              'isolates': <Object>[fakeUnpausedIsolate.toJson()],
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
      expect(
        event.eventData['targetPlatform'],
        getNameForTargetPlatform(TargetPlatform.android_arm),
      );
    }, overrides: <Type, Generator>{Usage: () => TestUsage()}),
  );

  testUsingContext(
    'ResidentRunner reports hot reload time details',
    () => testbed.run(
      () async {
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
        residentRunner = HotRunner(
          <FlutterDevice>[flutterDevice],
          stayResident: false,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          target: 'main.dart',
          analytics: fakeAnalytics,
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
          testLogger.statusText,
          contains(
            RegExp(
              r'Reloaded 1 of 42 libraries in \d+ms '
              r'\(compile: \d+ ms, reload: \d+ ms, reassemble: \d+ ms\)\.',
            ),
          ),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        Platform: () => FakePlatform(),
        ProjectFileInvalidator: () => FakeProjectFileInvalidator(),
        Usage: () => TestUsage(),
      },
    ),
  );

  testUsingContext(
    'ResidentRunner can send target platform to analytics from full restart',
    () => testbed.run(() async {
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
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
          ),
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
      expect(
        newEvent.eventData['targetPlatform'],
        getNameForTargetPlatform(TargetPlatform.android_arm),
      );
    }, overrides: <Type, Generator>{Usage: () => TestUsage()}),
  );

  testUsingContext(
    'ResidentRunner can remove breakpoints and exception-pause-mode from paused isolate during hot restart',
    () => testbed.run(() async {
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
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
          ),
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
    }),
  );

  testUsingContext(
    'ResidentRunner will alternative the name of the dill file uploaded for a hot restart',
    () => testbed.run(() async {
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
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
          ),
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
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
          ),
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
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse: vm_service.VM.parse(<String, Object>{})!.toJson(),
          ),
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
    }),
  );

  testUsingContext(
    'ResidentRunner Can handle an RPC exception from hot restart',
    () => testbed.run(() async {
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
            targetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
            sdkName: 'Android',
            emulator: false,
            fullRestart: true,
          ),
        ),
      );
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }, overrides: <Type, Generator>{Usage: () => TestUsage()}),
  );

  testUsingContext(
    'ResidentRunner uses temp directory when there is no output dill path',
    () => testbed.run(() {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      expect(residentRunner.artifactDirectory.path, contains('flutter_tool.'));

      final ResidentRunner otherRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        dillOutputPath: globals.fs.path.join('foobar', 'app.dill'),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );
      expect(otherRunner.artifactDirectory.path, contains('foobar'));
    }),
  );

  testUsingContext(
    'ResidentRunner deletes artifact directory on preExit',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      residentRunner.artifactDirectory.childFile('app.dill').createSync();
      await residentRunner.preExit();

      expect(residentRunner.artifactDirectory, isNot(exists));
    }),
  );

  testUsingContext(
    'ResidentRunner can run source generation',
    () => testbed.run(() async {
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
name: my_app
flutter:
  generate: true''');

      // Create necessary files for [DartPluginRegistrantTarget]
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'path_provider_linux': 'path_provider_linux'},
      );

      // Start from an empty dart_plugin_registrant.dart file.
      globals.fs
          .directory('.dart_tool')
          .childDirectory('flutter_build')
          .childFile('dart_plugin_registrant.dart')
          .createSync(recursive: true);

      await residentRunner.runSourceGenerators();

      expect(testLogger.errorText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    }, overrides: <Type, Generator>{Pub: ThrowingPub.new}),
  );

  testUsingContext(
    'generated main uses correct target',
    () => testbed.run(() async {
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
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'path_provider_linux': 'path_provider_linux'},
      );

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
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'custom_main.dart',
        analytics: fakeAnalytics,
      );
      await residentRunner.runSourceGenerators();

      final File generatedMain = globals.fs
          .directory('.dart_tool')
          .childDirectory('flutter_build')
          .childFile('dart_plugin_registrant.dart');

      expect(generatedMain.existsSync(), isTrue);
      expect(testLogger.errorText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    }, overrides: <Type, Generator>{Pub: ThrowingPub.new}),
  );

  testUsingContext(
    'ResidentRunner can run source generation - generation fails',
    () => testbed.run(() async {
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

      expect(testLogger.errorText, contains('Error'));
      expect(testLogger.statusText, isEmpty);
    }),
  );

  testUsingContext(
    'ResidentRunner generates files when l10n.yaml exists',
    () => testbed.run(() async {
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
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
      final residentCompiler = FakeResidentCompiler()
        ..nextOutput = const CompilerOutput('foo', 1, <Uri>[]);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );
      flutterDevice.generator = residentCompiler;

      await residentRunner.run();

      final File generatedLocalizationsFile = globals.fs
          .directory('lib')
          .childDirectory('l10n')
          .childFile('app_localizations.dart');
      expect(generatedLocalizationsFile, exists);

      // Completing this future ensures that the daemon can exit correctly.
      expect(await residentRunner.waitForAppToFinish(), 1);
    }),
  );

  testUsingContext(
    'ResidentRunner printHelpDetails hot runner',
    () => testbed.run(() {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

      residentRunner.printHelp(details: true);

      final CommandHelp commandHelp = residentRunner.commandHelp;

      // supports service protocol
      expect(residentRunner.supportsServiceProtocol, true);
      // isRunningDebug
      expect(residentRunner.isRunningDebug, true);
      // commands
      expect(
        testLogger.statusText,
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
    }),
  );

  testUsingContext(
    'ResidentRunner printHelp hot runner',
    () => testbed.run(() {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);

      residentRunner.printHelp(details: false);

      final CommandHelp commandHelp = residentRunner.commandHelp;

      // supports service protocol
      expect(residentRunner.supportsServiceProtocol, true);
      // isRunningDebug
      expect(residentRunner.isRunningDebug, true);
      // commands
      expect(
        testLogger.statusText,
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
    }),
  );

  testUsingContext(
    'ResidentRunner printHelpDetails cold runner',
    () => testbed.run(() {
      fakeVmServiceHost = null;
      residentRunner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        target: 'main.dart',
      );
      residentRunner.printHelp(details: true);

      final CommandHelp commandHelp = residentRunner.commandHelp;

      // does not supports service protocol
      expect(residentRunner.supportsServiceProtocol, false);
      // isRunningDebug
      expect(residentRunner.isRunningDebug, false);
      // commands
      expect(
        testLogger.statusText,
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
    }),
  );

  testUsingContext(
    'ResidentRunner printHelp cold runner',
    () => testbed.run(() {
      fakeVmServiceHost = null;
      residentRunner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        target: 'main.dart',
      );
      residentRunner.printHelp(details: false);

      final CommandHelp commandHelp = residentRunner.commandHelp;

      // does not supports service protocol
      expect(residentRunner.supportsServiceProtocol, false);
      // isRunningDebug
      expect(residentRunner.isRunningDebug, false);
      // commands
      expect(
        testLogger.statusText,
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
    }),
  );

  testUsingContext(
    'ResidentRunner printHelpDetails hides v on web in profile mode',
    () => testbed.run(() async {
      final FlutterDevice flutterDevice = await FlutterDevice.create(
        FakeDevice(targetPlatform: TargetPlatform.web_javascript),
        target: 'lib/main.dart',
        buildInfo: BuildInfo.profile,
        platform: FakePlatform(),
      );

      final ResidentRunner residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.profile),
        target: 'lib/main.dart',
        analytics: fakeAnalytics,
      );

      residentRunner.printHelp(details: true);

      final CommandHelp commandHelp = residentRunner.commandHelp;

      expect(residentRunner.isRunningDebug, false);
      expect(testLogger.statusText, isNot(contains(commandHelp.v)));
    }),
  );

  testUsingContext(
    'ResidentRunner ignores DevtoolsLauncher when attaching with enableDevTools: false - cold mode',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
      residentRunner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(
          BuildInfo.profile,
          vmserviceOutFile: 'foo',
          enableDevTools: false,
        ),
        target: 'main.dart',
      );

      final Future<int?> result = residentRunner.attach();
      expect(await result, 0);
    }),
  );

  testUsingContext(
    'FlutterDevice can exit from a release mode isolate with no VmService',
    () => testbed.run(() async {
      final flutterDevice = TestFlutterDevice(device);

      await flutterDevice.exitApps();

      expect(device.appStopped, true);
    }),
  );

  testUsingContext(
    'FlutterDevice will exit an un-paused isolate using stopApp',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final flutterDevice = TestFlutterDevice(device);
      flutterDevice.vmService = fakeVmServiceHost!.vmService;

      final Future<void> exitFuture = flutterDevice.exitApps();

      await expectLater(exitFuture, completes);
      expect(device.appStopped, true);
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }),
  );

  testUsingContext(
    'HotRunner writes vm service file when providing debugging option',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );

      await residentRunner.run();

      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
      expect(await globals.fs.file('foo').readAsString(), testUri.toString());
    }),
  );

  testUsingContext(
    'HotRunner copies compiled app.dill to cache during startup',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
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
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      expect(
        await globals.fs.file(globals.fs.path.join('build', 'cache.dill')).readAsString(),
        'ABC',
      );
    }),
  );

  testUsingContext(
    'HotRunner copies compiled app.dill to cache during startup with dart defines',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
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
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      expect(
        await globals.fs
            .file(globals.fs.path.join('build', '187ef4436122d1cc2f40dc2b92f0eba0.cache.dill'))
            .readAsString(),
        'ABC',
      );
    }),
  );

  testUsingContext(
    'HotRunner copies compiled app.dill to cache during startup with null safety',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
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
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      expect(
        await globals.fs.file(globals.fs.path.join('build', 'cache.dill')).readAsString(),
        'ABC',
      );
    }),
  );

  testUsingContext(
    'HotRunner copies compiled app.dill to cache during startup with track-widget-creation',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      expect(
        await globals.fs
            .file(globals.fs.path.join('build', 'cache.dill.track.dill'))
            .readAsString(),
        'ABC',
      );
    }),
  );

  testUsingContext(
    'HotRunner does not copy app.dill if a dillOutputPath is given',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        dillOutputPath: 'test',
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      expect(globals.fs.file(globals.fs.path.join('build', 'cache.dill')), isNot(exists));
    }),
  );

  testUsingContext(
    'HotRunner copies compiled app.dill to cache during startup with --track-widget-creation',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
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
      );
      residentRunner.artifactDirectory.childFile('app.dill').writeAsStringSync('ABC');

      await residentRunner.run();

      expect(
        await globals.fs
            .file(globals.fs.path.join('build', 'cache.dill.track.dill'))
            .readAsString(),
        'ABC',
      );
    }),
  );

  testUsingContext(
    'HotRunner calls device dispose',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );

      await residentRunner.run();
      expect(device.disposed, true);
    }),
  );

  testUsingContext(
    'HotRunner handles failure to write vmservice file',
    () => testbed.run(
      () async {
        fakeVmServiceHost = FakeVmServiceHost(
          requests: <VmServiceExpectation>[listViews, listViews],
        );
        globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
        residentRunner = HotRunner(
          <FlutterDevice>[flutterDevice],
          stayResident: false,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, vmserviceOutFile: 'foo'),
          target: 'main.dart',
          analytics: fakeAnalytics,
        );

        await residentRunner.run();

        expect(testLogger.errorText, contains('Failed to write vmservice-out-file at foo'));
        expect(fakeVmServiceHost?.hasRemainingExpectations, false);
      },
      overrides: <Type, Generator>{
        FileSystem: () => ThrowingForwardingFileSystem(MemoryFileSystem.test()),
      },
    ),
  );

  testUsingContext(
    'ColdRunner writes vm service file when providing debugging option',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews],
        wsAddress: testUri,
      );
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = ColdRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.profile, vmserviceOutFile: 'foo'),
        target: 'main.dart',
      );

      await residentRunner.run();

      expect(await globals.fs.file('foo').readAsString(), testUri.toString());
      expect(fakeVmServiceHost?.hasRemainingExpectations, false);
    }),
  );

  testUsingContext(
    'FlutterDevice uses dartdevc configuration when targeting web',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final device = FakeDevice(targetPlatform: TargetPlatform.web_javascript);
      final residentCompiler =
          (await FlutterDevice.create(
                device,
                buildInfo: const BuildInfo(
                  BuildMode.debug,
                  '',
                  treeShakeIcons: false,
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
                target: null,
                platform: FakePlatform(),
              )).generator
              as DefaultResidentCompiler?;

      expect(
        residentCompiler!.initializeFromDill,
        globals.fs.path.join(getBuildDirectory(), 'cache.dill'),
      );
      expect(
        residentCompiler.librariesSpec,
        globals.fs
            .file(globals.artifacts!.getHostArtifact(HostArtifact.flutterWebLibrariesJson))
            .uri
            .toString(),
      );
      expect(residentCompiler.targetModel, TargetModel.dartdevc);
      expect(
        residentCompiler.sdkRoot,
        '${globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path}/',
      );
      expect(
        residentCompiler.platformDill,
        'file:///HostArtifact.webPlatformKernelFolder/ddc_outline.dill',
      );
    },
    overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'FlutterDevice uses dartdevc configuration when targeting web with null-safety autodetected',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final device = FakeDevice(targetPlatform: TargetPlatform.web_javascript);

      final residentCompiler =
          (await FlutterDevice.create(
                device,
                buildInfo: const BuildInfo(
                  BuildMode.debug,
                  '',
                  treeShakeIcons: false,
                  extraFrontEndOptions: <String>['--enable-experiment=non-nullable'],
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
                target: null,
                platform: FakePlatform(),
              )).generator
              as DefaultResidentCompiler?;

      expect(
        residentCompiler!.initializeFromDill,
        globals.fs.path.join(getBuildDirectory(), 'cache.dill'),
      );
      expect(
        residentCompiler.librariesSpec,
        globals.fs
            .file(globals.artifacts!.getHostArtifact(HostArtifact.flutterWebLibrariesJson))
            .uri
            .toString(),
      );
      expect(residentCompiler.targetModel, TargetModel.dartdevc);
      expect(
        residentCompiler.sdkRoot,
        '${globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path}/',
      );
      expect(
        residentCompiler.platformDill,
        'file:///HostArtifact.webPlatformKernelFolder/ddc_outline.dill',
      );
    },
    overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'FlutterDevice passes alternative-invalidation-strategy flag',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final device = FakeDevice();

      final residentCompiler =
          (await FlutterDevice.create(
                device,
                buildInfo: const BuildInfo(
                  BuildMode.debug,
                  '',
                  treeShakeIcons: false,
                  extraFrontEndOptions: <String>[],
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
                target: null,
                platform: FakePlatform(),
              )).generator
              as DefaultResidentCompiler?;

      expect(
        residentCompiler!.extraFrontEndOptions,
        contains('--enable-experiment=alternative-invalidation-strategy'),
      );
    },
    overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'FlutterDevice passes initializeFromDill parameter if specified',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final device = FakeDevice();

      final residentCompiler =
          (await FlutterDevice.create(
                device,
                buildInfo: const BuildInfo(
                  BuildMode.debug,
                  '',
                  treeShakeIcons: false,
                  extraFrontEndOptions: <String>[],
                  initializeFromDill: '/foo/bar.dill',
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
                target: null,
                platform: FakePlatform(),
              )).generator
              as DefaultResidentCompiler?;

      expect(residentCompiler!.initializeFromDill, '/foo/bar.dill');
      expect(residentCompiler.assumeInitializeFromDillUpToDate, false);
    },
    overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'FlutterDevice passes assumeInitializeFromDillUpToDate parameter if specified',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final device = FakeDevice();

      final residentCompiler =
          (await FlutterDevice.create(
                device,
                buildInfo: const BuildInfo(
                  BuildMode.debug,
                  '',
                  treeShakeIcons: false,
                  extraFrontEndOptions: <String>[],
                  assumeInitializeFromDillUpToDate: true,
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
                target: null,
                platform: FakePlatform(),
              )).generator
              as DefaultResidentCompiler?;

      expect(residentCompiler!.assumeInitializeFromDillUpToDate, true);
    },
    overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'FlutterDevice passes frontendServerStarterPath parameter if specified',
    () async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      final device = FakeDevice();

      final residentCompiler =
          (await FlutterDevice.create(
                device,
                buildInfo: const BuildInfo(
                  BuildMode.debug,
                  '',
                  treeShakeIcons: false,
                  frontendServerStarterPath: '/foo/bar/frontend_server_starter.dart',
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
                target: null,
                platform: FakePlatform(),
              )).generator
              as DefaultResidentCompiler?;

      expect(residentCompiler!.frontendServerStarterPath, '/foo/bar/frontend_server_starter.dart');
    },
    overrides: <Type, Generator>{
      Artifacts: () => Artifacts.test(),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'Uses existing DDS URI from exception field',
    () => testbed.run(
      () async {
        fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
        final device = FakeDevice()..dds = DartDevelopmentService(logger: testLogger);
        ddsLauncherCallback =
            ({
              required Uri remoteVmServiceUri,
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
        final flutterDevice = TestFlutterDevice(device, vmServiceUris: Stream<Uri>.value(testUri));
        final done = Completer<void>();
        unawaited(
          runZonedGuarded(
            () => flutterDevice
                .connect(debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug))
                .then((_) => done.complete()),
            (_, _) => done.complete(),
          ),
        );
        await done.future;
        expect(device.dds.uri, Uri.parse('http://localhost/existingDdsInField'));
      },
      overrides: <Type, Generator>{
        VMServiceConnector: () =>
            (
              Uri httpUri, {
              ReloadSources? reloadSources,
              Restart? restart,
              CompileExpression? compileExpression,
              FlutterProject? flutterProject,
              PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
              io.CompressionOptions? compression,
              Device? device,
              required Logger logger,
            }) async => FakeVmServiceHost(requests: <VmServiceExpectation>[]).vmService,
      },
    ),
  );

  testUsingContext(
    'Host VM service ipv6 defaults',
    () => testbed.run(
      () async {
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
        final device = FakeDevice()..dds = DartDevelopmentService(logger: testLogger);
        final done = Completer<void>();
        ddsLauncherCallback =
            ({
              required Uri remoteVmServiceUri,
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
              expect(enableAuthCodes, isFalse);
              expect(serviceUri, Uri(scheme: 'http', host: '::1', port: 0));
              expect(cachedUserTags, isEmpty);
              done.complete();
              return FakeDartDevelopmentServiceLauncher(uri: remoteVmServiceUri);
            };
        final flutterDevice = TestFlutterDevice(device, vmServiceUris: Stream<Uri>.value(testUri));
        await flutterDevice.connect(
          debuggingOptions: DebuggingOptions.enabled(
            BuildInfo.debug,
            disableServiceAuthCodes: true,
            ipv6: true,
          ),
        );
        await done.future;
      },
      overrides: <Type, Generator>{
        VMServiceConnector: () =>
            (
              Uri httpUri, {
              ReloadSources? reloadSources,
              Restart? restart,
              CompileExpression? compileExpression,
              FlutterProject? flutterProject,
              PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
              io.CompressionOptions? compression,
              Device? device,
              required Logger logger,
            }) async => fakeVmServiceHost!.vmService,
      },
    ),
  );

  testUsingContext('nextPlatform moves through expected platforms', () {
    expect(nextPlatform('android'), 'iOS');
    expect(nextPlatform('iOS'), 'windows');
    expect(nextPlatform('windows'), 'macOS');
    expect(nextPlatform('macOS'), 'linux');
    expect(nextPlatform('linux'), 'fuchsia');
    expect(nextPlatform('fuchsia'), 'android');
    expect(() => nextPlatform('unknown'), throwsAssertionError);
  });

  testUsingContext(
    'HotRunner sets asset directory when first evict assets',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, setAssetBundlePath, evict],
      );
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );

      (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'asset'};

      expect(flutterDevice.devFS!.hasSetAssetDirectory, isFalse);
      await (residentRunner as HotRunner).evictDirtyAssets();
      expect(flutterDevice.devFS!.hasSetAssetDirectory, isTrue);
      expect(fakeVmServiceHost!.hasRemainingExpectations, isFalse);
    }),
  );

  testUsingContext(
    'HotRunner sets asset directory when first evict shaders',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[listViews, setAssetBundlePath, evictShader],
      );
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );

      (flutterDevice.devFS! as FakeDevFS).shaderPathsToEvict = <String>{'foo.frag'};

      expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
      await (residentRunner as HotRunner).evictDirtyAssets();
      expect(flutterDevice.devFS!.hasSetAssetDirectory, true);
      expect(fakeVmServiceHost!.hasRemainingExpectations, false);
    }),
  );

  testUsingContext(
    'HotRunner does not sets asset directory when no assets to evict',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[]);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );

      expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
      await (residentRunner as HotRunner).evictDirtyAssets();
      expect(flutterDevice.devFS!.hasSetAssetDirectory, false);
      expect(fakeVmServiceHost!.hasRemainingExpectations, false);
    }),
  );

  testUsingContext(
    'HotRunner does not set asset directory if it has been set before',
    () => testbed.run(() async {
      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, evict]);
      residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        analytics: fakeAnalytics,
      );

      (flutterDevice.devFS! as FakeDevFS).assetPathsToEvict = <String>{'asset'};
      flutterDevice.devFS!.hasSetAssetDirectory = true;

      await (residentRunner as HotRunner).evictDirtyAssets();
      expect(flutterDevice.devFS!.hasSetAssetDirectory, true);
      expect(fakeVmServiceHost!.hasRemainingExpectations, false);
    }),
  );

  testUsingContext(
    'use the nativeAssetsYamlFile when provided',
    () => testbed.run(() async {
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
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      residentRunner = HotRunner(
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
        analytics: globals.analytics,
        nativeAssetsYamlFile: 'foo.yaml',
      );

      final int? result = await residentRunner.run();
      expect(result, 0);

      expect(residentCompiler.recompileCalled, true);
      expect(residentCompiler.receivedNativeAssetsYaml, globals.fs.path.toUri('foo.yaml'));
    }),
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
    },
  );
}
