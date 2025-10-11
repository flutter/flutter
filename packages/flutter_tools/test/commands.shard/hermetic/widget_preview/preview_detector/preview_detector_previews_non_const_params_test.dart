// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../utils/preview_details_matcher.dart';
import '../utils/preview_detector_test_utils.dart';
import '../utils/preview_project.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

/// Creates a project with files containing preview applications that have non-const parameters.
class ProjectWithPreviewsWithNonConstParams extends WidgetPreviewProject with ProjectWithPreviews {
  ProjectWithPreviewsWithNonConstParams._({
    required super.projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) {
    initialize(pathsWithPreviews: pathsWithPreviews, pathsWithoutPreviews: pathsWithoutPreviews);
  }

  static Future<ProjectWithPreviewsWithNonConstParams> create({
    required Directory projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) async {
    final project = ProjectWithPreviewsWithNonConstParams._(
      projectRoot: projectRoot,
      pathsWithPreviews: pathsWithPreviews,
      pathsWithoutPreviews: pathsWithoutPreviews,
    );
    await project.initializePubspec();
    return project;
  }

  @override
  final nonPreviewContainingFileContents = '''
void main() {}
''';

  @override
  final previewContainingFileContents = '''
import 'package:flutter/widget_previews.dart';

class BrightnessPreview extends MultiPreview {
  const BrightnessPreview(this.value);

  final Object value;

  final List<Preview> previews = <Preview>[
    Preview(name: 'Light', brightness: Brightness.light, wrapper: (child) => child),
    Preview(name: 'Dark', brightness: Brightness.dark, wrapper: (child) => child),
  ];
}


class ClassDeclaration extends StatelessWidget {
  @BrightnessPreview(new Object())
  @Preview(theme: () => PreviewThemeData())
  ClassDeclaration();

  @override
  Widget build(BuildContext context) => Text('Foo');
}
''';

  @override
  List<PreviewDetailsMatcher> get expectedPreviewDetails => [];
}

void main() {
  initializeTestPreviewDetectorState();
  group('$PreviewDetector', () {
    // Note: we don't use a MemoryFileSystem since we don't have a way to
    // provide it to package:analyzer APIs without writing a significant amount
    // of wrapper logic.
    late PreviewDetector previewDetector;
    late ProjectWithPreviewsWithNonConstParams project;

    setUp(() {
      previewDetector = createTestPreviewDetector();
    });

    tearDown(() async {
      await previewDetector.dispose();
    });

    testUsingContext('ignores previews with non-const parameters in existing files', () async {
      project = await ProjectWithPreviewsWithNonConstParams.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>['foo.dart'],
        pathsWithoutPreviews: <String>[],
      );
      final PreviewDependencyGraph mapping = await previewDetector.initialize();
      expectContainsPreviews(mapping, project.matcherMapping);
    });

    testUsingContext('ignores previews with non-const parameters in updated files', () async {
      project = await ProjectWithPreviewsWithNonConstParams.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[],
        pathsWithoutPreviews: <String>['foo.dart'],
      );

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expectContainsPreviews(initialPreviews, project.matcherMapping);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // There should be no valid previews in foo.dart.
          expectContainsPreviews(updated, project.matcherMapping);
        },
        changeOperation: () => project.addPreviewContainingFile(path: 'foo.dart'),
      );
    });

    testUsingContext('ignores previews with non-const parameters in newly added files', () async {
      project = await ProjectWithPreviewsWithNonConstParams.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[],
        pathsWithoutPreviews: <String>[],
      );
      // The initial mapping should be empty as there's no files containing previews.
      const expectedInitialMapping = <PreviewPath, LibraryPreviewNode>{};

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, expectedInitialMapping);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // There should be no valid previews in baz.dart.
          expectContainsPreviews(updated, project.matcherMapping);
        },
        // Create baz.dart, which contains previews.
        changeOperation: () => project.addPreviewContainingFile(path: 'baz.dart'),
      );
    });
  });
}
