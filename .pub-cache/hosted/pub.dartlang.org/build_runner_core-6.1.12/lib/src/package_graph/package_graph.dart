// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../util/constants.dart';

/// The SDK package, we filter this to the core libs and dev compiler
/// resources.
final _sdkPackageNode = PackageNode(
    r'$sdk',
    sdkPath,
    DependencyType.hosted,
    // A fake language version for the SDK, we don't allow you to read its
    // sources anyways, and invalidate the whole build if this changes.
    LanguageVersion(0, 0));

/// A graph of the package dependencies for an application.
class PackageGraph {
  /// The root application package.
  final PackageNode root;

  /// All [PackageNode]s indexed by package name.
  final Map<String, PackageNode> allPackages;

  PackageGraph._(this.root, Map<String, PackageNode> allPackages)
      : allPackages = Map.unmodifiable(
            Map<String, PackageNode>.from(allPackages)
              ..putIfAbsent(r'$sdk', () => _sdkPackageNode)) {
    if (!root.isRoot) {
      throw ArgumentError('Root node must indicate `isRoot`');
    }
    if (allPackages.values.where((n) => n != root).any((n) => n.isRoot)) {
      throw ArgumentError('No nodes other than the root may indicate `isRoot`');
    }
  }

  /// Creates a [PackageGraph] given the [root] [PackageNode].
  factory PackageGraph.fromRoot(PackageNode root) {
    final allPackages = <String, PackageNode>{root.name: root};

    void addDeps(PackageNode package) {
      for (var dep in package.dependencies) {
        if (allPackages.containsKey(dep.name)) continue;
        allPackages[dep.name] = dep;
        addDeps(dep);
      }
    }

    addDeps(root);

    return PackageGraph._(root, allPackages);
  }

  /// Creates a [PackageGraph] for the package whose top level directory lives
  /// at [packagePath] (no trailing slash).
  static Future<PackageGraph> forPath(String packagePath) async {
    /// Read in the pubspec file and parse it as yaml.
    final pubspec = File(p.join(packagePath, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw StateError(
          'Unable to generate package graph, no `pubspec.yaml` found. '
          'This program must be ran from the root directory of your package.');
    }
    final rootPubspec = _pubspecForPath(packagePath);
    final rootPackageName = rootPubspec['name'] as String;

    final packageConfig =
        await findPackageConfig(Directory(packagePath), recurse: false);

    final dependencyTypes = _parseDependencyTypes(packagePath);

    final nodes = <String, PackageNode>{};
    // A consistent package order _should_ mean a consistent order of build
    // phases. It's not a guarantee, but also not required for correctness, only
    // an optimization.
    final consistentlyOrderedPackages = packageConfig.packages.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final package in consistentlyOrderedPackages) {
      var isRoot = package.name == rootPackageName;
      nodes[package.name] = PackageNode(
          package.name,
          package.root.toFilePath(),
          isRoot ? DependencyType.path : dependencyTypes[package.name],
          package.languageVersion,
          isRoot: isRoot);
    }
    final rootNode = nodes[rootPackageName];
    rootNode.dependencies
        .addAll(_depsFromYaml(rootPubspec, isRoot: true).map((n) => nodes[n]));

    final packageDependencies = _parsePackageDependencies(
        packageConfig.packages.where((p) => p.name != rootPackageName));
    for (final packageName in packageDependencies.keys) {
      nodes[packageName]
          .dependencies
          .addAll(packageDependencies[packageName].map((n) => nodes[n]));
    }
    return PackageGraph._(rootNode, nodes);
  }

  /// Creates a [PackageGraph] for the package in which you are currently
  /// running.
  static Future<PackageGraph> forThisPackage() =>
      PackageGraph.forPath(p.current);

  /// Shorthand to get a package by name.
  PackageNode operator [](String packageName) => allPackages[packageName];

  @override
  String toString() {
    var buffer = StringBuffer();
    for (var package in allPackages.values) {
      buffer.writeln('$package');
    }
    return buffer.toString();
  }
}

