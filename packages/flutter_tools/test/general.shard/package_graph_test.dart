// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/package_graph.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:package_config/package_config.dart';

import '../src/common.dart';

typedef Package = ({String name, List<String> dependencies, List<String> devDependencies});

// For all of these examples, imagine the following package structure:
//
// /
//   /my_app
//     pubspec.yaml
//   /package_a
//     pubspec.yaml
//   /package_b
//     pubspec.yaml
//   /package_c
//     pubspec.yaml
void main() {
  late FileSystem fileSystem;

  setUp(() {
    Cache.flutterRoot = '';
    fileSystem = MemoryFileSystem.test();
  });

  /// Write  pubspec.yaml files on [fileSystem] for each of the packages in
  /// [graph].
  ///
  /// Each pubspec is stored in `<packagename>/pubspec.yaml`.
  void writePubspecs(List<Package> graph) {
    final packageConfigMap = <String, Object?>{'configVersion': 2};
    for (final package in graph) {
      fileSystem.file(fileSystem.path.join(package.name, 'pubspec.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
name: ${package.name}
dependencies:
${package.dependencies.map((String d) => '  $d: {path: ../$d}').join('\n')}
dev_dependencies:
${package.devDependencies.map((String d) => '  $d: {path: ../$d}').join('\n')}
''');
      ((packageConfigMap['packages'] ??= <Object?>[]) as List<Object?>).add(<String, Object?>{
        'name': package.name,
        'rootUri': '../../${package.name}',
        'packageUri': 'lib/',
        'languageVersion': '3.7',
      });
    }
    fileSystem.file(fileSystem.path.join(graph.first.name, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(packageConfigMap));
  }

  void writePackageGraph(List<Package> graph) {
    fileSystem.file(fileSystem.path.join(graph.first.name, '.dart_tool', 'package_graph.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode(<String, Object?>{
          'configVersion': 1,
          'packages': <Object?>[
            for (final Package package in graph)
              <String, Object?>{
                'name': package.name,
                'dependencies': package.dependencies,
                'devDependencies': package.devDependencies,
              },
          ],
        }),
      );
  }

  /// Validates basic properties of `computeTransitiveDependencies` when run on
  /// pubspecs and package_config derrived from [graph] by `writePubspecs`.
  ///
  /// Validates all dependencies are found.
  ///
  /// And that exactly [exclusiveDevDependencies] are marked as
  /// exclusiveDevDependency.
  ///
  /// And that nothing is logged.
  Future<void> validatesComputeTransitiveDependencies(
    List<Package> graph,
    List<String> exclusiveDevDependencies,
  ) async {
    writePubspecs(graph);
    writePackageGraph(graph);

    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('my_app'));

    final PackageConfig packageConfig = await loadPackageConfig(project.packageConfig);

    final List<Dependency> dependencies = computeTransitiveDependencies(project, packageConfig);
    expect(dependencies.map((Dependency d) => d.name), graph.map((Package p) => p.name).toSet());
    for (final p in graph) {
      expect(
        dependencies.firstWhere((Dependency d) => d.name == p.name).isExclusiveDevDependency,
        exclusiveDevDependencies.contains(p.name),
      );
    }
  }

  test('no dev dependencies at all', () async {
    await validatesComputeTransitiveDependencies(<Package>[
      (name: 'my_app', dependencies: <String>['package_a'], devDependencies: <String>[]),
      (name: 'package_a', dependencies: <String>['package_b'], devDependencies: <String>[]),
      (name: 'package_b', dependencies: <String>['package_a'], devDependencies: <String>[]),
    ], <String>[]);
  });

  test('dev dependency', () async {
    await validatesComputeTransitiveDependencies(
      <Package>[
        (
          name: 'my_app',
          dependencies: <String>['package_a'],
          devDependencies: <String>['package_b'],
        ),
        (name: 'package_a', dependencies: <String>[], devDependencies: <String>[]),
        (name: 'package_b', dependencies: <String>[], devDependencies: <String>[]),
      ],
      <String>['package_b'],
    );
  });

  test('dev used as a non-dev dependency transitively', () async {
    await validatesComputeTransitiveDependencies(<Package>[
      (name: 'my_app', dependencies: <String>['package_a'], devDependencies: <String>['package_b']),
      (name: 'package_a', dependencies: <String>['package_b'], devDependencies: <String>[]),
      (name: 'package_b', dependencies: <String>[], devDependencies: <String>[]),
    ], <String>[]);
  });

  test('combination of an included and excluded dev_dependency', () async {
    await validatesComputeTransitiveDependencies(
      <Package>[
        (
          name: 'my_app',
          dependencies: <String>['package_a'],
          devDependencies: <String>['package_b', 'package_c'],
        ),
        (name: 'package_a', dependencies: <String>['package_b'], devDependencies: <String>[]),
        (name: 'package_b', dependencies: <String>[], devDependencies: <String>[]),
        (name: 'package_c', dependencies: <String>[], devDependencies: <String>[]),
      ],
      <String>['package_c'],
    );
  });
}
