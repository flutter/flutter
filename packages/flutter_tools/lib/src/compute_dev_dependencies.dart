// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'convert.dart';
import 'project.dart';

/// Computes a collection of the transitive dependencies of [project].
///
/// For each dependency it is calculated if it is only in the transitive closure
/// of dev_depencies.
///
/// Does a search rooted in `project`, following the `dependencies` and
/// `dev_dependencies` of the pubspec to find the transitive dependencies of the
/// app (including the project itself). Will follow the `dev_dependencies` of
/// the [project] package.
List<Dependency> computeTransitiveDependencies(
  FlutterProject project,
  PackageConfig packageConfig,
  FileSystem fileSystem,
) {
  final _PackageGraph packageGraph;
  final File packageGraphFile = fileSystem.file(
    project.packageConfig.uri.resolve('package_graph.json'),
  );
  try {
    packageGraph = _PackageGraph.fromJson(jsonDecode(packageGraphFile.readAsStringSync()));
  } on IOException catch (e) {
    throwToolExit('''
Failed to load ${packageGraphFile.path}: $e
Try running `flutter pub get`''');
  } on FormatException catch (e) {
    throwToolExit('''
Failed to parse ${packageGraphFile.path}: $e
Try running `flutter pub get`''');
  }
  final String rootName = project.manifest.appName;

  final Map<String, Dependency> result = <String, Dependency>{};
  result[rootName] = Dependency(
    rootName,
    project.directory.uri,
    // While building the dependency graph we mark everything as
    // isExclusiveDevDependency. Afterwards we traverse the non-dev-dependency
    // part of the graph removing the marker.
    isExclusiveDevDependency: true,
  );

  final List<String>? dependencies = packageGraph.dependencies[project.manifest.appName];
  if (dependencies == null) {
    throwToolExit('''
Failed to parse ${packageGraphFile.path}: dependencies for `${project.manifest.appName}` missing.
Try running `flutter pub get`''');
  }
  final List<String>? devDependencies = packageGraph.devDependencies[project.manifest.appName];
  if (devDependencies == null) {
    throwToolExit('''
Failed to parse ${packageGraphFile.path}: devDependencies for `${project.manifest.appName}` missing.
Try running `flutter pub get`''');
  }
  final List<String> packageNamesToVisit = <String>[...dependencies, ...devDependencies];
  while (packageNamesToVisit.isNotEmpty) {
    final String current = packageNamesToVisit.removeLast();
    if (result.containsKey(current)) {
      continue;
    }

    final List<String>? dependencies = packageGraph.dependencies[current];

    if (dependencies == null) {
      throwToolExit('''
Failed to parse ${packageGraphFile.path}: dependencies for `$current` missing.
Try running `flutter pub get`''');
    }
    packageNamesToVisit.addAll(dependencies);

    result[current] = Dependency(
      current,
      packageConfig[current]!.root,
      isExclusiveDevDependency: true,
    );
  }

  // Do a second traversal of only the non-dev-dependencies, to patch up the
  // `isExclusiveDevDependency` property.
  final Set<String> visitedDependencies = <String>{};
  packageNamesToVisit.add(project.manifest.appName);
  while (packageNamesToVisit.isNotEmpty) {
    final String current = packageNamesToVisit.removeLast();
    if (!visitedDependencies.add(current)) {
      continue;
    }
    final Dependency? currentDependency = result[current];
    if (currentDependency == null) {
      continue;
    }
    result[current] = Dependency(
      currentDependency.name,
      currentDependency.rootUri,
      isExclusiveDevDependency: false,
    );
    packageNamesToVisit.addAll(packageGraph.dependencies[current]!);
  }
  return result.values.toList();
}

/// Represents a package that is a dependency of the app.
class Dependency {
  Dependency(this.name, this.rootUri, {required this.isExclusiveDevDependency});

  /// The name of the package.
  final String name;

  /// True if this dependency is in the transitive closure of the main app's
  /// `dev_dependencies`, and **not** in the transitive closure of the regular
  /// dependencies.
  final bool isExclusiveDevDependency;

  /// The location of the package. (Same level as its pubspec.yaml).
  final Uri rootUri;
}

class _PackageGraph {
  _PackageGraph(this.dependencies, this.devDependencies);

  /// Parses the .dart_tool/package_graph.json file.
  factory _PackageGraph.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Expected top level to be a map');
    }
    if (json['configVersion'] != 1) {
      throw const FormatException('expected configVersion to be 1');
    }
    final Object? packages = json['packages'];
    if (packages is! List<Object?>) {
      throw FormatException('expected `packages` to be a list, got $packages');
    }
    final Map<String, List<String>> dependencies = <String, List<String>>{};
    final Map<String, List<String>> devDependencies = <String, List<String>>{};
    for (final Object? package in packages) {
      if (package is! Map<String, Object?>) {
        throw const FormatException('Expected `package` to be a map');
      }
      final Object? name = package['name'];
      if (name is! String) {
        throw const FormatException('Expected `name` to be a string');
      }
      List<String> parseList(String section) {
        final Object? list = package[section];
        if (list == null) {
          return <String>[];
        }
        if (list is! List<Object?>) {
          throw FormatException('Expected `$section` to be a list got a $list');
        }
        for (final Object? i in list) {
          if (i is! String) {
            throw FormatException('Expected `$section` to be a list of strings');
          }
        }
        return list.cast<String>();
      }

      dependencies[name] = parseList('dependencies');
      devDependencies[name] = parseList('devDependencies');
    }
    return _PackageGraph(dependencies, devDependencies);
  }
  final Map<String, List<String>> dependencies;
  final Map<String, List<String>> devDependencies;
}
