// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/preview_manifest.dart';
import 'package:flutter_tools/src/widget_preview/preview_pubspec_builder.dart';
import 'package:process/process.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';
import 'utils/preview_project.dart';

// Regression test for https://github.com/flutter/flutter/issues/176018.

void main() {
  group('$PreviewPubspecBuilder', () {
    late final LocalFileSystem fs;
    late final Directory root;
    late final Logger logger;
    late final ProcessManager processManager;

    setUp(() {
      fs = LocalFileSystem.test(signals: Signals.test());
      root = fs.systemTempDirectory.createTempSync();
      logger = BufferLogger.test();
      processManager = const LocalProcessManager();
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    testUsingContext(
      'creates dependency_overrides for previewed project dependencies',
      () async {
        const kPackageProjectName = 'abcd';
        const kExampleProjectName = 'example';
        final workspace = WidgetPreviewWorkspace(workspaceRoot: root);
        final WidgetPreviewProject packageProject = await workspace.createWorkspaceProject(
          name: kPackageProjectName,
        );
        final WidgetPreviewProject exampleProject = await workspace.createWorkspaceProject(
          name: kExampleProjectName,
        );

        // Add a dependency on the package project from the example project.
        exampleProject.writePubspec('''
${exampleProject.initialPubspecContents}
  ${packageProject.packageName}: # This resolves to the other package in the workspace
''');

        final FlutterProject rootProject = FlutterProject.fromDirectory(root);
        final pubspecBuilder = PreviewPubspecBuilder(
          logger: logger,
          verbose: true,
          offline: false,
          rootProject: rootProject,
          previewManifest: FakePreviewManifest(),
        );

        // Bare minimum initialization of the widget_preview_scaffold project.
        rootProject.widgetPreviewScaffold.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: widget_preview_scaffold
environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
''');

        // Populate .dart_tool/widget_preview_scaffold/pubspec.yaml with the dependencies on the
        // local projects.
        await pubspecBuilder.populatePreviewPubspec(rootProject: rootProject);
        final yaml =
            loadYaml(rootProject.widgetPreviewScaffoldProject.pubspecFile.readAsStringSync())
                as YamlMap;
        const expectedDependencies = <String, Object?>{
          'abcd': {'path': '../../packages/$kPackageProjectName'},
          'example': {'path': '../../packages/$kExampleProjectName'},
        };

        // The generated pubspec.yaml should have path dependencies on both the package and example
        // projects, but should also have dependency_overrides set to handle cases where one
        // project in a workspace depends on another without explicitly specifying a path
        // dependency (e.g., a dependency of the form "some_workspace_package: " with no version
        // constraint or path).
        if (yaml case {
          'dependencies': final YamlMap dependencies,
          'dependency_overrides': final YamlMap dependencyOverrides,
        }) {
          for (final MapEntry(key: package, value: constraint) in expectedDependencies.entries) {
            expect(dependencies[package], constraint);
            expect(dependencyOverrides[package], constraint);
          }
        } else {
          fail('''
Did not find the following dependencies for "dependencies" or "dependency_overrides":
$expectedDependencies

Actual pubspec:
$yaml
''');
        }
      },
      overrides: {
        Pub: () => Pub.test(
          fileSystem: fs,
          logger: logger,
          processManager: processManager,
          botDetector: const FakeBotDetector(true),
          platform: const LocalPlatform(),
          stdio: Stdio.test(stdout: stdout, stderr: stderr),
        ),
      },
    );
  });
}

class FakePreviewManifest extends Fake implements PreviewManifest {
  @override
  void updatePubspecHash({String? updatedPubspecPath}) {
    // Do nothing.
  }
}
