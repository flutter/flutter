// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';

/// An implementation of a context root.
class ContextRootImpl implements ContextRoot {
  @override
  final ResourceProvider resourceProvider;

  @override
  final Folder root;

  @override
  final Workspace workspace;

  @override
  final List<Resource> included = [];

  @override
  final List<Resource> excluded = [];

  /// A list of the globs for excluded files that were read from the analysis
  /// options file.
  List<LocatedGlob> excludedGlobs = [];

  @override
  File? optionsFile;

  @override
  File? packagesFile;

  /// Initialize a newly created context root.
  ContextRootImpl(this.resourceProvider, this.root, this.workspace);

  @override
  Iterable<String> get excludedPaths =>
      excluded.map((Resource folder) => folder.path);

  @override
  int get hashCode => root.path.hashCode;

  @override
  Iterable<String> get includedPaths =>
      included.map((Resource folder) => folder.path);

  @override
  bool operator ==(Object other) {
    return other is ContextRoot && root.path == other.root.path;
  }

  @override
  Iterable<String> analyzedFiles() sync* {
    var visited = <String>{};
    for (var includedPath in includedPaths) {
      var included = resourceProvider.getResource(includedPath);
      if (included is File) {
        yield includedPath;
      } else if (included is Folder) {
        yield* _includedFilesInFolder(visited, included, includedPath);
      } else {
        Type type = included.runtimeType;
        throw StateError('Unknown resource at path "$includedPath" ($type)');
      }
    }
  }

  @override
  bool isAnalyzed(String path) {
    for (var includedPath in includedPaths) {
      var included = resourceProvider.getResource(includedPath);
      if (included is File) {
        if (included.path == path) {
          return true;
        }
      } else if (included is Folder) {
        if (included.isOrContains(path)) {
          if (!_isExcluded(path, included.path)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Return the absolute paths of all of the files that are included in the
  /// given [folder]. Ignore globs that match the explicit [includedPath].
  Iterable<String> _includedFilesInFolder(
    Set<String> visited,
    Folder folder,
    String includedPath,
  ) sync* {
    List<Resource> children;
    try {
      children = folder.getChildren();
    } on FileSystemException {
      return;
    }

    for (Resource resource in children) {
      String path = resource.path;
      if (!_isExcluded(path, includedPath)) {
        if (resource is File) {
          yield path;
        } else if (resource is Folder) {
          String canonicalPath;
          try {
            canonicalPath = resource.resolveSymbolicLinksSync().path;
          } on FileSystemException {
            return;
          }
          if (visited.add(canonicalPath)) {
            yield* _includedFilesInFolder(visited, resource, includedPath);
            visited.remove(canonicalPath);
          }
        } else {
          Type type = resource.runtimeType;
          throw StateError('Unknown resource at path "$path" ($type)');
        }
      }
    }
  }

  /// Return `true` if the given [path] is not excluded by one of the
  /// [excludedPaths], or an applicable [excludedGlobs].
  ///
  /// This method is invoked while processing an explicitly [includedPath],
  /// and so we should ignore globs that would have excluded it.
  bool _isExcluded(String path, String includedPath) {
    Context context = resourceProvider.pathContext;

    for (var current = path; root.contains(current);) {
      if (context.basename(current).startsWith('.')) {
        return true;
      }
      current = context.dirname(current);
    }

    for (String excludedPath in excludedPaths) {
      if (context.isAbsolute(excludedPath)) {
        if (path == excludedPath || context.isWithin(excludedPath, path)) {
          return true;
        }
      } else {
        // The documentation claims that [excludedPaths] only contains absolute
        // paths, so we shouldn't be able to reach this point.
        for (String includedPath in includedPaths) {
          if (context.isWithin(
              context.join(includedPath, excludedPath), path)) {
            return true;
          }
        }
      }
    }

    for (final pattern in excludedGlobs) {
      if (!pattern.matches(includedPath) && pattern.matches(path)) {
        return true;
      }
    }

    return false;
  }
}

/// [Glob] to apply to resources inside the [parent].
class LocatedGlob {
  final Folder parent;
  final Glob glob;

  LocatedGlob(this.parent, this.glob);

  bool matches(String path) {
    if (parent.contains(path)) {
      final pathContext = parent.provider.pathContext;
      final relativePath = pathContext.relative(path, from: parent.path);
      return glob.matches(relativePath);
    }
    return false;
  }
}
