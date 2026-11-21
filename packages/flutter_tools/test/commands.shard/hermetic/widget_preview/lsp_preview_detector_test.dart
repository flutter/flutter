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
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/widget_preview.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:flutter_tools/src/widget_preview/lsp_preview_detector.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:watcher/watcher.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';
import '../../../src/test_flutter_command_runner.dart';
import 'utils/preview_project.dart';

const String _kProjectRootPath = '/project';
const String _kDartFilePath = '/project/lib/foo.dart';
const String _kNonDartFilePath = '/project/README.md';
const String _kPubspecPath = '/project/pubspec.yaml';
const String _kIgnoredDartToolPath = '/project/.dart_tool/package_config.json';

void main() {
  group('$LspPreviewDetector', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;
    late FakePlatform platform;
    late FakeAnalytics fakeAnalytics;
    late WidgetPreviewAnalytics previewAnalytics;
    late FakeFlutterProject project;
    late FakeWidgetPreviewDtdServices fakeDtd;
    late FakeWatcher fakeWatcher;
    late FakeAnalysisServer fakeAnalysisServer;
    late ShutdownHooks shutdownHooks;
    late List<FlutterWidgetPreviews> detectedChanges;
    late List<String> detectedPubspecChanges;
    late List<String> detectedNonDartFileChanges;
    late LspPreviewDetector detector;

    LspPreviewDetector createDetector({
      WidgetPreviewDtdServices? dtdOverride,
      FlutterProject? projectOverride,
      Platform? platformOverride,
      WatcherBuilder? watcherBuilderOverride,
    }) {
      return LspPreviewDetector(
        dtd: dtdOverride ?? fakeDtd,
        onChangeDetected: detectedChanges.add,
        onPubspecChangeDetected: detectedPubspecChanges.add,
        previewAnalytics: previewAnalytics,
        project: projectOverride ?? project,
        suppressAnalytics: false,
        toolContext: FakeToolContext(
          artifacts: Artifacts.test(),
          fs: fs,
          logger: logger,
          platform: platformOverride ?? platform,
          processManager: FakeProcessManager.any(),
          shutdownHooks: shutdownHooks,
        ),
        analysisServerFactory: () async => fakeAnalysisServer,
        onNonDartFileChangeDetected: detectedNonDartFileChanges.add,
        watcherBuilder: watcherBuilderOverride ?? (_) => fakeWatcher,
      );
    }

    setUp(() async {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
      platform = FakePlatform();
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fs,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
      previewAnalytics = WidgetPreviewAnalytics(analytics: fakeAnalytics);
      project = FakeFlutterProject(fs.directory(_kProjectRootPath));
      fakeDtd = FakeWidgetPreviewDtdServices();
      fakeWatcher = FakeWatcher();
      fakeAnalysisServer = FakeAnalysisServer();
      shutdownHooks = ShutdownHooks();
      detectedChanges = <FlutterWidgetPreviews>[];
      detectedPubspecChanges = <String>[];
      detectedNonDartFileChanges = <String>[];

      detector = createDetector();
      await detector.initialize();
    });

    tearDown(() async {
      await detector.dispose();
      await fakeWatcher.close();
    });

    void expectNPreviewReloadTimingEvents(int n) {
      final Iterable<Event> reloadTimingEvents = fakeAnalytics.sentEvents.where(
        (Event e) =>
            e.eventData['workflow'] == WidgetPreviewAnalytics.kWorkflow &&
            e.eventData['variableName'] == WidgetPreviewAnalytics.kPreviewReloadTime,
      );
      expect(reloadTimingEvents, hasLength(n));
    }

    Future<void> emitEvent(WatchEvent event) async {
      fakeWatcher.emitEvent(event);
      await pumpEventQueue();
      await detector.mutex.runGuarded(() async {});
    }

    testWithoutContext('reports preview reload timing when files are modified', () async {
      expectNPreviewReloadTimingEvents(0);
      expect(detectedChanges, isEmpty);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

      expect(detectedChanges, hasLength(1));
      expectNPreviewReloadTimingEvents(1);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 1);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

      expect(detectedChanges, hasLength(2));
      expectNPreviewReloadTimingEvents(2);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 2);
    });

    testWithoutContext(
      'does not report preview reload timing when pubspec.yaml is modified',
      () async {
        expectNPreviewReloadTimingEvents(0);
        expect(detectedPubspecChanges, isEmpty);

        await emitEvent(WatchEvent(ChangeType.MODIFY, _kPubspecPath));

        expect(detectedPubspecChanges, <String>[_kPubspecPath]);
        expectNPreviewReloadTimingEvents(0);
        expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
      },
    );

    testWithoutContext('notifies onNonDartFileChangeDetected and does not report preview reload timing when non-Dart file is modified', () async {
      expectNPreviewReloadTimingEvents(0);
      expect(detectedChanges, isEmpty);
      expect(detectedPubspecChanges, isEmpty);
      expect(detectedNonDartFileChanges, isEmpty);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kNonDartFilePath));

      expect(detectedChanges, isEmpty);
      expect(detectedPubspecChanges, isEmpty);
      expect(detectedNonDartFileChanges, <String>[_kNonDartFilePath]);
      expectNPreviewReloadTimingEvents(0);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    testWithoutContext('does not report preview reload timing for ignored directories', () async {
      expectNPreviewReloadTimingEvents(0);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kIgnoredDartToolPath));

      expect(detectedChanges, isEmpty);
      expect(detectedPubspecChanges, isEmpty);
      expect(detectedNonDartFileChanges, isEmpty);
      expectNPreviewReloadTimingEvents(0);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    testWithoutContext(
      'resets reload timing stopwatch on DTD exception and does not report timing',
      () async {
        fakeDtd.shouldThrow = true;
        expectNPreviewReloadTimingEvents(0);

        await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

        expect(detectedChanges, isEmpty);
        expectNPreviewReloadTimingEvents(0);

        fakeDtd.shouldThrow = false;
        await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

        expect(detectedChanges, hasLength(1));
        expectNPreviewReloadTimingEvents(1);
      },
    );

    testWithoutContext(
      'resets reload timing stopwatch on analysis server exception and does not report timing',
      () async {
        fakeAnalysisServer.shouldThrow = true;
        expectNPreviewReloadTimingEvents(0);

        await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

        expect(detectedChanges, isEmpty);
        expectNPreviewReloadTimingEvents(0);

        fakeAnalysisServer.shouldThrow = false;
        await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

        expect(detectedChanges, hasLength(1));
        expectNPreviewReloadTimingEvents(1);
      },
    );

    testWithoutContext('does not launch analysis server and waits for analysis over DTD when connected to an existing DTD instance', () async {
      await detector.dispose();

      fakeDtd = FakeWidgetPreviewDtdServices()..dtdUri = Uri.parse('ws://127.0.0.1:12345');
      detector = createDetector();
      await detector.initialize();

      expect(detector.analysisServer, isNull);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
      expect(fakeDtd.waitForAnalysisCallCount, 0);

      await detector.waitForAnalysis();
      expect(fakeDtd.waitForAnalysisCallCount, 1);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
      expect(detectedChanges, hasLength(1));
      expect(fakeDtd.waitForAnalysisCallCount, 2);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    testWithoutContext(
      'handles Windows directory watcher unexpected close error and rethrows other watcher errors',
      () async {
        // Regression test for https://github.com/flutter/flutter/issues/173895.
        await detector.dispose();

        final windowsWatcher = FakeWatcher();
        addTearDown(windowsWatcher.close);
        detector = createDetector(
          dtdOverride: FakeWidgetPreviewDtdServices(),
          platformOverride: FakePlatform(operatingSystem: 'windows'),
          watcherBuilderOverride: (_) => windowsWatcher,
        );
        await detector.initialize();

        windowsWatcher.emitError(
          const FileSystemException(
            '${LspPreviewDetector.kDirectoryWatcherClosedUnexpectedlyPrefix}: test',
          ),
        );
        await pumpEventQueue();
        expect(logger.traceText, contains(LspPreviewDetector.kWindowsFileWatcherRestartedMessage));

        Future<List<Object>> collectUncaughtWatcherErrors({
          required Platform testPlatform,
          required FileSystemException exception,
        }) async {
          final unhandledErrors = <Object>[];
          await runZonedGuarded(
            () async {
              final errorWatcher = FakeWatcher();
              addTearDown(errorWatcher.close);
              final LspPreviewDetector errorDetector = createDetector(
                dtdOverride: FakeWidgetPreviewDtdServices(),
                platformOverride: testPlatform,
                watcherBuilderOverride: (_) => errorWatcher,
              );
              addTearDown(errorDetector.dispose);
              await errorDetector.initialize();
              errorWatcher.emitError(exception);
              await pumpEventQueue();
            },
            (Object error, StackTrace _) {
              unhandledErrors.add(error);
            },
          );
          return unhandledErrors;
        }

        // Unrelated FileSystemExceptions on Windows must still be rethrown.
        expect(
          await collectUncaughtWatcherErrors(
            testPlatform: FakePlatform(operatingSystem: 'windows'),
            exception: const FileSystemException('Access denied'),
          ),
          <Matcher>[isA<FileSystemException>()],
        );

        // On non-Windows platforms, directory watcher closed errors must also be rethrown.
        expect(
          await collectUncaughtWatcherErrors(
            testPlatform: FakePlatform(),
            exception: const FileSystemException(
              LspPreviewDetector.kDirectoryWatcherClosedUnexpectedlyPrefix,
            ),
          ),
          <Matcher>[isA<FileSystemException>()],
        );
      },
    );

    testWithoutContext(
      'ignores events in .widget_preview, ephemeralDirectories, and symlinked ephemeralDirectories',
      () async {
        // Regression test for https://github.com/flutter/flutter/issues/178317 and
        // https://github.com/flutter/flutter/issues/189849.
        await detector.dispose();

        final Directory realProjectDir = fs.directory('/real_project')..createSync();
        final FlutterProject realProject = FlutterProject.fromDirectoryTest(realProjectDir);
        expect(realProject.ephemeralDirectories, isNotEmpty);

        final Directory externalEphemeralTarget = fs.directory('/external_ephemeral')..createSync();
        final Link symlinkedEphemeralLink = fs.link('/real_project/symlinked_ephemeral')
          ..createSync(externalEphemeralTarget.path);
        final ephemeralDirs = <Directory>{
          ...realProject.ephemeralDirectories,
          fs.directory(symlinkedEphemeralLink.path),
        };

        final ephemeralWatcher = FakeWatcher();
        addTearDown(ephemeralWatcher.close);
        detector = createDetector(
          dtdOverride: FakeWidgetPreviewDtdServices(),
          projectOverride: FakeFlutterProject(realProjectDir, ephemeralDirectories: ephemeralDirs),
          watcherBuilderOverride: (_) => ephemeralWatcher,
        );
        await detector.initialize();

        Future<void> emitOnEphemeralWatcher(String path) async {
          ephemeralWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, path));
          await pumpEventQueue();
          await detector.mutex.runGuarded(() async {});
        }

        await emitOnEphemeralWatcher('/real_project/.widget_preview/lib/main.dart');
        for (final Directory dir in realProject.ephemeralDirectories) {
          await emitOnEphemeralWatcher(fs.path.join(dir.path, 'generated.dart'));
        }
        await emitOnEphemeralWatcher('/real_project/symlinked_ephemeral/generated.dart');
        await emitOnEphemeralWatcher('/external_ephemeral/generated.dart');

        expect(detectedChanges, isEmpty);
        expect(detectedPubspecChanges, isEmpty);
        expect(detectedNonDartFileChanges, isEmpty);
        expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
      },
    );

    testWithoutContext(
      'resolves relative and symlinked project.directory to canonical path',
      () async {
        await detector.dispose();

        final Directory realProjectDir = fs.directory('/canonical/my_app')
          ..createSync(recursive: true);
        final Directory workspaceDir = fs.directory('/workspace')..createSync();
        fs.link('/workspace/linked_app').createSync(realProjectDir.path);
        fs.currentDirectory = workspaceDir;

        String? watchedPath;
        final symlinkWatcher = FakeWatcher();
        addTearDown(symlinkWatcher.close);
        detector = createDetector(
          dtdOverride: FakeWidgetPreviewDtdServices(),
          projectOverride: FakeFlutterProject(fs.directory('linked_app')),
          watcherBuilderOverride: (String path) {
            watchedPath = path;
            return symlinkWatcher;
          },
        );
        await detector.initialize();

        expect(detector.projectRoot.path, realProjectDir.path);
        expect(watchedPath, realProjectDir.path);
      },
    );
  });

  group('$WidgetPreviewSubCommandBase.getRootProject', () {
    testWithoutContext(
      'resolves relative CLI paths and symlinked workspace roots to canonical directories',
      () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory canonicalWorkspaceDir = fs.directory('/canonical/workspace')
          ..createSync(recursive: true);
        final workspace = WidgetPreviewWorkspace(workspaceRoot: canonicalWorkspaceDir);
        await workspace.createWorkspaceProject(name: 'member_app');

        final Directory canonicalScaffold = canonicalWorkspaceDir.childDirectory('.widget_preview')
          ..createSync();
        expect(canonicalScaffold, exists);

        final Directory linksDir = fs.directory('/links')..createSync();
        fs.link('/links/ws_link').createSync(canonicalWorkspaceDir.path);
        fs.currentDirectory = linksDir;

        final cleanCommand = WidgetPreviewCleanCommand(
          toolContext: FakeToolContext(
            fs: fs,
            logger: logger,
            platform: FakePlatform(),
            processManager: FakeProcessManager.any(),
            projectFactory: FlutterProjectFactory(
              config: FakeConfig(),
              fileSystem: fs,
              logger: logger,
            ),
            signals: FakeSignals(),
          ),
        );
        await createTestCommandRunner(cleanCommand)
            .run(<String>['clean', fs.path.join('ws_link', 'packages', 'member_app')]);

        expect(canonicalScaffold, isNot(exists));
        expect(
          logger.statusText,
          contains('Deleting widget preview scaffold at ${canonicalScaffold.path}.'),
        );
      },
    );
  });
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject(this.directory, {this.ephemeralDirectories = const <Directory>{}});

  @override
  final Directory directory;

  @override
  void reloadManifest({Logger? logger, FileSystem? fs}) {}

  @override
  final Set<Directory> ephemeralDirectories;
}

