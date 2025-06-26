// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';

import 'preview_project.dart';

bool _stateInitialized = false;

// Global state that must be cleaned up by `tearDown` in initializeTestPreviewDetectorState.
void Function(PreviewDependencyGraph)? _onChangeDetectedImpl;
void Function()? _onPubspecChangeDetected;
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

PreviewDetector createTestPreviewDetector() {
  if (!_stateInitialized) {
    throw StateError('$initializeTestPreviewDetectorState was not called!');
  }
  _projectRoot = _fs.systemTempDirectory.createTempSync('root');
  return PreviewDetector(
    projectRoot: _projectRoot!,
    logger: BufferLogger.test(),
    fs: _fs,
    onChangeDetected: _onChangeDetectedRoot,
    onPubspecChangeDetected: _onPubspecChangeDetectedRoot,
  );
}

void _onChangeDetectedRoot(PreviewDependencyGraph mapping) {
  _onChangeDetectedImpl!(mapping);
}

void _onPubspecChangeDetectedRoot() {
  _onPubspecChangeDetected!();
}

/// Test the files included in [filesWithErrors] contain errors after executing [changeOperation].
Future<void> expectHasErrors({
  required void Function() changeOperation,
  required Set<WidgetPreviewSourceFile> filesWithErrors,
}) async {
  await waitForChangeDetected(
    onChangeDetected:
        (PreviewDependencyGraph updated) => expectPreviewDependencyGraphIsWellFormed(
          updated,
          expectedFilesWithErrors: filesWithErrors,
        ),
    changeOperation: changeOperation,
  );
}

/// Test dependency graph generated as a result of [changeOperation] contains no compile time
/// errors.
Future<void> expectHasNoErrors({required void Function() changeOperation}) async {
  await expectHasErrors(
    changeOperation: changeOperation,
    filesWithErrors: const <WidgetPreviewSourceFile>{},
  );
}

/// Waits for a pubspec changed event to be detected after executing [changeOperation].
Future<void> waitForPubspecChangeDetected({required void Function() changeOperation}) async {
  final Completer<void> completer = Completer<void>();
  _onPubspecChangeDetected = () {
    if (completer.isCompleted) {
      return;
    }
    completer.complete();
  };
  changeOperation();
  await completer.future;
}

/// Waits for a change detected event after executing [changeOperation].
///
/// Invokes [onChangeDetected] when a change is detected before the returned future is completed.
Future<void> waitForChangeDetected({
  required void Function(PreviewDependencyGraph) onChangeDetected,
  required void Function() changeOperation,
}) async {
  final Completer<void> completer = Completer<void>();
  _onChangeDetectedImpl = (PreviewDependencyGraph updated) {
    if (completer.isCompleted) {
      return;
    }
    onChangeDetected(updated);
    completer.complete();
  };
  changeOperation();
  await completer.future;
}

/// Waits for [n] change detected events after executing [changeOperation].
Future<void> waitForNChangesDetected({
  required int n,
  required void Function() changeOperation,
}) async {
  int changeCount = 0;
  final Completer<void> completer = Completer<void>();
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

/// Walks the [graph] to verify its structure and that all files contained in
/// [expectedFilesWithErrors] actually contain errors.
void expectPreviewDependencyGraphIsWellFormed(
  PreviewDependencyGraph graph, {
  Set<WidgetPreviewSourceFile> expectedFilesWithErrors = const <WidgetPreviewSourceFile>{},
}) {
  final Set<LibraryPreviewNode> nodesWithErrors = <LibraryPreviewNode>{};
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
  final Set<PreviewPath> filesWithTransitiveErrors = <PreviewPath>{};
  void dependencyHasErrorsValidator(LibraryPreviewNode node) {
    filesWithTransitiveErrors.add(node.path);
    expect(node.dependencyHasErrors, true);
    node.dependedOnBy.forEach(dependencyHasErrorsValidator);
  }

  for (final LibraryPreviewNode node in nodesWithErrors) {
    filesWithTransitiveErrors.add(node.path);
    node.dependedOnBy.forEach(dependencyHasErrorsValidator);
  }

  // Verify we've found all the files expected to have transitive errors.
  expect(
    filesWithTransitiveErrors,
    expectedFilesWithErrors
        .map(
          (WidgetPreviewSourceFile file) =>
              previewPathForFile(projectRoot: _projectRoot!, path: file.path),
        )
        .toSet(),
  );
}

String platformPath(List<String> pathSegments) =>
    pathSegments.join(const LocalPlatform().pathSeparator);
