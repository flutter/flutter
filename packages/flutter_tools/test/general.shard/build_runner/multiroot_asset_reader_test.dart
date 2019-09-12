// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_runner/web_compilation_delegate.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('MultirootFileBasedAssetReader', () {
    Testbed testbed;
    FakePackageGraph packageGraph;

    setUp(() {
      testbed = Testbed(setup: () {
        final PackageNode root = PackageNode('foobar', fs.currentDirectory.path, DependencyType.path);
        packageGraph = FakePackageGraph(root, <String, PackageNode>{'foobar': root});
        fs.file(fs.path.join('lib', 'main.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('main');
        fs.file(fs.path.join('.dart_tool', 'build', 'generated', 'foobar', 'lib', 'bar.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('bar');
        fs.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('name: foobar');
      });
    });

    test('Can find assets from the generated directory', () => testbed.run(() async {
      final MultirootFileBasedAssetReader reader = MultirootFileBasedAssetReader(
        packageGraph,
        fs.directory(fs.path.join('.dart_tool', 'build', 'generated'))
      );

      // Note: we can't read from the regular directory because the default
      // asset reader uses the regular file system.
      expect(await reader.canRead(AssetId('foobar', 'lib/bar.dart')), true);
      expect(await reader.readAsString(AssetId('foobar', 'lib/bar.dart')), 'bar');
      expect(await reader.readAsBytes(AssetId('foobar', 'lib/bar.dart')), utf8.encode('bar'));
    }));
  });
}

class FakePackageGraph implements PackageGraph {
  FakePackageGraph(this.root, this.allPackages);

  @override
  final Map<String, PackageNode> allPackages;

  @override
  final PackageNode root;

  @override
  PackageNode operator [](String packageName) => allPackages[packageName];
}
