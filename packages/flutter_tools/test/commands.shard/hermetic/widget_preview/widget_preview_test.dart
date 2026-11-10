// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/fake.dart';

import '../../../src/common.dart';
import '../../../src/context.dart' show FakeProcessManager, FakeSignals;
import '../../../src/fakes.dart';
import '../../../src/test_build_system.dart';

const _kFailedRecompileMessage = 'Failed to recompile application.';
const _kProjectRootPath = '/project';
const _kMainDartPath = '/project/lib/main.dart';

class FakeWidgetPreviewDtdServices extends Fake implements WidgetPreviewDtdServices {
  @override
  Uri? dtdUri = Uri.parse('ws://127.0.0.1:54322/secret');

  @override
  String widgetPreviewService = 'widget-preview-uuid';

  @override
  String widgetPreviewScaffoldService = 'PreviewScaffold-uuid';

  @override
  String widgetPreviewScaffoldStream = 'WidgetPreviewScaffold-uuid';

  @override
  bool scaffoldConnected = true;

  int markScaffoldConnectedCount = 0;
  int markScaffoldDisconnectedCount = 0;
  int waitForScaffoldConnectedCount = 0;
  int waitForAnalysisCount = 0;
  Duration? lastWaitForScaffoldTimeout;
  Completer<void>? scaffoldConnectedCompleter;
  FlutterWidgetPreviews? nextPreviews;

  @override
  void markScaffoldConnected() {
    markScaffoldConnectedCount++;
    scaffoldConnected = true;
    if (scaffoldConnectedCompleter case final Completer<void> completer
        when !completer.isCompleted) {
      completer.complete();
    }
    scaffoldConnectedCompleter = null;
  }

  @override
  void markScaffoldDisconnected() {
    markScaffoldDisconnectedCount++;
    scaffoldConnected = false;
  }

  @override
  Future<void> waitForScaffoldConnected({
    Duration timeout = const Duration(milliseconds: WidgetPreviewDtdServices.kDefaultSyncTimeoutMs),
  }) async {
    waitForScaffoldConnectedCount++;
    lastWaitForScaffoldTimeout = timeout;
    if (scaffoldConnectedCompleter != null) {
      await scaffoldConnectedCompleter!.future.timeout(timeout);
    }
    scaffoldConnected = true;
  }

  @override
  Future<void> waitForAnalysis({Duration delay = const Duration(milliseconds: 100)}) async {
    waitForAnalysisCount++;
  }

  @override
  Future<FlutterWidgetPreviews> getFlutterWidgetPreviews() async {
    return nextPreviews ??
        const FlutterWidgetPreviews(
          namespaces: <String, String>{},
          previews: <FlutterWidgetPreviewDetails>[],
          scriptUris: <Uri>[],
        );
  }
}

class FakeResidentRunner extends Fake implements ResidentRunner {
  FakeResidentRunner({this.currentRestartCompleter, this.onRestart});

  final OperationResult Function(bool fullRestart)? onRestart;
  Completer<OperationResult>? currentRestartCompleter;
  int restartCount = 0;
  int concurrentRestarts = 0;
  int maxConcurrentRestarts = 0;
  final fullRestartRequests = <bool>[];

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool? pause = false,
    String? reason,
    bool benchmarkMode = false,
  }) async {
    restartCount++;
    fullRestartRequests.add(fullRestart);
    concurrentRestarts++;
    if (concurrentRestarts > maxConcurrentRestarts) {
      maxConcurrentRestarts = concurrentRestarts;
    }
    if (currentRestartCompleter != null) {
      await currentRestartCompleter!.future;
    }
    concurrentRestarts--;
    return onRestart?.call(fullRestart) ?? OperationResult.ok;
  }
}

