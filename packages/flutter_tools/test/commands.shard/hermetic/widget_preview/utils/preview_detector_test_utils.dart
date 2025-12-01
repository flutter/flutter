// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:flutter_tools/src/widget_preview/preview_manifest.dart';
import 'package:meta/meta.dart';

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../../../../src/fakes.dart';
import 'preview_project.dart';

var _stateInitialized = false;

// Global state that must be cleaned up by `tearDown` in initializeTestPreviewDetectorState.
void Function(PreviewDependencyGraph)? _onChangeDetectedImpl;
void Function(String path)? _onPubspecChangeDetected;
Directory? _projectRoot;

late FileSystem _fs;

/// Registers setup and tear down logic for [PreviewDetector] tests.
///
/// Must be called before [createTestPreviewDetector] is invoked.
void initializeTestPreviewDetectorState() {
  setUp(() {
    _fs = LocalFileSystem.test(signals: Signals.test());
  });

  tearDown(() {
    _onChangeDetectedImpl = null;
    _onPubspecChangeDetected = null;
    _projectRoot?.deleteSync(recursive: true);
    _projectRoot = null;
  });

  _stateInitialized = true;
}

@isTest
void testPreviewDetector(
  String description,
  FutureOr<void> Function(PreviewDetector) testMethod, {
  Map<Type, Generator> overrides = const <Type, Generator>{},
}) {
  testUsingContext(
    description,
    () async {
      PreviewDetector? previewDetector;
      try {
        previewDetector = createTestPreviewDetector();
        await testMethod(previewDetector);
      } finally {
        await previewDetector?.dispose();
      }
    },
    overrides: {
      FlutterProjectFactory: () =>
          FlutterProjectFactory(fileSystem: _fs, logger: BufferLogger.test()),
    },
  );
}

PreviewDetector createTestPreviewDetector() {
  if (!_stateInitialized) {
    throw StateError('$initializeTestPreviewDetectorState was not called!');
  }
  _projectRoot = _fs.systemTempDirectory.createTempSync('root');
  final FlutterProject project = FlutterProject.fromDirectory(_projectRoot!);

  return PreviewDetector(
    platform: FakePlatform(),
    previewAnalytics: WidgetPreviewAnalytics(
      analytics: getInitializedFakeAnalyticsInstance(
        fakeFlutterVersion: FakeFlutterVersion(),
        // We don't care about anything written by fake analytics, so we're safe to use a different
        // file system here.
        fs: MemoryFileSystem.test(),
      ),
    ),
    project: project,
    logger: BufferLogger.test(),
    fs: _fs,
    onChangeDetected: _onChangeDetectedRoot,
    onPubspecChangeDetected: _onPubspecChangeDetectedRoot,
  );
}

PreviewManifest createPreviewManifest() {
  if (!_stateInitialized) {
    throw StateError('$initializeTestPreviewDetectorState was not called!');
  }
  return PreviewManifest(
    logger: BufferLogger.test(),
    rootProject: FlutterProject.fromDirectory(_projectRoot!),
    fs: _fs,
    cache: Cache.test(processManager: FakeProcessManager.any()),
  );
}

void _onChangeDetectedRoot(PreviewDependencyGraph mapping) {
  _onChangeDetectedImpl!(mapping);
}

void _onPubspecChangeDetectedRoot(String path) {
  _onPubspecChangeDetected?.call(path);
}

/// Test the files included in [filesWithErrors] contain errors after executing [changeOperation].
Future<void> expectHasErrors({
  required WidgetPreviewProject project,
  required void Function() changeOperation,
  required Set<WidgetPreviewSourceFile> filesWithErrors,
}) async {
  await waitForChangeDetected(
    onChangeDetected: (PreviewDependencyGraph updated) => expectPreviewDependencyGraphIsWellFormed(
      project: project,
      graph: updated,
      expectedFilesWithErrors: filesWithErrors,
    ),
    changeOperation: changeOperation,
  );
}

/// Test dependency graph generated as a result of [changeOperation] contains no compile time
/// errors.
Future<void> expectHasNoErrors({
  required WidgetPreviewProject project,
  required void Function() changeOperation,
}) async {
  await expectHasErrors(
    project: project,
    changeOperation: changeOperation,
    filesWithErrors: const <WidgetPreviewSourceFile>{},
  );
}

