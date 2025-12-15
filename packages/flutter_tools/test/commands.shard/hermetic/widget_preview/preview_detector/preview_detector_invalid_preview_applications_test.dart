// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';

import '../../../../src/common.dart';
import '../utils/preview_details_matcher.dart';
import '../utils/preview_detector_test_utils.dart';
import '../utils/preview_project.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

/// Creates a project with files containing invalid preview applications.
class BasicProjectWithInvalidPreviews extends WidgetPreviewProject with ProjectWithPreviews {
  BasicProjectWithInvalidPreviews._({
    required super.projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) {
    initialize(pathsWithPreviews: pathsWithPreviews, pathsWithoutPreviews: pathsWithoutPreviews);
  }

  static Future<BasicProjectWithInvalidPreviews> create({
    required Directory projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) async {
    final project = BasicProjectWithInvalidPreviews._(
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


@Preview(name: 'Invalid preview on class declaration')
class ClassDeclaration extends StatelessWidget {
  @Preview(name: 'Invalid preview on constructor with required parameters')
  ClassDeclaration(int i);

  @Preview(name: 'Invalid preview on getter');
  int get foo => 1;

  @Preview(name: 'Invalid preview on setter');
  set foo(x) {
    print('foo set');
  };

  @Preview(name: 'Invalid preview on field')
  final int bar = 2;

  @Preview(name: 'Invalid preview on member function')
  Widget memberFunction() => Text('Member');

  @override
  Widget build(BuildContext context) => Text('Foo');
}

@Preview(name: 'Invalid preview on function with void return')
void previews() => Text('Foo');

@Preview(name: 'Invalid preview on function with parameter')
Widget foo(int bar) => Text('Foo');

@Preview(name: 'Invalid preview on extension')
extension on ClassDeclaration {}
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
    late BasicProjectWithInvalidPreviews project;

    testPreviewDetector('ignores invalid previews in existing files', (
      PreviewDetector previewDetector,
    ) async {
      project = await BasicProjectWithInvalidPreviews.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>['foo.dart'],
        pathsWithoutPreviews: <String>[],
      );
      final PreviewDependencyGraph mapping = await previewDetector.initialize();
      expectContainsPreviews(mapping, project.matcherMapping);
    });

    testPreviewDetector('ignores invalid previews in updated files', (
      PreviewDetector previewDetector,
    ) async {
      project = await BasicProjectWithInvalidPreviews.create(
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

    testPreviewDetector('ignores invalid previews in newly added files', (
      PreviewDetector previewDetector,
    ) async {
      project = await BasicProjectWithInvalidPreviews.create(
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
