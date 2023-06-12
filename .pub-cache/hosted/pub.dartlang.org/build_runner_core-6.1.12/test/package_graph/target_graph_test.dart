// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:_test_common/package_graphs.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/package_graph/target_graph.dart';

void main() {
  group('TargetGraph.forPackageGraph', () {
    test('warns if required sources are missing', () {
      var logs = <LogRecord>[];
      var listener = Logger.root.onRecord.listen(logs.add);
      addTearDown(listener.cancel);

      var packageB = PackageNode(
          'b', '/fakeB', DependencyType.path, LanguageVersion(0, 0));
      var packageA = PackageNode(
          'a', '/fakeA', DependencyType.path, LanguageVersion(0, 0),
          isRoot: true)
        ..dependencies.add(packageB);
      var packageGraph = PackageGraph.fromRoot(packageA);

      TargetGraph.forPackageGraph(packageGraph, overrideBuildConfig: {
        'a': BuildConfig.fromMap('a', [
          'b'
        ], {
          'targets': {
            r'$default': {
              'sources': ['lib/**']
            }
          }
        }),
        'b': BuildConfig.fromMap('b', [], {
          'targets': {
            r'$default': {
              'sources': ['web/**']
            }
          }
        }),
      }, requiredSourcePaths: [
        r'lib/$lib$',
      ], requiredRootSourcePaths: [
        r'lib/$lib$',
        r'$package$'
      ]);

      expect(
          logs,
          containsAll([
            isA<LogRecord>()
                .having((r) => r.level, 'level', equals(Level.WARNING))
                .having(
                    (r) => r.message,
                    'message',
                    allOf(
                        contains(
                            'The package `a` does not include some required '
                            'sources in any of its targets'),
                        contains(r'$package$'),
                        isNot(contains(r'lib/$lib$')))),
            isA<LogRecord>()
                .having((r) => r.level, 'level', equals(Level.WARNING))
                .having(
                    (r) => r.message,
                    'message',
                    allOf(
                        contains(
                            'The package `b` does not include some required '
                            'sources in any of its targets'),
                        contains(r'lib/$lib$'),
                        isNot(contains(r'$package$')))),
          ]));
    });
  });

  group('target graph reports visible assets', () {
    final a = rootPackage('a');
    final b = package('b');
    final packages = buildPackageGraph({
      a: ['b'],
      b: []
    });

    test('for root package', () async {
      final targetGraph = await TargetGraph.forPackageGraph(packages);

      expect(targetGraph.isVisibleInBuild(AssetId('a', 'web/index.html'), a),
          isTrue);
      expect(
          targetGraph.isVisibleInBuild(AssetId('a', 'lib/a.dart'), a), isTrue);
      expect(targetGraph.isVisibleInBuild(AssetId('a', 'test/my_test.dart'), a),
          isTrue);
      expect(targetGraph.validInputsFor(a), ['**/*']);
    });

    test('for non-root package with default configuration', () async {
      final targetGraph = await TargetGraph.forPackageGraph(packages);

      expect(targetGraph.isVisibleInBuild(AssetId('b', 'web/index.html'), b),
          isFalse);
      expect(
          targetGraph.isVisibleInBuild(AssetId('b', 'lib/b.dart'), b), isTrue);
      expect(
          targetGraph.isVisibleInBuild(AssetId('b', 'LICENSE.txt'), b), isTrue);
      expect(targetGraph.isVisibleInBuild(AssetId('b', 'README'), b), isTrue);
      expect(targetGraph.isVisibleInBuild(AssetId('b', 'test/my_test.dart'), b),
          isFalse);

      expect(targetGraph.validInputsFor(b), contains('lib/**'));
    });

    test('for non-root package exposing additional assets', () async {
      final targetGraph =
          await TargetGraph.forPackageGraph(packages, overrideBuildConfig: {
        'b':
            BuildConfig.parse('b', [], 'additional_public_assets: ["test/**"]'),
      });

      expect(
          targetGraph.isVisibleInBuild(AssetId('b', 'lib/b.dart'), b), isTrue);
      expect(targetGraph.isVisibleInBuild(AssetId('b', 'test/my_test.dart'), b),
          isTrue);

      expect(targetGraph.validInputsFor(b), contains('test/**'));
      // The additional input should also be included in the default target
      expect(targetGraph.allModules['b:b'].sourceIncludes,
          contains(isA<Glob>().having((e) => e.pattern, 'pattern', 'test/**')));
    });
  });
}
