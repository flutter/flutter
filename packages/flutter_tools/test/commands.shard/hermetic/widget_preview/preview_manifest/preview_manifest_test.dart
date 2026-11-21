// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/preview_manifest.dart';

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../utils/preview_project.dart';

void main() {
  group('$PreviewManifest', () {
    late FlutterProject rootProject;
    late PreviewManifest previewManifest;
    late Logger logger;

    // The version really doesn't matter, just the format.
    const kFakeSDKVersion = '2.1.0-dev.8.0.flutter-4312ae32';

    setUp(() {
      final fs = MemoryFileSystem.test();
      final manifest = FlutterManifest.empty(logger: BufferLogger.test());
      final Directory projectDir = fs.currentDirectory.childDirectory('project')..createSync();
      projectDir.childDirectory('lib/src').createSync(recursive: true);
      rootProject = FlutterProject(projectDir, manifest, manifest);
      logger = BufferLogger.test();
      previewManifest = PreviewManifest(
        logger: logger,
        rootProject: rootProject,
        fs: fs,
        cache: Cache.test(
          processManager: FakeProcessManager.any(),
          fileSystem: fs,
          platform: FakePlatform(version: kFakeSDKVersion),
        ),
      );
    });

    testUsingContext('generates a valid manifest', () async {
      previewManifest.generate();
      final manifest = json.decode(
        rootProject.widgetPreviewScaffold
            .childFile(PreviewManifest.previewManifestPath)
            .readAsStringSync(),
      ) as PreviewManifestContents;

      expect(manifest.containsKey(PreviewManifest.kPubspecHashes), true);
      expect(manifest.containsKey(PreviewManifest.kManifestVersion), true);
      expect(manifest.containsKey(PreviewManifest.kSdkVersion), true);
    });

    testUsingContext('identifies widget preview scaffold project needs to be generated', () {
      // The widget preview scaffold directory doesn't exist, so we should know that we need to
      // generate the project.
      expect(previewManifest.shouldGenerateProject(), true);

      // Populate the manifest. For this test, this has the side effect of creating the widget
      // preview scaffold project directory as well.
      previewManifest.generate();

      // The widget preview scaffold project directory should exist as well as the newly generated
      // preview manifest.
      expect(previewManifest.shouldGenerateProject(), false);

      // Simulate changing the SDK version and verify that we should regenerate the project.
      final PreviewManifest modified = previewManifest.copyWith(
        cache: Cache.test(
          processManager: FakeProcessManager.any(),
          platform: FakePlatform(version: '${kFakeSDKVersion}foo'),
        ),
      );

      const sdkMismatchMessage =
          'The existing Widget Preview Scaffold was generated with Dart SDK '
          'version 2.1.0 (build 2.1.0-dev.8.0 4312ae32), which does not match the current Dart '
          'SDK version (2.1.0 (build 2.1.0-dev.8.0 4312ae32foo)). Regenerating Widget Preview '
          'Scaffold.\n';
      expect(modified.shouldGenerateProject(), true);
      expect((modified.logger as BufferLogger).statusText, contains(sdkMismatchMessage));
    });

    testUsingContext('identifies root project pubspec has changed', () {
      // The widget preview scaffold directory doesn't exist, so we should know that we need to
      // generate the project.
      expect(previewManifest.shouldGenerateProject(), true);

      // Populate the manifest. For this test, this has the side effect of creating the widget
      // preview scaffold project directory as well.
      previewManifest.generate();

      // The widget preview scaffold project directory should exist as well as the newly generated
      // preview manifest.
      expect(previewManifest.shouldGenerateProject(), false);

      // Simulate changing the root project's pubspec.yaml and verify that we should regenerate
      // the widget preview scaffold's pubspec.yaml.
      rootProject.replacePubspec(
        rootProject.manifest.copyWith(
          logger: logger,
          shaders: <AssetsEntry>[AssetsEntry(uri: Uri.parse('Random'))],
        ),
      );
      expect(previewManifest.shouldRegeneratePubspec(), true);

      // Update the manifest to include the hash for the updated pubspec.yaml and verify that we
      // no longer need to regenerate the pubspec.
      previewManifest.updatePubspecHash();
      expect(previewManifest.shouldRegeneratePubspec(), false);
    });
  });

  group('$PreviewManifest - Workspace', () {
    const fakeSdkVersion = '2.1.0-dev.8.0.flutter-4312ae32';

    late MemoryFileSystem fs;
    late BufferLogger logger;
    late Directory workspaceDir;
    late WidgetPreviewWorkspace workspace;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
      workspaceDir = fs.directory('/workspace')..createSync();
      workspace = WidgetPreviewWorkspace(workspaceRoot: workspaceDir);
    });

    PreviewManifest createWorkspaceManifest() {
      final FlutterProject rootProject = FlutterProject.fromDirectory(workspaceDir, logger: logger);
      return PreviewManifest(
        logger: logger,
        rootProject: rootProject,
        fs: fs,
        cache: Cache.test(
          processManager: FakeProcessManager.any(),
          fileSystem: fs,
          platform: FakePlatform(version: fakeSdkVersion),
        ),
      );
    }

    testWithoutContext('can handle workspace entries that do not exist', () async {
      await workspace.createWorkspaceProject(name: 'foo');
      await workspace.createWorkspaceProject(name: 'bar');

      final PreviewManifest manifest = createWorkspaceManifest()..generate();
      final Set<String> originalWorkspacePubspecPaths = workspace.workspacePubspecPaths;
      expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

      // Add a new workspace project to the workspace pubspec without creating the project yet.
      await workspace.updatePubspec(injectNonExistentProject: 'baz');
      manifest.updatePubspecHash(updatedPubspecPath: workspace.pubspecAbsolutePath);
      expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

      // Create the newly added workspace project and verify its pubspec hash is recorded.
      final WidgetPreviewProject baz = await workspace.createWorkspaceProject(
        name: 'baz',
        updateWorkspacePubspec: false,
      );
      manifest.updatePubspecHash(updatedPubspecPath: baz.pubspecAbsolutePath);
      expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);
    });

    testWithoutContext(
      'can handle the addition of new workspace projects before the workspace pubspec is updated',
      () async {
        await workspace.createWorkspaceProject(name: 'foo');
        await workspace.createWorkspaceProject(name: 'bar');

        final PreviewManifest manifest = createWorkspaceManifest()..generate();
        final Set<String> originalWorkspacePubspecPaths = workspace.workspacePubspecPaths;
        expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

        // Create a subproject before adding it to the root workspace pubspec.
        final WidgetPreviewProject baz = await workspace.createWorkspaceProject(
          name: 'baz',
          updateWorkspacePubspec: false,
        );
        manifest.updatePubspecHash(updatedPubspecPath: baz.pubspecAbsolutePath);
        expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

        // Update the root workspace pubspec to include the new project.
        await workspace.updatePubspec();
        manifest.updatePubspecHash(updatedPubspecPath: workspace.pubspecAbsolutePath);
        expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);
      },
    );

    testWithoutContext('can handle the removal of workspace projects', () async {
      await workspace.createWorkspaceProject(name: 'foo');
      final WidgetPreviewProject bar = await workspace.createWorkspaceProject(name: 'bar');
      final String barPubspecPath = bar.pubspecAbsolutePath;

      final PreviewManifest manifest = createWorkspaceManifest()..generate();
      final Set<String> originalWorkspacePubspecPaths = workspace.workspacePubspecPaths;
      expect(manifest.pubspecHashes.keys, originalWorkspacePubspecPaths);

      // Delete the subproject directory before updating the workspace pubspec.
      await workspace.deleteWorkspaceProject(name: 'bar', updateWorkspacePubspec: false);
      manifest.updatePubspecHash(updatedPubspecPath: barPubspecPath);
      expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);

      // Update the workspace pubspec to remove the deleted project.
      await workspace.updatePubspec();
      manifest.updatePubspecHash(updatedPubspecPath: workspace.pubspecAbsolutePath);
      expect(manifest.pubspecHashes.keys, workspace.workspacePubspecPaths);
    });
  });
}
