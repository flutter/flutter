// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
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

    LspPreviewDetector createDetector() => LspPreviewDetector(
      dtd: fakeDtd,
      onChangeDetected: detectedChanges.add,
      onPubspecChangeDetected: detectedPubspecChanges.add,
      previewAnalytics: previewAnalytics,
      project: project,
      suppressAnalytics: false,
      toolContext: FakeToolContext(
        artifacts: Artifacts.test(),
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: FakeProcessManager.any(),
        shutdownHooks: shutdownHooks,
      ),
      analysisServerFactory: () async => fakeAnalysisServer,
      onNonDartFileChangeDetected: detectedNonDartFileChanges.add,
      watcherBuilder: (_) => fakeWatcher,
    );

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

    group('getFlutterWidgetPreviews requests', () {
      const previews = FlutterWidgetPreviews(
        namespaces: <String, String>{'a': 'package:foo/foo.dart'},
        previews: <FlutterWidgetPreviewDetails>[],
        scriptUris: <Uri>[],
      );

      // Timers and stream callbacks are bound to the zone they're created in, so the detector
      // under test has to be created and driven inside the FakeAsync zone.
      void runWithFakeAsyncDetector(
        void Function(FakeAsync time, LspPreviewDetector detector) body,
      ) {
        final originalWatcher = fakeWatcher;
        FakeAsync().run((FakeAsync time) {
          fakeDtd = FakeWidgetPreviewDtdServices()
            ..pendingRequests = <Completer<FlutterWidgetPreviews>>[];
          fakeWatcher = FakeWatcher();
          final LspPreviewDetector fakeAsyncDetector = createDetector();
          unawaited(fakeAsyncDetector.initialize());
          time.flushMicrotasks();

          body(time, fakeAsyncDetector);

          for (final Completer<FlutterWidgetPreviews> request in fakeDtd.pendingRequests!) {
            if (!request.isCompleted) {
              request.complete(previews);
            }
          }
          unawaited(fakeAsyncDetector.dispose());
          unawaited(fakeWatcher.close());
          time.flushMicrotasks();
        });
        fakeWatcher = originalWatcher;
      }

      testWithoutContext('applies a response that arrives after its request timed out', () {
        runWithFakeAsyncDetector((FakeAsync time, _) {
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          time.elapse(const Duration(seconds: 6));
          expect(fakeDtd.pendingRequests, hasLength(2));
          expect(detectedChanges, isEmpty);

          fakeDtd.pendingRequests!.first.complete(previews);
          time.flushMicrotasks();

          expect(detectedChanges, <FlutterWidgetPreviews>[previews]);
          expectNPreviewReloadTimingEvents(1);

          fakeDtd.pendingRequests!.last.complete(
            const FlutterWidgetPreviews(
              namespaces: <String, String>{},
              previews: <FlutterWidgetPreviewDetails>[],
              scriptUris: <Uri>[],
            ),
          );
          time.elapse(const Duration(minutes: 1));

          expect(fakeDtd.pendingRequests, hasLength(2));
          expect(detectedChanges, <FlutterWidgetPreviews>[previews]);
          expect(logger.warningText, isEmpty);
        });
      });

      testWithoutContext('applies a late response received while waiting to retry', () {
        runWithFakeAsyncDetector((FakeAsync time, _) {
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          time.elapse(const Duration(seconds: 5, milliseconds: 100));
          expect(fakeDtd.pendingRequests, hasLength(1));

          fakeDtd.pendingRequests!.single.complete(previews);
          time.elapse(const Duration(minutes: 1));

          expect(fakeDtd.pendingRequests, hasLength(1));
          expect(detectedChanges, <FlutterWidgetPreviews>[previews]);
          expect(logger.warningText, isEmpty);
        });
      });

      testWithoutContext('sends another request when one goes unanswered', () {
        runWithFakeAsyncDetector((FakeAsync time, _) {
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          time.elapse(const Duration(seconds: 4, milliseconds: 900));
          expect(fakeDtd.pendingRequests, hasLength(1));

          time.elapse(const Duration(milliseconds: 400));
          expect(fakeDtd.pendingRequests, hasLength(2));

          fakeDtd.pendingRequests!.last.complete(previews);
          time.flushMicrotasks();

          expect(detectedChanges, <FlutterWidgetPreviews>[previews]);
          expectNPreviewReloadTimingEvents(1);
          expect(logger.warningText, isEmpty);
        });
      });

      testWithoutContext('ignores a late error from a request that timed out', () {
        runWithFakeAsyncDetector((FakeAsync time, _) {
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          time.elapse(const Duration(seconds: 6));
          expect(fakeDtd.pendingRequests, hasLength(2));

          fakeDtd.pendingRequests!.first.completeError(StateError('Fake DTD error'));
          time.elapse(const Duration(seconds: 1));
          expect(fakeDtd.pendingRequests, hasLength(2));

          fakeDtd.pendingRequests!.last.complete(previews);
          time.flushMicrotasks();

          expect(detectedChanges, <FlutterWidgetPreviews>[previews]);
          expect(logger.warningText, isEmpty);
        });
      });

      testWithoutContext('retries immediately failing requests after a short delay', () {
        runWithFakeAsyncDetector((FakeAsync time, _) {
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          time.elapse(const Duration(milliseconds: 100));
          fakeDtd.pendingRequests!.single.completeError(StateError('Fake DTD error'));
          time.elapse(const Duration(milliseconds: 199));
          expect(fakeDtd.pendingRequests, hasLength(1));

          time.elapse(const Duration(milliseconds: 1));
          expect(fakeDtd.pendingRequests, hasLength(2));

          fakeDtd.pendingRequests!.last.complete(previews);
          time.flushMicrotasks();

          expect(detectedChanges, <FlutterWidgetPreviews>[previews]);
          expect(logger.warningText, isEmpty);
        });
      });

      testWithoutContext('warns and drops the update after five unanswered requests', () {
        runWithFakeAsyncDetector((FakeAsync time, _) {
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          // Five 5 second timeouts separated by four 200ms delays.
          time.elapse(const Duration(seconds: 25, milliseconds: 700));
          expect(fakeDtd.pendingRequests, hasLength(5));
          expect(logger.warningText, isEmpty);

          time.elapse(const Duration(milliseconds: 200));

          expect(logger.warningText, contains('Lost connection to the Dart Tooling Daemon (DTD)'));
          expect(logger.warningText, contains('TimeoutException'));
          expect(detectedChanges, isEmpty);
          expectNPreviewReloadTimingEvents(0);

          time.elapse(const Duration(minutes: 1));
          expect(fakeDtd.pendingRequests, hasLength(5));

          // The next change is processed normally once the analysis server responds again.
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          time.elapse(const Duration(seconds: 1));
          fakeDtd.pendingRequests!.last.complete(previews);
          time.flushMicrotasks();

          expect(fakeDtd.pendingRequests, hasLength(6));
          expect(detectedChanges, <FlutterWidgetPreviews>[previews]);
          expect('Lost connection'.allMatches(logger.warningText), hasLength(1));
        });
      });

      testWithoutContext('stops sending requests once disposed', () {
        runWithFakeAsyncDetector((FakeAsync time, LspPreviewDetector fakeAsyncDetector) {
          fakeWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));
          time.elapse(const Duration(seconds: 1));
          expect(fakeDtd.pendingRequests, hasLength(1));

          unawaited(fakeAsyncDetector.dispose());
          time.elapse(const Duration(minutes: 1));

          expect(fakeDtd.pendingRequests, hasLength(1));
          expect(detectedChanges, isEmpty);
          expect(logger.warningText, isEmpty);
        });
      });
    });

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
  });
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject(this.directory);

  @override
  final Directory directory;

  @override
  void reloadManifest({Logger? logger, FileSystem? fs}) {}

  @override
  Set<Directory> get ephemeralDirectories => const <Directory>{};
}

class FakeWatcher extends Fake implements Watcher {
  final StreamController<WatchEvent> _events = StreamController<WatchEvent>.broadcast();

  @override
  Stream<WatchEvent> get events => _events.stream;

  @override
  Future<void> get ready => Future<void>.value();

  void emitEvent(WatchEvent event) => _events.add(event);

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

  /// When non-null, [getFlutterWidgetPreviews] requests stay pending until completed by the test.
  List<Completer<FlutterWidgetPreviews>>? pendingRequests;

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
    if (pendingRequests case final List<Completer<FlutterWidgetPreviews>> pendingRequests) {
      final request = Completer<FlutterWidgetPreviews>();
      pendingRequests.add(request);
      return request.future;
    }
    return nextUpdate ??
        const FlutterWidgetPreviews(
          namespaces: <String, String>{},
          previews: <FlutterWidgetPreviewDetails>[],
          scriptUris: <Uri>[],
        );
  }
}
