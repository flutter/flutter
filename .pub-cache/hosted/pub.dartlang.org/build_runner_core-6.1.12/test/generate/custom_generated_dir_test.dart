// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:build_runner_core/build_runner_core.dart';

import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';

void main() {
  final customGeneratedDir = 'my-custom-dir';
  overrideGeneratedOutputDirectory(customGeneratedDir);

  PackageGraph packageGraph;

  setUp(() {
    packageGraph = buildPackageGraph({
      rootPackage('a', path: 'a/'): [],
    });
  });

  test('can output files to a custom generated dir', () async {
    var writer = InMemoryRunnerAssetWriter();
    await testBuilders(
        [
          applyToRoot(
              TestBuilder(
                  buildExtensions: appendExtension('.copy', from: '.txt')),
              hideOutput: true),
        ],
        {'a|lib/a.txt': 'a'},
        packageGraph: packageGraph,
        outputs: {
          r'$$a|lib/a.txt.copy': 'a',
        },
        expectedGeneratedDir: customGeneratedDir,
        writer: writer);
    expect(
        writer.assets[AssetId(
            'a', '.dart_tool/build/$customGeneratedDir/a/lib/a.txt.copy')],
        isNotNull);
  });
}
