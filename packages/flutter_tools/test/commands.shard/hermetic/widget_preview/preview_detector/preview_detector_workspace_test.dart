// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../utils/preview_detector_test_utils.dart';
import '../utils/preview_project.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

void main() {
  initializeTestPreviewDetectorState();
  group('$PreviewDetector - Workspace', () {
    // Note: we don't use a MemoryFileSystem since we don't have a way to
    // provide it to package:analyzer APIs without writing a significant amount
    // of wrapper logic.
    late PreviewDetector previewDetector;
    late WidgetPreviewWorkspace workspace;

    setUp(() {
      previewDetector = createTestPreviewDetector();
      workspace = WidgetPreviewWorkspace(workspaceRoot: previewDetector.projectRoot);
    });

    tearDown(() async {
      await previewDetector.dispose();
    });

    const simplePreviewSource = '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'preview')
Widget preview() => Text('Hello world!');
''';

    const noPreviewSource = '''
import 'package:flutter/material.dart';

Widget foo() => Text('Hello world!');
''';

    testUsingContext(
      'can detect previews in existing files in multiple workspace projects',
      () async {
        (await workspace.createWorkspaceProject(
          name: 'foo',
        )).writeFile((path: 'foo.dart', source: simplePreviewSource));
        (await workspace.createWorkspaceProject(
          name: 'bar',
        )).writeFile((path: 'bar.dart', source: simplePreviewSource));

        final PreviewDependencyGraph mapping = await previewDetector.initialize();
        expect(mapping.nodesWithPreviews.length, 2);
      },
    );

    testUsingContext('can detect previews in updated files', () async {
      // Create two projects with existing previews and one without.
      (await workspace.createWorkspaceProject(
        name: 'foo',
      )).writeFile((path: 'foo.dart', source: simplePreviewSource));
      (await workspace.createWorkspaceProject(
        name: 'bar',
      )).writeFile((path: 'bar.dart', source: simplePreviewSource));

      final WidgetPreviewProject projectBaz = (await workspace.createWorkspaceProject(name: 'baz'))
        ..writeFile((path: 'baz.dart', source: noPreviewSource));

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews.nodesWithPreviews.length, 2);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The new preview in baz.dart should be included in the preview mapping.
          expect(updated.nodesWithPreviews.length, 3);
        },
        changeOperation: () =>
            projectBaz.writeFile((path: 'baz.dart', source: simplePreviewSource)),
      );

      // Update the file with an existing preview to remove the preview and ensure it triggers
      // the preview detector.
      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The removed preview in baz.dart should not longer be included in the preview mapping.
          expect(updated.nodesWithPreviews.length, 2);
        },
        changeOperation: () => projectBaz.writeFile((path: 'baz.dart', source: noPreviewSource)),
      );
    });

    testUsingContext('can detect previews in newly added projects', () async {
      // Create two projects with existing previews.
      (await workspace.createWorkspaceProject(
        name: 'foo',
      )).writeFile((path: 'foo.dart', source: simplePreviewSource));
      (await workspace.createWorkspaceProject(
        name: 'bar',
      )).writeFile((path: 'bar.dart', source: simplePreviewSource));

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews.nodesWithPreviews.length, 2);

      // Add a new project to the workspace with single preview and verify it's detected.
      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The new preview in baz.dart should be included in the preview mapping.
          expect(updated.nodesWithPreviews.length, 3);
        },
        changeOperation: () async =>
            (await workspace.createWorkspaceProject(name: 'baz'))
              ..writeFile((path: 'baz.dart', source: simplePreviewSource)),
      );
    });

    testUsingContext('can detect previews removed due to deleted project', () async {
      // Create three projects with existing previews.
      (await workspace.createWorkspaceProject(
        name: 'foo',
      )).writeFile((path: 'foo.dart', source: simplePreviewSource));
      (await workspace.createWorkspaceProject(
        name: 'bar',
      )).writeFile((path: 'bar.dart', source: simplePreviewSource));
      (await workspace.createWorkspaceProject(
        name: 'baz',
      )).writeFile((path: 'baz.dart', source: simplePreviewSource));

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews.nodesWithPreviews.length, 3);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The preview in baz.dart in the deleted project should be removed from the preview
          // mapping.
          expect(updated.nodesWithPreviews.length, 2);
        },
        // Delete the 'baz' project.
        changeOperation: () => workspace.deleteWorkspaceProject(name: 'baz'),
      );
    });

    testUsingContext("can detect changes in a subproject's pubspec.yaml", () async {
      // Create three empty projects in the same workspace.
      await workspace.createWorkspaceProject(name: 'foo');
      await workspace.createWorkspaceProject(name: 'bar');
      final WidgetPreviewProject bazProject = await workspace.createWorkspaceProject(name: 'baz');

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, isEmpty);

      // Change the contents of the pubspec and verify the callback is invoked for the right
      // pubspec.yaml.
      expect(
        await waitForPubspecChangeDetected(changeOperation: () => bazProject.touchPubspec()),
        bazProject.pubspecAbsolutePath,
      );
    });

    testUsingContext("can detect changes in a workspace's root pubspec.yaml", () async {
      // Create three empty projects in the same workspace.
      await workspace.createWorkspaceProject(name: 'foo');
      await workspace.createWorkspaceProject(name: 'bar');
      await workspace.createWorkspaceProject(name: 'baz');

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, isEmpty);

      // Change the contents of the pubspec and verify the callback is invoked for the right
      // pubspec.yaml.
      expect(
        await waitForPubspecChangeDetected(changeOperation: () => workspace.touchPubspec()),
        workspace.pubspecAbsolutePath,
      );
    });
  });
}