/// A node in a [PackageGraph].
class PackageNode {
  /// The name of the package as listed in `pubspec.yaml`.
  final String name;

  /// The type of dependency being used to pull in this package.
  ///
  /// May be `null`.
  final DependencyType dependencyType;

  /// All the packages that this package directly depends on.
  final List<PackageNode> dependencies = [];

  /// The absolute path of the current version of this package.
  ///
  /// Paths are platform dependent.
  final String path;

  /// Whether this node is the [PackageGraph.root].
  final bool isRoot;

  final LanguageVersion languageVersion;

  PackageNode(this.name, String path, this.dependencyType, this.languageVersion,
      {bool isRoot})
      : path = _toAbsolute(path),
        isRoot = isRoot ?? false;

  @override
  String toString() => '''
  $name:
    type: $dependencyType
    path: $path
    dependencies: [${dependencies.map((d) => d.name).join(', ')}]''';

  /// Converts [path] to a canonical absolute path, returns `null` if given
  /// `null`.
  static String _toAbsolute(String path) =>
      (path == null) ? null : p.canonicalize(path);
}

/// The type of dependency being used. This dictates how the package should be
/// watched for changes.
enum DependencyType { github, path, hosted }

/// Parse the `pubspec.lock` file and return a Map from package name to the type
/// of dependency.
Map<String, DependencyType> _parseDependencyTypes(String rootPackagePath) {
  final pubspecLock = File(p.join(rootPackagePath, 'pubspec.lock'));
  if (!pubspecLock.existsSync()) {
    throw StateError(
        'Unable to generate package graph, no `pubspec.lock` found. '
        'This program must be ran from the root directory of your package.');
  }
  final dependencyTypes = <String, DependencyType>{};
  final dependencies = loadYaml(pubspecLock.readAsStringSync()) as YamlMap;
  for (final packageName in dependencies['packages'].keys) {
    final source = dependencies['packages'][packageName]['source'];
    dependencyTypes[packageName as String] =
        _dependencyTypeFromSource(source as String);
  }
  return dependencyTypes;
}

DependencyType _dependencyTypeFromSource(String source) {
  switch (source) {
    case 'git':
      return DependencyType.github;
    case 'hosted':
      return DependencyType.hosted;
    case 'path':
    case 'sdk': // Until Flutter supports another type, assum same as path.
      return DependencyType.path;
  }
  throw ArgumentError('Unable to determine dependency type:\n$source');
}

/// Read the pubspec for each package in [packages] and finds it's
/// dependencies.
Map<String, List<String>> _parsePackageDependencies(
    Iterable<Package> packages) {
  final dependencies = <String, List<String>>{};
  for (final package in packages) {
    final pubspec = _pubspecForPath(package.root.toFilePath());
    dependencies[package.name] = _depsFromYaml(pubspec);
  }
  return dependencies;
}

/// Gets the deps from a yaml file, omitting dependency_overrides.
List<String> _depsFromYaml(YamlMap yaml, {bool isRoot = false}) {
  var deps = <String>{
    ..._stringKeys(yaml['dependencies'] as Map),
    if (isRoot) ..._stringKeys(yaml['dev_dependencies'] as Map),
  };
  // A consistent package order _should_ mean a consistent order of build
  // phases. It's not a guarantee, but also not required for correctness, only
  // an optimization.
  return deps.toList()..sort();
}

Iterable<String> _stringKeys(Map m) =>
    m == null ? const [] : m.keys.cast<String>();

/// Should point to the top level directory for the package.
YamlMap _pubspecForPath(String absolutePath) {
  var pubspecPath = p.join(absolutePath, 'pubspec.yaml');
  var pubspec = File(pubspecPath);
  if (!pubspec.existsSync()) {
    throw StateError(
        'Unable to generate package graph, no `$pubspecPath` found.');
  }
  return loadYaml(pubspec.readAsStringSync()) as YamlMap;
}
