// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:collection/collection.dart';

abstract class FileStateFilter {
  /// Return a filter of files that can be accessed by the [file].
  factory FileStateFilter(FileState file) {
    var workspacePackage = file.workspacePackage;
    if (workspacePackage is PubWorkspacePackage) {
      return _PubFilter(workspacePackage, file.path);
    } else {
      return _AnyFilter();
    }
  }

  bool shouldInclude(FileState file);
}

class _AnyFilter implements FileStateFilter {
  @override
  bool shouldInclude(FileState file) {
    var uri = file.uriProperties;
    if (uri.isDart) {
      return !uri.isDartInternal;
    }
    return true;
  }
}

class _PubFilter implements FileStateFilter {
  final PubWorkspacePackage targetPackage;
  final String? targetPackageName;
  final bool targetInLib;
  final Set<String> dependencies;

  factory _PubFilter(PubWorkspacePackage package, String path) {
    var inLib = package.workspace.provider
        .getFolder(package.root)
        .getChildAssumingFolder('lib')
        .contains(path);

    var dependencies = <String>{};
    var pubspec = package.pubspec;
    if (pubspec != null) {
      dependencies.addAll(pubspec.dependencies.names);
      if (!inLib) {
        dependencies.addAll(pubspec.devDependencies.names);
      }
    }

    return _PubFilter._(
      targetPackage: package,
      targetPackageName: pubspec?.name?.value.text,
      targetInLib: inLib,
      dependencies: dependencies,
    );
  }

  _PubFilter._({
    required this.targetPackage,
    required this.targetPackageName,
    required this.targetInLib,
    required this.dependencies,
  });

  @override
  bool shouldInclude(FileState file) {
    var uri = file.uriProperties;
    if (uri.isDart) {
      return !uri.isDartInternal;
    }

    // Normally only package URIs are available.
    // But outside of lib/ we allow any files of this package.
    var packageName = uri.packageName;
    if (packageName == null) {
      if (targetInLib) {
        return false;
      } else {
        var filePackage = file.workspacePackage;
        return filePackage is PubWorkspacePackage &&
            filePackage.root == targetPackage.root;
      }
    }

    // Any `package:` library from the same package.
    if (packageName == targetPackageName) {
      return true;
    }

    // If not the same package, must be public.
    if (uri.isSrc) {
      return false;
    }

    return dependencies.contains(packageName);
  }
}

extension on PSDependencyList? {
  List<String> get names {
    final self = this;
    if (self == null) {
      return const [];
    } else {
      return self
          .map((dependency) => dependency.name?.text)
          .whereNotNull()
          .toList();
    }
  }
}
