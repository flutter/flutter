// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:build_runner_core/build_runner_core.dart';

void main() {
  PackageGraph graph;

  group('PackageGraph', () {
    group('forThisPackage ', () {
      setUp(() async {
        graph = await PackageGraph.forThisPackage();
      });

      test('root', () {
        expectPkg(graph.root, 'build_runner_core', '', DependencyType.path);
      });
    });

    group('basic package ', () {
      var basicPkgPath = 'test/fixtures/basic_pkg';

      setUp(() async {
        graph = await PackageGraph.forPath(basicPkgPath);
      });

      test('allPackages', () {
        expect(
            graph.allPackages,
            equals({
              'a': graph['a'],
              'b': graph['b'],
              'c': graph['c'],
              'd': graph['d'],
              'basic_pkg': graph['basic_pkg'],
              r'$sdk': anything,
            }));
      });

      test('root', () {
        expectPkg(graph.root, 'basic_pkg', basicPkgPath, DependencyType.path,
            [graph['a'], graph['b'], graph['c'], graph['d']]);
      });

      test('dependency', () {
        expectPkg(graph['a'], 'a', '$basicPkgPath/pkg/a', DependencyType.hosted,
            [graph['b'], graph['c']]);
      });
    });

    group('package with dev dependencies', () {
      var withDevDepsPkgPath = 'test/fixtures/with_dev_deps';

      setUp(() async {
        graph = await PackageGraph.forPath(withDevDepsPkgPath);
      });

      test('allPackages contains dev deps of root pkg, but not others', () {
        // Package `c` is a dev dep of package `a` so it shouldn't be present
        // while package `b` is a dev dep of the root package so it should be.
        expect(graph.allPackages, {
          'a': graph['a'],
          'b': graph['b'],
          'with_dev_deps': graph['with_dev_deps'],
          r'$sdk': graph[r'$sdk'],
        });
      });

      test('dev deps are contained in deps of root pkg, but not others', () {
        // Package `b` shows as a dep because this is the root package.
        expectPkg(graph.root, 'with_dev_deps', withDevDepsPkgPath,
            DependencyType.path, [graph['a'], graph['b']]);

        // Package `c` does not appear because this is not the root package.
        expectPkg(graph['a'], 'a', '$withDevDepsPkgPath/pkg/a',
            DependencyType.hosted, []);

        expectPkg(graph['b'], 'b', '$withDevDepsPkgPath/pkg/b',
            DependencyType.hosted, []);

        expect(graph['c'], isNull);
      });
    });

    group('package with flutter dependencies', () {
      var withFlutterDeps = 'test/fixtures/flutter_pkg';

      setUp(() async {
        graph = await PackageGraph.forPath(withFlutterDeps);
      });

      test('allPackages resolved correctly with all packages', () {
        expect(
            graph.allPackages.keys,
            unorderedEquals([
              'flutter_gallery',
              'intl',
              'string_scanner',
              'flutter',
              'collection',
              'flutter_gallery_assets',
              'flutter_test',
              'flutter_driver',
              r'$sdk',
            ]));
      });
    });

    test('custom creation via fromRoot', () {
      var a = PackageNode('a', null, DependencyType.path, null, isRoot: true);
      var b = PackageNode('b', null, null, null);
      var c = PackageNode('c', null, null, null);
      var d = PackageNode('d', null, null, null);
      a.dependencies.addAll([b, d]);
      b.dependencies.add(c);
      var graph = PackageGraph.fromRoot(a);
      expect(graph.root, a);
      expect(graph.allPackages,
          equals({'a': a, 'b': b, 'c': c, 'd': d, r'$sdk': anything}));
    });

    test('missing pubspec throws on create', () {
      expect(
          () => PackageGraph.forPath(p.join('test', 'fixtures', 'no_pubspec')),
          throwsA(anything));
    });

    test('missing .packages file throws on create', () {
      expect(
          () => PackageGraph.forPath(
              p.join('test', 'fixtures', 'no_packages_file')),
          throwsA(anything));
    });
  });
}

void expectPkg(PackageNode node, String name, String location,
    DependencyType dependencyType,
    [Iterable<PackageNode> dependencies]) {
  location = p.canonicalize(location);
  expect(node.name, name);
  expect(node.path, location);
  expect(node.dependencyType, dependencyType);
  if (dependencies != null) {
    expect(node.dependencies, unorderedEquals(dependencies));
  }
}
