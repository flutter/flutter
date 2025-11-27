// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';

import '../../../src/common.dart';
import 'utils/preview_detector_test_utils.dart';
import 'utils/preview_project.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

WidgetPreviewSourceFile withUpdatedSource(WidgetPreviewSourceFile original, String source) =>
    (path: original.path, source: source);

void main() {
  initializeTestPreviewDetectorState();
  group('$PreviewDependencyGraph', () {
    // Note: we don't use a MemoryFileSystem since we don't have a way to
    // provide it to package:analyzer APIs without writing a significant amount
    // of wrapper logic.

    testPreviewDetector('dependency graph cycle smoke test', (
      PreviewDetector previewDetector,
    ) async {
      final project = WidgetPreviewProject(projectRoot: previewDetector.projectRoot);
      await project.initializePubspec();
      // Simple test to ensure graph cycles don't cause infinite recursion during traversal.
      <WidgetPreviewSourceFile>[
        (path: 'foo.dart', source: "import 'bar.dart';"),
        (path: 'bar.dart', source: "import 'foo.dart';"),
      ].forEach(project.writeFile);
      final PreviewDependencyGraph graph = await previewDetector.initialize();
      expect(graph.keys, containsAll(project.paths));
      expectPreviewDependencyGraphIsWellFormed(project: project, graph: graph);
    });

    group('library parts', () {
      const WidgetPreviewSourceFile main = (
        path: 'main.dart',
        source: '''
import 'src/lib.dart';

void main() {}
''',
      );
      final WidgetPreviewSourceFile lib = (
        path: platformPath(<String>['src', 'lib.dart']),
        source: '''
library lib;
part 'lib_part1.dart';
part 'lib_part2.dart';''',
      );
      final WidgetPreviewSourceFile libPart1 = (
        path: platformPath(<String>['src', 'lib_part1.dart']),
        source: '''
part of 'lib.dart';
''',
      );
      final WidgetPreviewSourceFile libPart2 = (
        path: platformPath(<String>['src', 'lib_part2.dart']),
        source: '''
part of 'lib.dart';
''',
      );

      final sources = <WidgetPreviewSourceFile>[main, lib, libPart1, libPart2];

      testPreviewDetector('smoke test', (PreviewDetector previewDetector) async {
        final project = WidgetPreviewProject(projectRoot: previewDetector.projectRoot);
        sources.forEach(project.writeFile);
        await project.initializePubspec();
        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();

        // Ensure that projects with libraries containing parts are handled correctly.
        expect(
          initialGraph.keys,
          containsAll(<PreviewPath>{
            project.toPreviewPath(main.path),
            project.toPreviewPath(lib.path),
          }),
        );
        expectPreviewDependencyGraphIsWellFormed(project: project, graph: initialGraph);
        expect(initialGraph[project.toPreviewPath(lib.path)]!.files, hasLength(3));
      });

      testPreviewDetector('with errors in parts', (PreviewDetector previewDetector) async {
        final project = WidgetPreviewProject(projectRoot: previewDetector.projectRoot);
        sources.forEach(project.writeFile);
        await project.initializePubspec();
        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expectPreviewDependencyGraphIsWellFormed(project: project, graph: initialGraph);

        // Introduce a compilation error into one of the library parts and verify that the library
        // and libraries that depend on it have errors.
        await expectHasErrors(
          project: project,
          changeOperation: () =>
              project.writeFile(withUpdatedSource(libPart1, '${libPart1.source}\ninvalid-symbol;')),
          filesWithErrors: <WidgetPreviewSourceFile>{main, lib},
        );

        // Fix the compilation error and verify that there's no longer any errors.
        await expectHasNoErrors(
          project: project,
          changeOperation: () => project.writeFile(libPart1),
        );
      });
    });

    group('dependency errors', () {
      const WidgetPreviewSourceFile main = (
        path: 'main.dart',
        source: '''
import 'foo.dart';
void main() => foo();
''',
      );
      const WidgetPreviewSourceFile foo = (
        path: 'foo.dart',
        source: '''
import 'bar.dart';
void foo() => bar();
''',
      );

      const WidgetPreviewSourceFile bar = (
        path: 'bar.dart',
        source: '''
void bar() => null;
''',
      );

      const sources = <WidgetPreviewSourceFile>[main, foo, bar];

      WidgetPreviewSourceFile toInvalidSource(WidgetPreviewSourceFile original) =>
          withUpdatedSource(original, 'invalid-symbol');

      testPreviewDetector('entire directory removed', (PreviewDetector previewDetector) async {
        final project = WidgetPreviewProject(projectRoot: previewDetector.projectRoot);
        sources.forEach(project.writeFile);
        await project.initializePubspec();
        String platformPath(List<String> pathSegments) =>
            pathSegments.join(const LocalPlatform().pathSeparator);
        final WidgetPreviewSourceFile a = (
          path: platformPath(<String>['dir', 'a.dart']),
          source: "import 'b.dart';",
        );
        final WidgetPreviewSourceFile b = (
          path: platformPath(<String>['dir', 'b.dart']),
          source: "import 'c.dart';",
        );
        final WidgetPreviewSourceFile c = (
          path: platformPath(<String>['dir', 'c.dart']),
          source: 'void foo() {}',
        );
        project
          ..writeFile(a)
          ..writeFile(b)
          ..writeFile(c);

        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expect(initialGraph.keys, containsAll(project.paths));

        // Validate the files in dir/ all have transistive errors.
        await expectHasErrors(
          project: project,
          changeOperation: () => project.writeFile(toInvalidSource(c)),
          filesWithErrors: <WidgetPreviewSourceFile>{a, b, c},
        );

        // Delete dir/. This will cause 3 change events to be reported, one for each file in the
        // deleted directory. Until all 3 events have been processed, the dependency graph will not
        // be consistent as the files have already been deleted on disk.
        await waitForNChangesDetected(
          n: 3,
          changeOperation: () => project.removeDirectoryContaining(a),
        );

        // Verify the graph is well formed once the deletion events have been processed.
        expectPreviewDependencyGraphIsWellFormed(project: project, graph: initialGraph);
      });

      testPreviewDetector('smoke test', (PreviewDetector previewDetector) async {
        final project = WidgetPreviewProject(projectRoot: previewDetector.projectRoot);
        sources.forEach(project.writeFile);
        await project.initializePubspec();
        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expect(initialGraph.keys, containsAll(project.paths));

        // Verify there's no errors in the project.
        for (final LibraryPreviewNode node in initialGraph.values) {
          expect(node.dependencyHasErrors, false);
          expect(node.hasErrors, false);
        }

        // Introduce an error into bar.dart and verify files that have transitive dependencies on
        // bar.dart are marked as having errors.
        await expectHasErrors(
          project: project,
          changeOperation: () => project.writeFile(toInvalidSource(bar)),
          filesWithErrors: project.currentSources,
        );

        // Remove the error from bar.dart and ensure no files have errors.
        await expectHasNoErrors(project: project, changeOperation: () => project.writeFile(bar));
      });

      testPreviewDetector('file with error added and removed', (
        PreviewDetector previewDetector,
      ) async {
        final project = WidgetPreviewProject(projectRoot: previewDetector.projectRoot);
        sources.forEach(project.writeFile);
        await project.initializePubspec();
        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expect(initialGraph.keys, containsAll(project.paths));

        // Verify there's no errors in the project.
        for (final LibraryPreviewNode node in initialGraph.values) {
          expect(node.dependencyHasErrors, false);
          expect(node.hasErrors, false);
        }

        // Add baz.dart, which contains errors. Since no other files import baz.dart, it should be
        // the only file with errors.
        const WidgetPreviewSourceFile baz = (path: 'baz.dart', source: 'invalid.symbol');
        await expectHasErrors(
          project: project,
          changeOperation: () => project.writeFile(baz),
          filesWithErrors: <WidgetPreviewSourceFile>{baz},
        );

        // Update main.dart to import baz.dart. All files in the project should now have transitive
        // errors.
        await expectHasErrors(
          project: project,
          changeOperation: () =>
              project.writeFile((path: main.path, source: "import '${baz.path}';\n${main.source}")),
          filesWithErrors: <WidgetPreviewSourceFile>{main, baz},
        );

        // Delete baz.dart. main.dart should continue to have an error.
        await expectHasErrors(
          project: project,
          changeOperation: () => project.removeFile(baz),
          filesWithErrors: <WidgetPreviewSourceFile>{main},
        );

        // Restore main.dart to remove the baz.dart import and clear the errors.
        await expectHasNoErrors(project: project, changeOperation: () => project.writeFile(main));
      });

      testPreviewDetector('error added into dependency in the middle of the graph and removed', (
        PreviewDetector previewDetector,
      ) async {
        final project = WidgetPreviewProject(projectRoot: previewDetector.projectRoot);
        sources.forEach(project.writeFile);
        await project.initializePubspec();
        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expect(initialGraph.keys, containsAll(project.paths));

        // Verify there's no errors in the project.
        for (final LibraryPreviewNode node in initialGraph.values) {
          expect(node.dependencyHasErrors, false);
          expect(node.hasErrors, false);
        }

        // Add baz.dart, which contains errors. Since no other files import baz.dart, it should be
        // the only file with errors.
        await expectHasErrors(
          project: project,
          changeOperation: () => project.writeFile(toInvalidSource(foo)),
          filesWithErrors: <WidgetPreviewSourceFile>{foo, main},
        );

        // Delete baz.dart. main.dart should continue to have an error.
        await expectHasNoErrors(project: project, changeOperation: () => project.writeFile(foo));
      });
    });
  });
}
