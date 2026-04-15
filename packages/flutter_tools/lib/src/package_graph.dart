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
) {
  final PackageGraph packageGraph = PackageGraph.load(project);

  final String rootName = project.manifest.appName;

  final result = <String, Dependency>{};
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
Failed to parse ${packageGraph.file.path}: dependencies for `${project.manifest.appName}` missing.
Try running `flutter pub get`''');
  }
  final List<String>? devDependencies = packageGraph.devDependencies[project.manifest.appName];
  if (devDependencies == null) {
    throwToolExit('''
Failed to parse ${packageGraph.file.path}: devDependencies for `${project.manifest.appName}` missing.
Try running `flutter pub get`''');
  }
  final packageNamesToVisit = <String>[...dependencies, ...devDependencies];
  while (packageNamesToVisit.isNotEmpty) {
    final String current = packageNamesToVisit.removeLast();
    if (result.containsKey(current)) {
      continue;
    }

    final List<String>? dependencies = packageGraph.dependencies[current];

    if (dependencies == null) {
      throwToolExit('''
Failed to parse ${packageGraph.file.path}: dependencies for `$current` missing.
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
  final visitedDependencies = <String>{};
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

class PackageGraph {
  PackageGraph(this.file, this.roots, this.dependencies, this.devDependencies);

  /// Parses the .dart_tool/package_graph.json file.
  factory PackageGraph.fromJson(File file, Object? json) {
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
    final List<String> roots = _parseList(json, 'roots');
    final dependencies = <String, List<String>>{};
    final devDependencies = <String, List<String>>{};
    for (final Object? package in packages) {
      if (package is! Map<String, Object?>) {
        throw const FormatException('Expected `package` to be a map');
      }
      final Object? name = package['name'];
      if (name is! String) {
        throw const FormatException('Expected `name` to be a string');
      }

      dependencies[name] = _parseList(package, 'dependencies');
      devDependencies[name] = _parseList(package, 'devDependencies');
    }
    return PackageGraph(file, roots, dependencies, devDependencies);
  }

  static PackageGraph load(FlutterProject project) {
    final File file = project.packageConfig.fileSystem.file(
      project.packageConfig.uri.resolve('package_graph.json'),
    );
    try {
      return PackageGraph.fromJson(file, jsonDecode(file.readAsStringSync()));
    } on IOException catch (e) {
      throwToolExit('''
Failed to load ${file.path}: $e
Try running `flutter pub get`''');
    } on FormatException catch (e) {
      throwToolExit('''
Failed to parse ${file.path}: $e
Try running `flutter pub get`''');
    }
  }

  /// The file this was parsed from.
  final File file;

  /// Names of all root packages in the workspace of this package graph.
  final List<String> roots;
  final Map<String, List<String>> dependencies;
  final Map<String, List<String>> devDependencies;

  static List<String> _parseList(Map<String, Object?> map, String section) {
    final Object? result = map[section];
    try {
      return (result as List<Object?>?)?.cast<String>() ?? <String>[];
    } on TypeError {
      throw FormatException('Expected `$section` to be a list of strings');
    }
  }
}
