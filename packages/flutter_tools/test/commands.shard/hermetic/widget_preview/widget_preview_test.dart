// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:test/fake.dart';

import '../../../src/common.dart';
import '../../../src/context.dart' show FakeProcessManager, FakeSignals;
import '../../../src/fakes.dart';
import '../../../src/test_build_system.dart';

const _kFailedRecompileMessage = 'Failed to recompile application.';
const _kProjectRootPath = '/project';
const _kMainDartPath = '/project/lib/main.dart';

class FakeWidgetPreviewDtdServices extends Fake implements WidgetPreviewDtdServices {}

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

    setUp(() {
      fs = MemoryFileSystem.test();
      bufferLogger = BufferLogger.test();
      logger = WidgetPreviewMachineAwareLogger(
        bufferLogger,
        machine: false,
        stdio: FakeStdio(),
        verbose: false,
      );
      final Directory rootDir = fs.directory(_kProjectRootPath)..createSync(recursive: true);
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
          signals: FakeSignals(),
        ),
        dtdServicesOverride: FakeWidgetPreviewDtdServices(),
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
        expect(result?.isOk, isFalse);
        expect(
          bufferLogger.statusText,
          isNot(contains(WidgetPreviewStartCommand.kHotReloadRejectedMessage)),
        );
      },
    );
  });
}
