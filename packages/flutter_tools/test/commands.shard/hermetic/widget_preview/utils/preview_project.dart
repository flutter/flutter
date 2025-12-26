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

  /// "Modifies" the workspace's pubspec.yaml.
  void touchPubspec() {
    _pubspecYaml.setLastModifiedSync(DateTime.now());
  }

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
    await savePackageConfig(
      PackageConfig(
        <Package>[
          for (final String package in [..._packages.keys, ?injectNonExistentProject])
            Package(package, workspaceRoot.childDirectory('packages').childDirectory(package).uri),
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
      workspaceRoot,
    );
  }
}

/// A utility class used to manage a fake Flutter project for widget preview testing.
class WidgetPreviewProject {
  WidgetPreviewProject({
    required this.projectRoot,
    this.packageName = 'foo',
    this.inWorkspace = false,
  }) : _libDirectory = projectRoot.childDirectory('lib')..createSync(recursive: true),
       _pubspecYaml = projectRoot.childFile(_kPubspec)..createSync();

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

  /// The current contents of the pubspec.yaml for the project.
  String get pubspecContents => _pubspecYaml.readAsStringSync();

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
    writePubspec(initialPubspecContents);
    final String flutterRoot = getFlutterRoot();
    await savePackageConfig(
      PackageConfig(
        <Package>[
          Package(packageName, projectRoot.uri),
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
      projectRoot,
    );
  }

  /// "Modifies" the project's pubspec.yaml.
  void touchPubspec() {
    _pubspecYaml.setLastModifiedSync(DateTime.now());
  }

  /// Updates the content of the project's pubspec.yaml.
  void writePubspec(String contents) {
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

/// A mixin for preview projects that support adding and removing libraries with previews.
mixin ProjectWithPreviews on WidgetPreviewProject {
  List<Matcher> get expectedPreviewDetails;

  String get previewContainingFileContents;

  String get nonPreviewContainingFileContents;

  Map<PreviewPath, List<Matcher>> get matcherMapping => <PreviewPath, List<Matcher>>{
    for (final PreviewPath path in librariesWithPreviews) path: expectedPreviewDetails,
  };

  final librariesWithPreviews = <PreviewPath>{};
  final librariesWithoutPreviews = <PreviewPath>{};

  void initialize({
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) {
    final initialSources = <WidgetPreviewSourceFile>[];
    for (final path in pathsWithPreviews) {
      initialSources.add((path: path, source: previewContainingFileContents));
      librariesWithPreviews.add(toPreviewPath(path));
    }
    for (final path in pathsWithoutPreviews) {
      initialSources.add((path: path, source: nonPreviewContainingFileContents));
      librariesWithoutPreviews.add(toPreviewPath(path));
    }
    initialSources.forEach(writeFile);
  }

  /// Adds a file containing previews at [path].
  void addPreviewContainingFile({required String path}) {
    writeFile((path: path, source: previewContainingFileContents));
    final PreviewPath previewPath = toPreviewPath(path);
    librariesWithoutPreviews.remove(previewPath);
    librariesWithPreviews.add(previewPath);
  }

  /// Adds a file with no previews at [path].
  void addNonPreviewContainingFile({required String path}) {
    writeFile((path: path, source: nonPreviewContainingFileContents));
    final PreviewPath previewPath = toPreviewPath(path);
    librariesWithPreviews.remove(previewPath);
    librariesWithoutPreviews.add(previewPath);
  }

  /// Adds a new library with a part at [path].
  ///
  /// If the file name specified by [path] is 'path.dart', the part file will be named
  /// 'path_part.dart'.
  void addLibraryWithPartsContainingPreviews({required String path}) {
    final String partPath = path.replaceAll('.dart', '_part.dart');
    writeFile((
      path: partPath,
      source:
          '''
part of '$path';

$previewContainingFileContents
''',
    ));

    writeFile((
      path: path,
      source:
          '''
part '$partPath';
''',
    ));
    final PreviewPath previewPath = toPreviewPath(path);
    librariesWithoutPreviews.remove(previewPath);
    librariesWithPreviews.add(previewPath);
  }
}
