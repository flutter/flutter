// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
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
    late LspPreviewDetector detector;

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

      detector = LspPreviewDetector(
        platform: platform,
        previewAnalytics: previewAnalytics,
        project: project,
        fs: fs,
        logger: logger,
        onChangeDetected: detectedChanges.add,
        onPubspecChangeDetected: detectedPubspecChanges.add,
        dtd: fakeDtd,
        processManager: FakeProcessManager.any(),
        terminal: Terminal.test(),
        suppressAnalytics: false,
        artifacts: Artifacts.test(),
        shutdownHooks: shutdownHooks,
        watcherBuilder: (_) => fakeWatcher,
        analysisServerFactory: () async => fakeAnalysisServer,
      );
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

    testWithoutContext(
      'does not report preview reload timing when non-Dart file is modified',
      () async {
        expectNPreviewReloadTimingEvents(0);
        expect(detectedChanges, isEmpty);
        expect(detectedPubspecChanges, isEmpty);

        await emitEvent(WatchEvent(ChangeType.MODIFY, _kNonDartFilePath));

        expect(detectedChanges, isEmpty);
        expect(detectedPubspecChanges, isEmpty);
        expectNPreviewReloadTimingEvents(0);
        expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
      },
    );

    testWithoutContext('does not report preview reload timing for ignored directories', () async {
      expectNPreviewReloadTimingEvents(0);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kIgnoredDartToolPath));

      expect(detectedChanges, isEmpty);
      expect(detectedPubspecChanges, isEmpty);
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
  bool lspServiceAvailable = false;

  @override
  Uri get dtdUri => Uri.parse('ws://127.0.0.1:12345');

  bool shouldThrow = false;
  FlutterWidgetPreviews? nextUpdate;

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
