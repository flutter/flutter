// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:flutter_tools/src/build_runner/web_compilation_delegate.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:glob/glob.dart';

import '../../src/common.dart';
import '../../src/io.dart';
import '../../src/testbed.dart';

void main() {
  group('MultirootFileBasedAssetReader', () {
    Testbed testbed;
    FakePackageGraph packageGraph;

    setUp(() {
      testbed = Testbed(setup: () {
        final PackageNode root = PackageNode('foobar', globals.fs.currentDirectory.path, DependencyType.path);
        packageGraph = FakePackageGraph(root, <String, PackageNode>{'foobar': root});
        globals.fs.file(globals.fs.path.join('lib', 'main.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('main');
        globals.fs.file(globals.fs.path.join('.dart_tool', 'build', 'generated', 'foobar', 'lib', 'bar.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('bar');
        globals.fs.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('name: foobar');
      });
    });

    test('Can find assets from the generated directory', () => testbed.run(() async {
      await IOOverrides.runWithIOOverrides(() async {
        final MultirootFileBasedAssetReader reader = MultirootFileBasedAssetReader(
          packageGraph,
          globals.fs.directory(globals.fs.path.join('.dart_tool', 'build', 'generated')),
        );
        expect(await reader.canRead(AssetId('foobar', 'lib/bar.dart')), true);
        expect(await reader.canRead(AssetId('foobar', 'lib/main.dart')), true);

        expect(await reader.readAsString(AssetId('foobar', 'lib/bar.dart')), 'bar');
        expect(await reader.readAsString(AssetId('foobar', 'lib/main.dart')), 'main');

        expect(await reader.readAsBytes(AssetId('foobar', 'lib/bar.dart')), utf8.encode('bar'));
        expect(await reader.readAsBytes(AssetId('foobar', 'lib/main.dart')), utf8.encode('main'));

        expect(await reader.findAssets(Glob('**')).toList(), unorderedEquals(<AssetId>[
          AssetId('foobar', 'pubspec.yaml'),
          AssetId('foobar', 'lib/bar.dart'),
          AssetId('foobar', 'lib/main.dart'),
        ]));
      }, FlutterIOOverrides(fileSystem: globals.fs));
     // Some component of either dart:io or build_runner normalizes file uris
     // into file paths for windows. This doesn't seem to work with IOOverrides
     // leaving all filepaths on windows with forward slashes.
    }), skip: Platform.isWindows);
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