void main() {
  // Regression tests for https://github.com/flutter/flutter/issues/192697.
  group('$WidgetPreviewStartCommand reload handling', () {
    late MemoryFileSystem fs;
    late BufferLogger bufferLogger;
    late WidgetPreviewMachineAwareLogger logger;
    late FlutterProject scaffoldProject;
    late FlutterWidgetPreviews emptyPreviewUpdate;

    late FakeWidgetPreviewDtdServices fakeDtdServices;

    setUp(() {
      fs = MemoryFileSystem.test();
      bufferLogger = BufferLogger.test();
      logger = WidgetPreviewMachineAwareLogger(
        bufferLogger,
        machine: false,
        stdio: FakeStdio(),
        verbose: false,
      );
      fakeDtdServices = FakeWidgetPreviewDtdServices();
      final Directory rootDir = fs.directory(_kProjectRootPath)..createSync(recursive: true);
      fs.currentDirectory = rootDir;
      rootDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.7.0
''');
      final Directory scaffoldDir = rootDir
          .childDirectory('.dart_tool')
          .childDirectory('widget_preview_scaffold');
      scaffoldDir.childDirectory('lib').childDirectory('src').createSync(recursive: true);
      scaffoldDir.childFile('pubspec.yaml').writeAsStringSync('''
name: widget_preview_scaffold
environment:
  sdk: ^3.7.0
''');
      scaffoldProject = FlutterProject.fromDirectoryTest(scaffoldDir, logger);
      emptyPreviewUpdate = FlutterWidgetPreviews(
        namespaces: const <String, String>{},
        previews: const <FlutterWidgetPreviewDetails>[],
        scriptUris: <Uri>[fs.file(_kMainDartPath).uri],
      );
    });

    WidgetPreviewStartCommand createStartCommand(FakeResidentRunner runner) {
      final command = WidgetPreviewCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        buildTargets: const BuildTargetsImpl(),
        toolContext: FakeToolContext(
          artifacts: Artifacts.test(),
          fs: fs,
          logger: logger,
          platform: FakePlatform(),
          processManager: FakeProcessManager.empty(),
          shutdownHooks: ShutdownHooks(),
          signals: FakeSignals(),
        ),
        dtdServicesOverride: fakeDtdServices,
      );
      return (command.subcommands['start']! as WidgetPreviewStartCommand)
        ..previewCodeGenerator = PreviewCodeGenerator(
          widgetPreviewScaffoldProject: scaffoldProject,
          fs: fs,
        )
        ..widgetPreviewApp = runner;
    }

    testWithoutContext(
      'onChangeDetected triggers hot restart under reload mutex when hot reload is rejected',
      () async {
        var rejectNextHotReload = true;
        final rejectedReloadCompleter = Completer<OperationResult>();
        final fakeResidentRunner = FakeResidentRunner(
          currentRestartCompleter: rejectedReloadCompleter,
          onRestart: (bool fullRestart) {
            if (!fullRestart && rejectNextHotReload) {
              rejectNextHotReload = false;
              return OperationResult(
                1,
                _kFailedRecompileMessage,
                updateFSReport: UpdateFSReport(hotReloadRejected: true),
              );
            }
            return OperationResult.ok;
          },
        );
        final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

        // Start a reload that will be rejected, then queue a follow-up change while the
        // rejected reload is still in flight.
        startCommand.onChangeDetected(emptyPreviewUpdate);
        await pumpEventQueue();
        expect(fakeResidentRunner.restartCount, 1);
        expect(fakeResidentRunner.concurrentRestarts, 1);

        startCommand.onChangeDetected(emptyPreviewUpdate);

        fakeResidentRunner.currentRestartCompleter = null;
        rejectedReloadCompleter.complete(OperationResult.ok);
        await pumpEventQueue();

        // The fallback hot restart must complete inside _reloadMutex before the queued
        // follow-up hot reload executes, with zero overlapping restart calls.
        expect(fakeResidentRunner.maxConcurrentRestarts, 1);
        expect(fakeResidentRunner.fullRestartRequests, <bool>[false, true, false]);
        expect(
          bufferLogger.statusText,
          contains(WidgetPreviewStartCommand.kHotReloadRejectedMessage),
        );
        expect(
          scaffoldProject.directory
              .childDirectory('lib')
              .childDirectory('src')
              .childFile('generated_preview.dart'),
          exists,
        );
      },
    );

    testWithoutContext(
      'onChangeDetected does not trigger hot restart when hot reload fails without rejection',
      () async {
        final fakeResidentRunner = FakeResidentRunner(
          onRestart: (bool fullRestart) {
            return OperationResult(1, _kFailedRecompileMessage, updateFSReport: UpdateFSReport());
          },
        );
        final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

        startCommand.onChangeDetected(emptyPreviewUpdate);
        await pumpEventQueue();

        expect(fakeResidentRunner.fullRestartRequests, <bool>[false]);
        expect(
          bufferLogger.statusText,
          isNot(contains(WidgetPreviewStartCommand.kHotReloadRejectedMessage)),
        );
      },
    );

    testWithoutContext(
      'onChangeDetected does not trigger hot restart when hot reload succeeds',
      () async {
        final fakeResidentRunner = FakeResidentRunner(
          onRestart: (bool fullRestart) {
            return OperationResult(
              0,
              '',
              updateFSReport: UpdateFSReport(success: true, hotReloadRejected: true),
            );
          },
        );
        final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

        startCommand.onChangeDetected(emptyPreviewUpdate);
        await pumpEventQueue();

        expect(fakeResidentRunner.fullRestartRequests, <bool>[false]);
        expect(
          bufferLogger.statusText,
          isNot(contains(WidgetPreviewStartCommand.kHotReloadRejectedMessage)),
        );
      },
    );

    testWithoutContext('handleReload returns fallback hot restart result when rejected', () async {
      final fakeResidentRunner = FakeResidentRunner(
        onRestart: (bool fullRestart) {
          if (!fullRestart) {
            return OperationResult(
              1,
              _kFailedRecompileMessage,
              updateFSReport: UpdateFSReport(hotReloadRejected: true),
            );
          }
          return OperationResult.ok;
        },
      );
      final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

      final OperationResult? result = await startCommand.handleReload();

      expect(fakeResidentRunner.fullRestartRequests, <bool>[false, true]);
      expect(result?.isOk, isTrue);
      expect(
        bufferLogger.statusText,
        contains(WidgetPreviewStartCommand.kHotReloadRejectedMessage),
      );
    });

    testWithoutContext(
      'handleReload returns failed result when hot reload fails for other reasons',
      () async {
        final fakeResidentRunner = FakeResidentRunner(
          onRestart: (bool fullRestart) {
            return OperationResult(1, _kFailedRecompileMessage, updateFSReport: UpdateFSReport());
          },
        );
        final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

        final OperationResult? result = await startCommand.handleReload();

        expect(fakeResidentRunner.fullRestartRequests, <bool>[false]);
        expect(fakeDtdServices.markScaffoldDisconnectedCount, 0);
        expect(result?.isOk, isFalse);
        expect(
          bufferLogger.statusText,
          isNot(contains(WidgetPreviewStartCommand.kHotReloadRejectedMessage)),
        );
      },
    );

    testWithoutContext('syncPreviews regenerates previews when changed, reloads, and waits for scaffold when disconnected', () async {
      final fakeResidentRunner = FakeResidentRunner();
      fakeDtdServices.scaffoldConnected = false;
      fakeDtdServices.nextPreviews = FlutterWidgetPreviews(
        namespaces: const <String, String>{
          'widget_preview.dart': '_i1',
          'utils.dart': '_i2',
          'package:my_app/main.dart': '_i3',
          'package:flutter/src/widget_previews/widget_previews.dart': '_i4',
        },
        previews: <FlutterWidgetPreviewDetails>[
          FlutterWidgetPreviewDetails(
            functionName: 'okPreview',
            hasError: false,
            dependencyHasErrors: false,
            isBuilder: false,
            isMultiPreview: false,
            packageName: 'my_app',
            position: const Position(character: 0, line: 10),
            previewAnnotation: "const _i4.Preview(name: 'OK')",
            scriptUri: fs.file(_kMainDartPath).uri,
            libraryUri: Uri.parse('package:my_app/main.dart'),
          ),
          FlutterWidgetPreviewDetails(
            functionName: 'brokenPreview',
            hasError: true,
            dependencyHasErrors: false,
            isBuilder: false,
            isMultiPreview: false,
            packageName: 'my_app',
            position: const Position(character: 0, line: 20),
            previewAnnotation: "const _i4.Preview(name: 'Broken')",
            scriptUri: fs.file(_kMainDartPath).uri,
            libraryUri: Uri.parse('package:my_app/main.dart'),
          ),
        ],
        scriptUris: <Uri>[fs.file(_kMainDartPath).uri],
      );

      final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);
      final File generatedFile = scaffoldProject.directory
          .childDirectory('lib')
          .childDirectory('src')
          .childFile('generated_preview.dart');
      expect(generatedFile, isNot(exists));

      final SyncPreviewsResponse response = await startCommand.syncPreviews(
        timeout: const Duration(seconds: 12),
      );

      expect(generatedFile, exists);
      expect(generatedFile.readAsStringSync(), contains('okPreview'));
      expect(fakeDtdServices.waitForAnalysisCount, 1);
      expect(fakeDtdServices.waitForScaffoldConnectedCount, 1);
      expect(fakeDtdServices.lastWaitForScaffoldTimeout, const Duration(seconds: 12));
      expect(fakeResidentRunner.fullRestartRequests, <bool>[false]);
      expect(
        response,
        equals(
          const SyncPreviewsResponse(
            compileSuccess: true,
            errorPreviewCount: 1,
            fullRestart: false,
            reloaded: true,
          ),
        ),
      );

      // Second sync with unchanged preview metadata still triggers an incremental
      // reload (capturing widget body edits), without waiting for Connected again.
      generatedFile.writeAsStringSync('// sentinel');
      final SyncPreviewsResponse secondResponse = await startCommand.syncPreviews();

      expect(generatedFile.readAsStringSync(), '// sentinel');
      expect(fakeResidentRunner.fullRestartRequests, <bool>[false, false]);
      expect(fakeDtdServices.waitForScaffoldConnectedCount, 1);
      expect(secondResponse.reloaded, isTrue);
      expect(secondResponse.fullRestart, isFalse);
    });

    testWithoutContext('syncPreviews marks scaffold disconnected before fallback hot restart and waits for reconnect', () async {
      var scaffoldWasMarkedDisconnectedBeforeRestart = false;
      final fakeResidentRunner = FakeResidentRunner(
        onRestart: (bool fullRestart) {
          if (!fullRestart) {
            return OperationResult(
              1,
              _kFailedRecompileMessage,
              updateFSReport: UpdateFSReport(hotReloadRejected: true),
            );
          }
          scaffoldWasMarkedDisconnectedBeforeRestart = !fakeDtdServices.scaffoldConnected;
          return OperationResult.ok;
        },
      );
      final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

      final SyncPreviewsResponse response = await startCommand.syncPreviews();

      expect(scaffoldWasMarkedDisconnectedBeforeRestart, isTrue);
      expect(fakeDtdServices.markScaffoldDisconnectedCount, 1);
      expect(fakeDtdServices.waitForScaffoldConnectedCount, 1);
      expect(fakeResidentRunner.fullRestartRequests, <bool>[false, true]);
      expect(
        response,
        equals(
          const SyncPreviewsResponse(
            compileSuccess: true,
            errorPreviewCount: 0,
            fullRestart: true,
            reloaded: true,
          ),
        ),
      );
    });

    testWithoutContext(
      'syncPreviews returns compileError immediately without hanging when compile fails',
      () async {
        fakeDtdServices.scaffoldConnected = false;
        final fakeResidentRunner = FakeResidentRunner(
          onRestart: (bool fullRestart) {
            return OperationResult(1, _kFailedRecompileMessage, updateFSReport: UpdateFSReport());
          },
        );
        final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

        final SyncPreviewsResponse response = await startCommand.syncPreviews();

        expect(fakeDtdServices.waitForScaffoldConnectedCount, 0);
        expect(
          response,
          equals(
            const SyncPreviewsResponse(
              compileError: _kFailedRecompileMessage,
              compileSuccess: false,
              errorPreviewCount: 0,
              fullRestart: false,
              reloaded: false,
            ),
          ),
        );
      },
    );

    testWithoutContext('restores scaffoldConnected when full restart fails compilation so subsequent incremental syncPreviews does not hang', () async {
      // Uncompleted completer models a running browser scaffold isolate that
      // will not emit a new Connected event when fullRestart fails before
      // hotRestart is sent to the browser.
      fakeDtdServices.scaffoldConnected = true;
      fakeDtdServices.scaffoldConnectedCompleter = Completer<void>();

      var failCompilation = true;
      var rejectHotReload = true;
      var disconnectedDuringFullRestart = false;
      final fakeResidentRunner = FakeResidentRunner(
        onRestart: (bool fullRestart) {
          if (fullRestart) {
            disconnectedDuringFullRestart = !fakeDtdServices.scaffoldConnected;
          }
          if (!fullRestart && rejectHotReload) {
            rejectHotReload = false;
            return OperationResult(
              1,
              _kFailedRecompileMessage,
              updateFSReport: UpdateFSReport(hotReloadRejected: true),
            );
          }
          if (failCompilation) {
            return OperationResult(1, _kFailedRecompileMessage, updateFSReport: UpdateFSReport());
          }
          return OperationResult.ok;
        },
      );
      final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

      // 1. Rejected hot reload falls back to fullRestart, which fails to compile.
      final SyncPreviewsResponse failedFallbackResponse = await startCommand.syncPreviews(
        timeout: const Duration(milliseconds: 10),
      );
      expect(disconnectedDuringFullRestart, isTrue);
      expect(fakeDtdServices.markScaffoldDisconnectedCount, 1);
      expect(fakeDtdServices.markScaffoldConnectedCount, 1);
      expect(fakeDtdServices.scaffoldConnected, isTrue);
      expect(fakeDtdServices.waitForScaffoldConnectedCount, 0);
      expect(
        failedFallbackResponse,
        equals(
          const SyncPreviewsResponse(
            compileError: _kFailedRecompileMessage,
            compileSuccess: false,
            errorPreviewCount: 0,
            fullRestart: true,
            reloaded: false,
          ),
        ),
      );

      // 2. Subsequent incremental syncPreviews succeeds without hanging on Connected.
      failCompilation = false;
      fakeDtdServices.scaffoldConnectedCompleter = Completer<void>();
      final SyncPreviewsResponse recoveredResponse = await startCommand.syncPreviews(
        timeout: const Duration(milliseconds: 10),
      );
      expect(fakeDtdServices.waitForScaffoldConnectedCount, 0);
      expect(
        recoveredResponse,
        equals(
          const SyncPreviewsResponse(
            compileSuccess: true,
            errorPreviewCount: 0,
            fullRestart: false,
            reloaded: true,
          ),
        ),
      );

      // 3. Explicit hot restart request failing compilation also restores scaffoldConnected.
      failCompilation = true;
      startCommand.onHotRestartRequest();
      await pumpEventQueue();
      expect(fakeDtdServices.markScaffoldDisconnectedCount, 2);
      expect(fakeDtdServices.markScaffoldConnectedCount, 2);
      expect(fakeDtdServices.scaffoldConnected, isTrue);

      // 4. When scaffold was never connected, a failed fullRestart keeps scaffoldConnected false.
      fakeDtdServices.scaffoldConnected = false;
      startCommand.onHotRestartRequest();
      await pumpEventQueue();
      expect(fakeDtdServices.markScaffoldDisconnectedCount, 3);
      expect(fakeDtdServices.markScaffoldConnectedCount, 2);
      expect(fakeDtdServices.scaffoldConnected, isFalse);
    });

    testWithoutContext('syncPreviews returns reloaded false without throwing before startup initialization or during shutdown', () async {
      final shutdownHooks = ShutdownHooks();
      final command = WidgetPreviewCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        buildTargets: const BuildTargetsImpl(),
        toolContext: FakeToolContext(
          artifacts: Artifacts.test(),
          fs: fs,
          logger: logger,
          platform: FakePlatform(),
          processManager: FakeProcessManager.empty(),
          shutdownHooks: shutdownHooks,
          signals: FakeSignals(),
        ),
        dtdServicesOverride: fakeDtdServices,
      );
      // Neither previewCodeGenerator nor widgetPreviewApp is initialized yet.
      final uninitializedStartCommand = command.subcommands['start']! as WidgetPreviewStartCommand;

      final SyncPreviewsResponse preInitResponse = await uninitializedStartCommand.syncPreviews();
      expect(fakeDtdServices.waitForAnalysisCount, 0);
      expect(
        preInitResponse,
        equals(
          const SyncPreviewsResponse(
            compileSuccess: true,
            errorPreviewCount: 0,
            fullRestart: false,
            reloaded: false,
          ),
        ),
      );

      final fakeResidentRunner = FakeResidentRunner();
      uninitializedStartCommand
        ..previewCodeGenerator = PreviewCodeGenerator(
          widgetPreviewScaffoldProject: scaffoldProject,
          fs: fs,
        )
        ..widgetPreviewApp = fakeResidentRunner;

      await shutdownHooks.runShutdownHooks(logger);
      final SyncPreviewsResponse shutdownResponse = await uninitializedStartCommand.syncPreviews();
      expect(fakeDtdServices.waitForAnalysisCount, 0);
      expect(fakeResidentRunner.restartCount, 0);
      expect(
        shutdownResponse,
        equals(
          const SyncPreviewsResponse(
            compileSuccess: true,
            errorPreviewCount: 0,
            fullRestart: false,
            reloaded: false,
          ),
        ),
      );
    });

    testWithoutContext(
      'onHotReloadRequest reloads and onHotRestartRequest marks scaffold disconnected',
      () async {
        final fakeResidentRunner = FakeResidentRunner();
        final WidgetPreviewStartCommand startCommand = createStartCommand(fakeResidentRunner);

        await startCommand.onHotReloadRequest();
        expect(fakeResidentRunner.fullRestartRequests, <bool>[false]);
        expect(fakeDtdServices.markScaffoldDisconnectedCount, 0);

        startCommand.onHotRestartRequest();
        await pumpEventQueue();
        expect(fakeResidentRunner.fullRestartRequests, <bool>[false, true]);
        expect(fakeDtdServices.markScaffoldDisconnectedCount, 1);
      },
    );

    testWithoutContext(
      'wires DTD RPC callbacks and emits machine started event with DTD metadata',
      () async {
        final fakeStdio = FakeStdio();
        final machineLogger = WidgetPreviewMachineAwareLogger(
          BufferLogger.test(),
          machine: true,
          stdio: fakeStdio,
          verbose: false,
        );
        final fakeResidentRunner = FakeResidentRunner();
        fs.directory(_kProjectRootPath)
          ..childDirectory('.widget_preview').childFile('pubspec.yaml').createSync(recursive: true)
          ..childDirectory('.widget_preview')
              .childFile('pubspec.yaml')
              .writeAsStringSync('name: widget_preview_scaffold\n');

        final command = WidgetPreviewCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          buildTargets: const BuildTargetsImpl(),
          toolContext: FakeToolContext(
            artifacts: Artifacts.test(),
            fs: fs,
            logger: machineLogger,
            platform: FakePlatform(),
            processManager: FakeProcessManager.empty(),
            shutdownHooks: ShutdownHooks(),
            signals: FakeSignals(),
          ),
        );
        // Verify WidgetPreviewMachineAwareLogger.sendStartedEvent wire schema.
        machineLogger.sendStartedEvent(
          applicationUrl: Uri.parse('http://localhost:54321'),
          dtdUri: Uri.parse('ws://127.0.0.1:54322/secret'),
          previewService: 'widget-preview-abc',
          projectRoot: _kProjectRootPath,
          scaffoldService: 'PreviewScaffold-abc',
        );

        final String emittedLine = fakeStdio.writtenToStdout.single.trim();
        final decoded = json.decode(emittedLine) as List<Object?>;
        expect(
          decoded,
          equals(<Object?>[
            <String, Object?>{
              'event': 'widget_preview.started',
              'params': <String, Object?>{
                'url': 'http://localhost:54321',
                'dtdUri': 'ws://127.0.0.1:54322/secret',
                'previewService': 'widget-preview-abc',
                'scaffoldService': 'PreviewScaffold-abc',
                'projectRoot': _kProjectRootPath,
              },
            },
          ]),
        );

        // Verify the real WidgetPreviewDtdServices instance constructed and wired by
        // WidgetPreviewStartCommand itself (no dtdServicesOverride).
        final wiredStartCommand = (command.subcommands['start']! as WidgetPreviewStartCommand)
          ..previewCodeGenerator = PreviewCodeGenerator(
            widgetPreviewScaffoldProject: scaffoldProject,
            fs: fs,
          )
          ..widgetPreviewApp = fakeResidentRunner
          ..webPreviewUri = Uri.parse('http://localhost:54321');
        final WidgetPreviewDtdServices dtdServices = wiredStartCommand.dtdService;
        final String uuid = dtdServices.serviceUuid;

        DTDServiceCallback callbackFor(String method) {
          for (final (String name, DTDServiceCallback cb) in dtdServices.services) {
            if (name == method) {
              return cb;
            }
          }
          fail('Missing $method');
        }

        final Map<String, Object?> infoJson = await callbackFor(
          WidgetPreviewDtdServices.kGetServiceInfo,
        )(Parameters('getServiceInfo', <String, Object?>{}));
        expect(infoJson[PreviewServiceInfo.kType], PreviewServiceInfo.kTypeName);
        expect(infoJson[PreviewServiceInfo.kProjectRoot], _kProjectRootPath);
        expect(infoJson[PreviewServiceInfo.kPreviewService], 'widget-preview-$uuid');
        expect(infoJson[PreviewServiceInfo.kScaffoldService], 'PreviewScaffold-$uuid');
        expect(infoJson[PreviewServiceInfo.kScaffoldStream], 'WidgetPreviewScaffold-$uuid');
        expect(infoJson[PreviewServiceInfo.kWebPreviewUri], 'http://localhost:54321');

        final Map<String, Object?> urlJson = await callbackFor(
          WidgetPreviewDtdServices.kGetWebPreviewUrl,
        )(Parameters('getWebPreviewUrl', <String, Object?>{}));
        expect(urlJson[WebPreviewUrlResult.kType], WebPreviewUrlResult.kTypeName);
        expect(urlJson[WebPreviewUrlResult.kUrl], 'http://localhost:54321');

        final Map<String, Object?> reloadJson = await callbackFor(
          WidgetPreviewDtdServices.kHotReloadPreviewer,
        )(Parameters('hotReloadPreviewer', <String, Object?>{}));
        expect(reloadJson, equals(const Success().toJson()));
        expect(fakeResidentRunner.restartCount, 1);
      },
    );
  });
}
