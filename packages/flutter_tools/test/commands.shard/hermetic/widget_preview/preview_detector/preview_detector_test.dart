// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../utils/preview_details_matcher.dart';
import '../utils/preview_detector_test_utils.dart';
import '../utils/preview_project.dart';
import 'projects/basic_project_exhaustive_previews.dart';
import 'projects/multipreview_project.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

typedef PreviewProjectBuilder =
    Future<ProjectWithPreviews> Function({
      required Directory projectRoot,
      required List<String> pathsWithPreviews,
      required List<String> pathsWithoutPreviews,
    });

void main() {
  initializeTestPreviewDetectorState();
  group('$PreviewDetector', () {
    // Note: we don't use a MemoryFileSystem since we don't have a way to
    // provide it to package:analyzer APIs without writing a significant amount
    // of wrapper logic.
    late PreviewDetector previewDetector;
    late ProjectWithPreviews project;
    late FakeAnalytics analytics;

    setUp(() {
      previewDetector = createTestPreviewDetector();
      analytics = previewDetector.previewAnalytics.analytics as FakeAnalytics;
    });

    tearDown(() async {
      await previewDetector.dispose();
    });

    void expectNPreviewReloadTimingEvents(int n) {
      expect(analytics.sentEvents, hasLength(n));
      for (final Event event in analytics.sentEvents) {
        if (event.eventData case {
          'workflow': final String workflow,
          'variableName': final String variableName,
        }) {
          expect(workflow, WidgetPreviewAnalytics.kWorkflow);
          expect(variableName, WidgetPreviewAnalytics.kPreviewReloadTime);
        } else {
          throw StateError('${event.eventData} is missing keys!');
        }
      }
    }

    for (final MapEntry(key: previewType, value: createProject) in <String, PreviewProjectBuilder>{
      'previews': BasicProjectWithExhaustivePreviews.create,
      'multipreviews': MultiPreviewProject.create,
    }.entries) {
      testUsingContext('can detect $previewType in existing files', () async {
        project = await createProject(
          projectRoot: previewDetector.projectRoot,
          pathsWithPreviews: <String>[
            'foo.dart',
            platformPath(<String>['src', 'bar.dart']),
          ],
          pathsWithoutPreviews: <String>['baz'],
        );
        final PreviewDependencyGraph mapping = await previewDetector.initialize();
        expect(mapping.nodesWithPreviews.keys, unorderedMatches(project.librariesWithPreviews));
      });

      testUsingContext('can detect $previewType in updated files', () async {
        // Create two files with existing previews and one without.
        project = await createProject(
          projectRoot: previewDetector.projectRoot,
          pathsWithPreviews: <String>[
            'foo.dart',
            platformPath(<String>['src', 'bar.dart']),
          ],
          pathsWithoutPreviews: <String>['baz'],
        );

        // Initialize the file watcher.
        final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
        expectContainsPreviews(initialPreviews, project.matcherMapping);
        expectNPreviewReloadTimingEvents(0);

        await waitForChangeDetected(
          onChangeDetected: (PreviewDependencyGraph updated) {
            // The new preview in baz.dart should be included in the preview mapping.
            expectContainsPreviews(updated, project.matcherMapping);
          },
          changeOperation: () => project.addPreviewContainingFile(path: 'baz.dart'),
        );
        expectNPreviewReloadTimingEvents(1);

        // Update the file with an existing preview to remove the preview and ensure it triggers
        // the preview detector.
        await waitForChangeDetected(
          onChangeDetected: (PreviewDependencyGraph updated) {
            // The removed preview in baz.dart should not longer be included in the preview mapping.
            expectContainsPreviews(updated, project.matcherMapping);
          },
          changeOperation: () => project.addNonPreviewContainingFile(path: 'baz.dart'),
        );
        expectNPreviewReloadTimingEvents(2);
      });

      testUsingContext('can detect $previewType in newly added files', () async {
        project = await createProject(
          projectRoot: previewDetector.projectRoot,
          pathsWithPreviews: <String>[],
          pathsWithoutPreviews: <String>[],
        );
        // The initial mapping should be empty as there's no files containing previews.
        const expectedInitialMapping = <PreviewPath, LibraryPreviewNode>{};

        // Initialize the file watcher.
        final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
        expect(initialPreviews, expectedInitialMapping);
        expectNPreviewReloadTimingEvents(0);

        await waitForChangeDetected(
          onChangeDetected: (PreviewDependencyGraph updated) {
            // The new previews in baz.dart should be included in the preview mapping.
            expectContainsPreviews(updated, project.matcherMapping);
          },
          // Create baz.dart, which contains previews.
          changeOperation: () => project.addPreviewContainingFile(path: 'baz.dart'),
        );
        expectNPreviewReloadTimingEvents(1);
      });

      testUsingContext('can detect $previewType in existing libraries with parts', () async {
        project =
            await createProject(
                projectRoot: previewDetector.projectRoot,
                pathsWithPreviews: <String>[],
                pathsWithoutPreviews: <String>[],
              )
              ..addLibraryWithPartsContainingPreviews(path: 'foo.dart');
        final PreviewDependencyGraph mapping = await previewDetector.initialize();
        expect(mapping.nodesWithPreviews.keys, unorderedMatches(project.librariesWithPreviews));
      });

      testUsingContext('can detect $previewType in newly added libraries with parts', () async {
        project = await createProject(
          projectRoot: previewDetector.projectRoot,
          pathsWithPreviews: <String>[],
          pathsWithoutPreviews: <String>[],
        );
        // The initial mapping should be empty as there's no files containing previews.
        const expectedInitialMapping = <PreviewPath, LibraryPreviewNode>{};

        final PreviewDependencyGraph mapping = await previewDetector.initialize();
        expect(mapping.nodesWithPreviews, expectedInitialMapping);
        expectNPreviewReloadTimingEvents(0);

        // Add a library with a part file, which will cause a change detected event for each file.
        await waitForNChangesDetected(
          n: 2,
          changeOperation: () => project.addLibraryWithPartsContainingPreviews(path: 'foo.dart'),
        );
        final PreviewDependencyGraph nodesWithPreviews =
            previewDetector.dependencyGraph.nodesWithPreviews;
        expect(nodesWithPreviews, isNotEmpty);
        expect(nodesWithPreviews.keys, unorderedMatches(project.librariesWithPreviews));
        expectNPreviewReloadTimingEvents(2);
      });
    }

    testUsingContext('can detect changes in the pubspec.yaml', () async {
      // Create an initial pubspec.
      project = await BasicProjectWithExhaustivePreviews.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[],
        pathsWithoutPreviews: <String>[],
      );

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, isEmpty);

      // Change the contents of the pubspec and verify the callback is invoked.
      await waitForPubspecChangeDetected(changeOperation: () => project.touchPubspec());

      // There should be no reload timing events for a pubspec change.
      expectNPreviewReloadTimingEvents(0);
    });
  });
}
