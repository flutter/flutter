// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:flutter_tools/src/widget_preview/preview_manifest.dart';
import 'package:test/test.dart';

import '../../../../src/common.dart';
import '../utils/preview_detector_test_utils.dart';
import '../utils/preview_project.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

void main() {
  initializeTestPreviewDetectorState();
  group('$PreviewManifest - Workspace', () {
    testPreviewDetector('can handle workspace entries that do not exist', (
      PreviewDetector previewDetector,
    ) async {
      final workspace = WidgetPreviewWorkspace(workspaceRoot: previewDetector.projectRoot);

      await workspace.createWorkspaceProject(name: 'foo');
      await workspace.createWorkspaceProject(name: 'bar');

      final PreviewManifest manifest = createPreviewManifest()..generate();
      await previewDetector.initialize();

      // Verify the manifest contains pubspec hashes for each pubspec in the workspace.
      final Set<String> originalWorkspacePubspecPaths = workspace.workspacePubspecPaths;
      expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

      // Add a new workspace project to the workspace pubspec, but don't actually create the
      // project yet.
      String pubspecPath = await waitForPubspecChangeDetected(
        changeOperation: () => workspace.updatePubspec(injectNonExistentProject: 'baz'),
      );

      // Update the manifest and verify we haven't added any new pubspec hashes, since the new
      // workspace project hasn't been created yet.
      manifest.updatePubspecHash(updatedPubspecPath: pubspecPath);
      expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

      // Create the newly added workspace project.
      pubspecPath = await waitForPubspecChangeDetected(
        changeOperation: () =>
            workspace.createWorkspaceProject(name: 'baz', updateWorkspacePubspec: false),
      );

      // Update the manifest and verify that the new project now has a pubspec hash entry.
      manifest.updatePubspecHash(updatedPubspecPath: pubspecPath);
      expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);
    });

    testPreviewDetector(
      'can handle the addition of new workspace projects before the workspace pubspec is updated',
      (PreviewDetector previewDetector) async {
        final workspace = WidgetPreviewWorkspace(workspaceRoot: previewDetector.projectRoot);

        await workspace.createWorkspaceProject(name: 'foo');
        await workspace.createWorkspaceProject(name: 'bar');

        final PreviewManifest manifest = createPreviewManifest()..generate();
        await previewDetector.initialize();

        // Verify the manifest contains pubspec hashes for each pubspec in the workspace.
        final Set<String> originalWorkspacePubspecPaths = workspace.workspacePubspecPaths;
        expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

        // Add a new workspace project, but don't update the workspace's pubspec to include it
        // yet.
        String pubspecPath = await waitForPubspecChangeDetected(
          changeOperation: () =>
              workspace.createWorkspaceProject(name: 'baz', updateWorkspacePubspec: false),
        );

        // Update the manifest and verify we haven't added any new pubspec hashes, since the new
        // workspace project technically isn't part of the workspace yet.
        manifest.updatePubspecHash(updatedPubspecPath: pubspecPath);
        expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

        // Update the workspace to include the newly added project.
        pubspecPath = await waitForPubspecChangeDetected(
          changeOperation: () => workspace.updatePubspec(),
        );

        // Update the manifest and verify that the new project now has a pubspec hash entry.
        manifest.updatePubspecHash(updatedPubspecPath: pubspecPath);
        expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);
      },
    );

    testPreviewDetector('can handle the removal of workspace projects', (
      PreviewDetector previewDetector,
    ) async {
      final workspace = WidgetPreviewWorkspace(workspaceRoot: previewDetector.projectRoot);

      await workspace.createWorkspaceProject(name: 'foo');
      await workspace.createWorkspaceProject(name: 'bar');

      final PreviewManifest manifest = createPreviewManifest()..generate();
      await previewDetector.initialize();

      // Verify the manifest contains pubspec hashes for each pubspec in the workspace.
      final Set<String> originalWorkspacePubspecPaths = workspace.workspacePubspecPaths;
      expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

      // Add a new workspace project, but don't update the workspace's pubspec to include it
      // yet.
      String pubspecPath = await waitForPubspecChangeDetected(
        changeOperation: () =>
            workspace.deleteWorkspaceProject(name: 'bar', updateWorkspacePubspec: false),
      );

      // Update the manifest and verify we haven't added any new pubspec hashes, since the new
      // workspace project technically isn't part of the workspace yet.
      manifest.updatePubspecHash(updatedPubspecPath: pubspecPath);
      expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);

      // Update the workspace to include the newly added project.
      pubspecPath = await waitForPubspecChangeDetected(
        changeOperation: () => workspace.updatePubspec(),
      );

      // Update the manifest and verify that the new project now has a pubspec hash entry.
      manifest.updatePubspecHash(updatedPubspecPath: pubspecPath);
      expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);
    });
  });
}