/// Waits for a pubspec changed event to be detected after executing [changeOperation].
Future<String> waitForPubspecChangeDetected({required void Function() changeOperation}) {
  final completer = Completer<String>();
  _onPubspecChangeDetected = (String path) {
    if (completer.isCompleted) {
      return;
    }
    completer.complete(path);
  };
  changeOperation();
  return completer.future;
}

/// Waits for a change detected event after executing [changeOperation].
///
/// Invokes [onChangeDetected] when a change is detected before the returned future is completed.
Future<void> waitForChangeDetected({
  required void Function(PreviewDependencyGraph) onChangeDetected,
  required FutureOr<void> Function() changeOperation,
}) async {
  final completer = Completer<void>();
  _onChangeDetectedImpl = (PreviewDependencyGraph updated) {
    if (completer.isCompleted) {
      return;
    }
    onChangeDetected(updated);
    completer.complete();
  };
  await changeOperation();
  await completer.future;
}

/// Waits for [n] change detected events after executing [changeOperation].
Future<void> waitForNChangesDetected({
  required int n,
  required void Function() changeOperation,
}) async {
  var changeCount = 0;
  final completer = Completer<void>();
  _onChangeDetectedImpl = (PreviewDependencyGraph updated) {
    if (completer.isCompleted) {
      return;
    }
    changeCount++;
    if (changeCount == n) {
      completer.complete();
    }
  };
  changeOperation();
  await completer.future;
}

extension PreviewDependencyGraphExtensions on PreviewDependencyGraph {
  /// Returns a subset of dependency graph consisting only of library nodes containing previews.
  PreviewDependencyGraph get nodesWithPreviews {
    return PreviewDependencyGraph.fromEntries(
      entries.where(
        (MapEntry<PreviewPath, LibraryPreviewNode> element) => element.value.previews.isNotEmpty,
      ),
    );
  }
}

/// Walks the [graph] to verify its structure and that all files contained in
/// [expectedFilesWithErrors] actually contain errors.
void expectPreviewDependencyGraphIsWellFormed({
  required WidgetPreviewProject project,
  required PreviewDependencyGraph graph,
  Set<WidgetPreviewSourceFile> expectedFilesWithErrors = const <WidgetPreviewSourceFile>{},
}) {
  final nodesWithErrors = <LibraryPreviewNode>{};
  for (final LibraryPreviewNode node in graph.values) {
    expect(_fs.file(node.path.path), exists);
    if (node.hasErrors) {
      nodesWithErrors.add(node);
    }
    for (final LibraryPreviewNode upstream in node.dependedOnBy) {
      expect(upstream.dependsOn, contains(node));
    }
    for (final LibraryPreviewNode downstream in node.dependsOn) {
      expect(downstream.dependedOnBy, contains(node));
    }
  }

  // Validates that all upstream dependencies are marked as having a transitive dependency
  // containing errors.
  final filesWithTransitiveErrors = <PreviewPath>{};
  void dependencyHasErrorsValidator(LibraryPreviewNode node) {
    filesWithTransitiveErrors.add(node.path);
    expect(node.dependencyHasErrors, true);
    node.dependedOnBy.forEach(dependencyHasErrorsValidator);
  }

  for (final node in nodesWithErrors) {
    filesWithTransitiveErrors.add(node.path);
    node.dependedOnBy.forEach(dependencyHasErrorsValidator);
  }

  // Verify we've found all the files expected to have transitive errors.
  expect(
    filesWithTransitiveErrors,
    expectedFilesWithErrors
        .map((WidgetPreviewSourceFile file) => project.toPreviewPath(file.path))
        .toSet(),
  );
}

String platformPath(List<String> pathSegments) =>
    pathSegments.join(const LocalPlatform().pathSeparator);

extension ScriptHelper on String {
  String get stripScriptUris =>
      replaceAll(RegExp(r"scriptUri:\s*'file:\/\/\/\S*',"), "scriptUri: 'STRIPPED',");
}
