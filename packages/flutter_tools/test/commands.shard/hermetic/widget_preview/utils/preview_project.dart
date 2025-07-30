// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter_tools/src/widget_preview/preview_detector.dart';
library;

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';

import '../../../../src/common.dart';

typedef WidgetPreviewSourceFile = ({String path, String source});

const _kPubspec = 'pubspec.yaml';

class WidgetPreviewWorkspace {
  WidgetPreviewWorkspace({required this.workspaceRoot})
    : _packagesRoot = workspaceRoot.childDirectory('packages')..createSync(recursive: true),
      _pubspecYaml = workspaceRoot.childFile(_kPubspec)..createSync();

  final Directory workspaceRoot;
  final Directory _packagesRoot;
  final File _pubspecYaml;

  final _packages = <String, WidgetPreviewProject>{};

  /// The absolute path to the workspace's pubspec.yaml.
  String get pubspecAbsolutePath => _pubspecYaml.absolute.path;

  /// "Modifies" the workspace's pubspec.yaml.
  void touchPubspec() {
    _pubspecYaml.setLastModifiedSync(DateTime.now());
  }

  WidgetPreviewProject createWorkspaceProject({required String name}) {
    if (_packages.containsKey(name)) {
      throw StateError('Project with name "$name" already exists.');
    }
    final project = WidgetPreviewProject(
      projectRoot: _packagesRoot.childDirectory(name)..createSync(),
      inWorkspace: true,
    );
    project._writePubspec(project.pubspecContents);
    _packages[name] = project;
    _updatePubspec();
    return project;
  }

  void deleteWorkspaceProject({required String name}) {
    if (!_packages.containsKey(name)) {
      throw StateError('Project with name "$name" does not exist.');
    }
    _packages[name]!.projectRoot.deleteSync(recursive: true);
    _updatePubspec();
  }

  void _updatePubspec() {
    final pubspec = StringBuffer('workspace:\n');
    for (final String package in _packages.keys) {
      pubspec.writeln('  - packages/$package');
    }
    _pubspecYaml.writeAsStringSync(pubspec.toString());
  }
}

/// A utility class used to manage a fake Flutter project for widget preview testing.
class WidgetPreviewProject {
  WidgetPreviewProject({required this.projectRoot, this.inWorkspace = false})
    : _libDirectory = projectRoot.childDirectory('lib')..createSync(recursive: true),
      _pubspecYaml = projectRoot.childFile(_kPubspec)..createSync();

  /// The name for the package defined by this project.
  String get packageName => 'foo';

  /// The initial contents of the pubspec.yaml for the project.
  String get pubspecContents =>
      '''
name: $packageName

${inWorkspace ? 'resolution: workspace' : ''}

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
''';

  /// The root of the fake project.
  ///
  /// This should always be set to [PreviewDetector.projectRoot].
  late final Directory projectRoot;
  late final Directory _libDirectory;
  final File _pubspecYaml;

  /// The absolute path to the project's pubspec.yaml.
  String get pubspecAbsolutePath => _pubspecYaml.absolute.path;

  /// Set to true if the project is part of a workspace.
  final bool inWorkspace;

  Set<WidgetPreviewSourceFile> get currentSources => _currentSources.values.toSet();
  final _currentSources = <String, WidgetPreviewSourceFile>{};

  Set<PreviewPath> get paths => _currentSources.keys.map(toPreviewPath).toSet();

  /// Builds a [PreviewPath] based on [path] using the [projectRoot]'s `lib/` directory as the
  /// path root.
  PreviewPath toPreviewPath(String path) {
    final File file = _libDirectory.childFile(path);

    return (
      path: file.path,
      uri: PackageConfig(<Package>[Package(packageName, projectRoot.uri)]).toPackageUri(file.uri)!,
    );
  }

  /// Writes `pubspec.yaml` and `.dart_tool/package_config.json` at [projectRoot].
  Future<void> initializePubspec() async {
    _writePubspec(pubspecContents);

    await savePackageConfig(
      PackageConfig(<Package>[Package(packageName, projectRoot.uri)]),
      projectRoot,
    );
  }

  /// "Modifies" the project's pubspec.yaml.
  void touchPubspec() {
    _pubspecYaml.setLastModifiedSync(DateTime.now());
  }

  /// Updates the content of the project's pubspec.yaml.
  void _writePubspec(String contents) {
    projectRoot.childFile(_kPubspec)
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  /// Writes the contents of [file] to the file system.
  @mustCallSuper
  void writeFile(WidgetPreviewSourceFile file) {
    _libDirectory.childFile(file.path)
      ..createSync(recursive: true)
      ..writeAsStringSync(file.source);
    _currentSources[file.path] = file;
  }

  /// Removes the contents of [file] from the file system.
  @mustCallSuper
  void removeFile(WidgetPreviewSourceFile file) {
    _libDirectory.fileSystem.file(_libDirectory.childFile(file.path).path).deleteSync();
    _currentSources.remove(file.path);
  }

  /// Recursively deletes the parent directory of [file].
  @mustCallSuper
  void removeDirectoryContaining(WidgetPreviewSourceFile file) {
    final Context context = _libDirectory.fileSystem.path;
    final Directory dir = _libDirectory.childDirectory(context.dirname(file.path));
    _currentSources.removeWhere((String path, _) => path.startsWith(dir.path));
    dir.deleteSync(recursive: true);
  }
}
