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
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
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

      detector = LspPreviewDetector(
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

    test('reports preview reload timing when files are modified', () async {
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

    test('does not report preview reload timing when pubspec.yaml is modified', () async {
      expectNPreviewReloadTimingEvents(0);
      expect(detectedPubspecChanges, isEmpty);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kPubspecPath));

      expect(detectedPubspecChanges, <String>[_kPubspecPath]);
      expectNPreviewReloadTimingEvents(0);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    test('ignores changes to pubspec.yaml in nested non-project directories', () async {
      expectNPreviewReloadTimingEvents(0);
      expect(detectedPubspecChanges, isEmpty);

      final String nestedPubspecPath = fs.path.join(
        _kProjectRootPath,
        '.claude',
        'worktrees',
        'foo',
        'pubspec.yaml',
      );

      await emitEvent(WatchEvent(ChangeType.MODIFY, nestedPubspecPath));

      expect(detectedPubspecChanges, isEmpty);
      expect(detectedNonDartFileChanges, isEmpty);
      expectNPreviewReloadTimingEvents(0);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    test('detects changes to glob-matched workspace member pubspec.yaml', () async {
      project.manifest = FlutterManifest.createFromString('''
name: workspace_root
workspace:
  - packages/*
''', logger: logger)!;
      final String newMemberPubspecPath = fs.path.join(
        _kProjectRootPath,
        'packages',
        'new_pkg',
        'pubspec.yaml',
      );
      fs.file(newMemberPubspecPath).createSync(recursive: true);

      await emitEvent(WatchEvent(ChangeType.ADD, newMemberPubspecPath));

      expect(detectedPubspecChanges, <String>[newMemberPubspecPath]);
      expect(detectedNonDartFileChanges, isEmpty);
      expectNPreviewReloadTimingEvents(0);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    test('ignores unlisted, hidden, and build pubspec.yaml with ** workspace', () async {
      project.manifest = FlutterManifest.createFromString('''
name: workspace_root
workspace:
  - "**"
''', logger: logger)!;
      final String unlistedPubspecPath = fs.path.join(
        _kProjectRootPath,
        'other',
        'pkg',
        'pubspec.yaml',
      );
      final String hiddenPubspecPath = fs.path.join(
        _kProjectRootPath,
        '.claude',
        'worktrees',
        'foo',
        'pubspec.yaml',
      );
      final String buildPubspecPath = fs.path.join(
        _kProjectRootPath,
        'build',
        'foo',
        'pubspec.yaml',
      );

      // Update manifest to a narrower pattern to verify unlisted paths are ignored.
      project.manifest = FlutterManifest.createFromString('''
name: workspace_root
workspace:
  - packages/*
''', logger: logger)!;
      await emitEvent(WatchEvent(ChangeType.MODIFY, unlistedPubspecPath));

      // Switch to '**' and verify hidden and build directories are still ignored.
      project.manifest = FlutterManifest.createFromString('''
name: workspace_root
workspace:
  - "**"
''', logger: logger)!;
      await emitEvent(WatchEvent(ChangeType.MODIFY, hiddenPubspecPath));
      await emitEvent(WatchEvent(ChangeType.MODIFY, buildPubspecPath));

      expect(detectedPubspecChanges, isEmpty);
      expect(detectedNonDartFileChanges, isEmpty);
      expectNPreviewReloadTimingEvents(0);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    test('detects pubspec.yaml changes when project root is symlinked', () async {
      final Directory realRoot = fs.directory('/private/var/folders/project')
        ..createSync(recursive: true);
      final Link symlinkRoot = fs.link('/var/folders/project')
        ..createSync(realRoot.path, recursive: true);
      final File realPubspec = realRoot.childFile('pubspec.yaml')
        ..writeAsStringSync('''
name: app
workspace:
  - packages/*
''');

      final symlinkProject = FakeFlutterProject(fs.directory(symlinkRoot.path));
      final symlinkWatcher = FakeWatcher();
      final symlinkPubspecChanges = <String>[];
      final symlinkDetector = LspPreviewDetector(
        dtd: fakeDtd,
        onChangeDetected: (_) {},
        onPubspecChangeDetected: symlinkPubspecChanges.add,
        previewAnalytics: previewAnalytics,
        project: symlinkProject,
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
        onNonDartFileChangeDetected: (_) {},
        watcherBuilder: (_) => symlinkWatcher,
      );
      addTearDown(() async {
        await symlinkDetector.dispose();
        await symlinkWatcher.close();
      });
      await symlinkDetector.initialize();

      symlinkWatcher.emitEvent(WatchEvent(ChangeType.MODIFY, realPubspec.path));
      // Simulate a deleted workspace member pubspec.yaml under the symlinked root
      // so _resolveSymlinksAndCanonicalize walks up to the existing ancestor.
      final String deletedMemberPubspec = fs.path.join(
        realRoot.path,
        'packages',
        'deleted_pkg',
        'pubspec.yaml',
      );
      symlinkWatcher.emitEvent(WatchEvent(ChangeType.REMOVE, deletedMemberPubspec));
      await pumpEventQueue();
      await symlinkDetector.mutex.runGuarded(() async {});

      expect(symlinkPubspecChanges, <String>[realPubspec.path, deletedMemberPubspec]);
    });

    test('notifies onNonDartFileChangeDetected and does not report preview reload timing when non-Dart file is modified', () async {
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

    test('does not report preview reload timing for ignored directories', () async {
      expectNPreviewReloadTimingEvents(0);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kIgnoredDartToolPath));

      expect(detectedChanges, isEmpty);
      expect(detectedPubspecChanges, isEmpty);
      expect(detectedNonDartFileChanges, isEmpty);
      expectNPreviewReloadTimingEvents(0);
      expect(fakeAnalysisServer.waitForAnalysisCallCount, 0);
    });

    test('resets reload timing stopwatch on DTD exception and does not report timing', () async {
      fakeDtd.shouldThrow = true;
      expectNPreviewReloadTimingEvents(0);

      await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

      expect(detectedChanges, isEmpty);
      expectNPreviewReloadTimingEvents(0);

      fakeDtd.shouldThrow = false;
      await emitEvent(WatchEvent(ChangeType.MODIFY, _kDartFilePath));

      expect(detectedChanges, hasLength(1));
      expectNPreviewReloadTimingEvents(1);
    });

    test(
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

    test('does not launch analysis server and waits for analysis over DTD when connected to an existing DTD instance', () async {
      await detector.dispose();

      fakeDtd = FakeWidgetPreviewDtdServices()..dtdUri = Uri.parse('ws://127.0.0.1:12345');
      detector = LspPreviewDetector(
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
        watcherBuilder: (_) => fakeWatcher,
      );
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
  FakeFlutterProject(this.directory)
    : manifest = FlutterManifest.empty(logger: BufferLogger.test());

  @override
  final Directory directory;

  @override
  FlutterManifest manifest;

  @override
  File get pubspecFile => directory.childFile('pubspec.yaml');

  @override
  List<FlutterProject> get workspaceProjects => const <FlutterProject>[];

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