class FakeWatcher extends Fake implements Watcher {
  final StreamController<WatchEvent> _events = StreamController<WatchEvent>.broadcast();

  @override
  Stream<WatchEvent> get events => _events.stream;

  @override
  Future<void> get ready => Future<void>.value();

  void emitEvent(WatchEvent event) => _events.add(event);

  void emitError(Object error, [StackTrace? stackTrace]) =>
      _events.addError(error, stackTrace ?? StackTrace.current);

  Future<void> close() => _events.close();
}

class FakeAnalysisServer extends Fake implements AnalysisServer {
  int waitForAnalysisCallCount = 0;
  bool shouldThrow = false;

  @override
  Future<void> start() async {}

  @override
  Future<void> connectToDtd({required Uri dtdUri}) async {}

  @override
  Future<bool?> dispose() async => true;

  @override
  Future<void> waitForAnalysis({Duration delay = const Duration(milliseconds: 100)}) async {
    if (shouldThrow) {
      throw StateError('Fake analysis server error');
    }
    waitForAnalysisCallCount++;
  }
}

class FakeWidgetPreviewDtdServices extends Fake implements WidgetPreviewDtdServices {
  @override
  Uri? dtdUri;

  int waitForAnalysisCallCount = 0;
  bool shouldThrow = false;
  FlutterWidgetPreviews? nextUpdate;

  @override
  Future<void> launchAndConnect({required AnalysisServer analysisServer}) async {
    dtdUri = Uri.parse('ws://127.0.0.1:12345');
  }

  @override
  Future<void> waitForAnalysis({Duration delay = const Duration(milliseconds: 100)}) async {
    if (shouldThrow) {
      throw StateError('Fake DTD error');
    }
    waitForAnalysisCallCount++;
  }

  @override
  Future<FlutterWidgetPreviews> getFlutterWidgetPreviews() async {
    if (shouldThrow) {
      throw StateError('Fake DTD error');
    }
    return nextUpdate ??
        const FlutterWidgetPreviews(
          namespaces: <String, String>{},
          previews: <FlutterWidgetPreviewDetails>[],
          scriptUris: <Uri>[],
        );
  }
}
