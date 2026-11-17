// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:package_config/package_config.dart';

import '../../../../src/common.dart';

const _kPubspec = 'pubspec.yaml';

/// A utility class for working with Pub workspaces in Widget Preview tests.
class WidgetPreviewWorkspace {
  WidgetPreviewWorkspace({required this.workspaceRoot})
    : _packagesRoot = workspaceRoot.childDirectory('packages')..createSync(recursive: true),
      _pubspecYaml = workspaceRoot.childFile(_kPubspec)..createSync();

  final Directory workspaceRoot;
  final Directory _packagesRoot;
  final File _pubspecYaml;

  /// The set of directories that make up the workspace, including the workspace root.
  Set<Directory> get workspaceDirectories => {
    workspaceRoot,
    ..._packages.values.map((e) => e.projectRoot),
  };

  /// The set of paths to each pubspec in the workspace.
  Set<String> get workspacePubspecPaths => workspaceDirectories
      .map((e) => workspaceRoot.fileSystem.path.join(e.path, 'pubspec.yaml'))
      .toSet();

  final _packages = <String, WidgetPreviewProject>{};

  /// The absolute path to the workspace's pubspec.yaml.
  String get pubspecAbsolutePath => _pubspecYaml.absolute.path;

  Future<WidgetPreviewProject> createWorkspaceProject({
    required String name,
    bool updateWorkspacePubspec = true,
  }) async {
    if (_packages.containsKey(name)) {
      throw StateError('Project with name "$name" already exists.');
    }
    final project = WidgetPreviewProject(
      projectRoot: _packagesRoot.childDirectory(name)..createSync(),
      inWorkspace: true,
      packageName: name,
    );
    _packages[name] = project;
    project.writePubspec(project.initialPubspecContents);
    if (updateWorkspacePubspec) {
      await updatePubspec();
    }
    return project;
  }

  Future<void> deleteWorkspaceProject({
    required String name,
    bool updateWorkspacePubspec = true,
  }) async {
    if (!_packages.containsKey(name)) {
      throw StateError('Project with name "$name" does not exist.');
    }
    _packages.remove(name)!.projectRoot.deleteSync(recursive: true);
    if (updateWorkspacePubspec) {
      await updatePubspec();
    }
  }

  Future<void> updatePubspec({String? injectNonExistentProject}) async {
    final pubspec = StringBuffer('workspace:\n');
    for (final String package in [..._packages.keys, ?injectNonExistentProject]) {
      pubspec.writeln('  - packages/$package');
    }
    _pubspecYaml.writeAsStringSync(pubspec.toString());

    final String flutterRoot = getFlutterRoot();
    final Directory dartToolDir = workspaceRoot.childDirectory('.dart_tool')
      ..createSync(recursive: true);
    final configBuffer = StringBuffer();
    PackageConfig.writeString(
      PackageConfig(
        <Package>[
          for (final String package in [..._packages.keys, ?injectNonExistentProject])
            Package(
              package,
              workspaceRoot.childDirectory('packages').childDirectory(package).uri,
              packageUriRoot: Uri(path: 'lib/'),
            ),
          Package(
            'flutter',
            Uri(scheme: 'file', path: '$flutterRoot/packages/flutter/'),
            packageUriRoot: Uri(path: 'lib/'),
          ),
          Package(
            'flutter_localizations',
            Uri(scheme: 'file', path: '$flutterRoot/packages/flutter_localizations/'),
            packageUriRoot: Uri(path: 'lib/'),
          ),
          Package(
            'sky_engine',
            Uri(scheme: 'file', path: '$flutterRoot/bin/cache/pkg/sky_engine/'),
            packageUriRoot: Uri(path: 'lib/'),
          ),
        ],
        extraData: {'flutterRoot': 'file://$flutterRoot', 'flutterVersion': '3.33.0'},
      ),
      configBuffer,
      dartToolDir.uri,
    );
    dartToolDir.childFile('package_config.json').writeAsStringSync(configBuffer.toString());
  }
}

/// A utility class used to manage a fake Flutter project for widget preview testing.
class WidgetPreviewProject {
  WidgetPreviewProject({
    required this.projectRoot,
    this.packageName = 'foo',
    this.inWorkspace = false,
  }) : _pubspecYaml = projectRoot.childFile(_kPubspec)..createSync() {
    projectRoot.childDirectory('lib').createSync(recursive: true);
  }

  /// The name for the package defined by this project.
  final String packageName;

  /// The initial contents of the pubspec.yaml for the project.
  String get initialPubspecContents =>
      '''
name: $packageName

${inWorkspace ? 'resolution: workspace' : ''}

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
''';

  /// The root of the fake project.
  final Directory projectRoot;
  final File _pubspecYaml;

  /// The absolute path to the project's pubspec.yaml.
  String get pubspecAbsolutePath => _pubspecYaml.absolute.path;

  /// Set to true if the project is part of a workspace.
  final bool inWorkspace;

  /// Updates the content of the project's pubspec.yaml.
  void writePubspec(String contents) {
    projectRoot.childFile(_kPubspec)
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  }
}
