// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/preview_manifest.dart';
import 'package:flutter_tools/src/widget_preview/preview_pubspec_builder.dart';
import 'package:test/test.dart';
import 'package:test_api/fake.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/package_config.dart';

void main() {
  group('$PreviewPubspecBuilder', () {
    late MemoryFileSystem fileSystem;
    late ProcessManager processManager;
    late PreviewPubspecBuilder pubspecBuilder;
    late FlutterProject rootProject;
    late Logger logger;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      processManager = FakeProcessManager.any();
      logger = BufferLogger.test();
      rootProject = FakeFlutterProject(
        projectRoot: 'some_project',
        fileSystem: fileSystem,
        logger: logger,
      );
      pubspecBuilder = PreviewPubspecBuilder(
        logger: logger,
        verbose: false,
        offline: false,
        rootProject: rootProject,
        previewManifest: PreviewManifest(
          logger: logger,
          rootProject: rootProject,
          fs: fileSystem,
          cache: Cache.test(processManager: processManager),
        ),
      );
    });

    testUsingContext(
      'can create a pubspec.yaml for the preview scaffold including root project deferred components',
      () {
        final FlutterManifest root = rootProject.manifest;
        final FlutterManifest updated = pubspecBuilder.buildPubspec(
          rootProject: rootProject,
          widgetPreviewManifest: rootProject.widgetPreviewScaffoldProject.manifest,
        );

        expect(updated.deferredComponents?.length, root.deferredComponents?.length);
        if (root.deferredComponents != null) {
          for (var i = 0; i < root.deferredComponents!.length; ++i) {
            expect(
              updated.deferredComponents![i].toString(),
              PreviewPubspecBuilder.transformDeferredComponent(
                root.deferredComponents![i],
              ).toString(),
            );
          }
        }
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
      },
    );
  });
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({required this.projectRoot, required this.fileSystem, required this.logger});

  static const complexPubspec = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  generate: true
  assets:
    - path: foo
      flavors:
        - flavor
      transformers:
        - package: package:foo
          args:
            - arg
    - path: package/foo
  fonts:
    - family: fontFamily
      fonts:
        - weight: 100
          style: normal
          asset: assetUri
        - weight: 200
          style: italic
          asset: package/assetUri
  shaders:
    - shaderUri
  deferred-components:
    - name: deferredComponent
      libraries:
        - deferredComponentLibrary
      assets:
        - path: deferredComponentUri
          flavors:
            - deferredComponentFlavor
          transformers:
            - package: package:deferredComponent
              args:
                - deferredComponentArg
        - path: package/deferredComponentUri''';

  final String projectRoot;
  final FileSystem fileSystem;
  final Logger logger;

  @override
  late final FlutterManifest manifest = FlutterManifest.createFromPath(
    pubspecFile.path,
    fileSystem: fileSystem,
    logger: logger,
  )!;

  @override
  late FlutterProject widgetPreviewScaffoldProject = FakeFlutterProject(
    projectRoot: fileSystem.path.join(projectRoot, '.dart_tool', 'widget_preview_scaffold'),
    fileSystem: fileSystem,
    logger: logger,
  );

  @override
  late final File pubspecFile = () {
    final File file = fileSystem.directory(projectRoot).childFile('pubspec.yaml')
      ..createSync(recursive: true);
    file.writeAsStringSync(complexPubspec);
    return file;
  }();

  @override
  late final File packageConfig = () {
    return writePackageConfigFiles(
      directory: fileSystem.directory(projectRoot),
      mainLibName: 'my_app',
    );
  }();

  @override
  final workspaceProjects = <FlutterProject>[];
}
