// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter_tools/src/widget_preview/preview_detector.dart';
library;

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:meta/meta.dart';

import '../../../../src/common.dart';

typedef WidgetPreviewSourceFile = ({String path, String source});

PreviewPath previewPathForFile({required Directory projectRoot, required String path}) {
  final File file = projectRoot.childDirectory('lib').childFile(path);
  return (path: file.path, uri: file.uri);
}

/// A utility class used to manage a fake Flutter project for widget preview testing.
class WidgetPreviewProject {
  WidgetPreviewProject({required this.projectRoot})
    : _libDirectory = projectRoot.childDirectory('lib')..createSync(recursive: true);

  /// The root of the fake project.
  ///
  /// This should always be set to [PreviewDetector.projectRoot].
  late final Directory projectRoot;
  late final Directory _libDirectory;

  Set<WidgetPreviewSourceFile> get currentSources => _currentSources.values.toSet();
  final Map<String, WidgetPreviewSourceFile> _currentSources = <String, WidgetPreviewSourceFile>{};

  Set<PreviewPath> get paths => _currentSources.keys.map(toPreviewPath).toSet();

  /// Builds a [PreviewPath] based on [path] using the [projectRoot]'s `lib/` directory as the
  /// path root.
  PreviewPath toPreviewPath(String path) =>
      previewPathForFile(projectRoot: projectRoot, path: path);

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
