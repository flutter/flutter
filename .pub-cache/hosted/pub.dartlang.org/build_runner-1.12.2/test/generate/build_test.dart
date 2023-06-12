// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner/src/generate/build.dart' as build_impl;
import 'package:build_test/build_test.dart';

import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';

void main() {
  // Basic phases/phase groups which get used in many tests
  final copyABuildApplication = applyToRoot(
      TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt')));
  final packageConfigId = makeAssetId('a|.dart_tool/package_config.json');
  InMemoryRunnerAssetWriter writer;

  setUp(() async {
    writer = InMemoryRunnerAssetWriter();
    await writer.writeAsString(makeAssetId('a|.packages'), '''
# Fake packages file
a:file://fake/pkg/path
''');
    await writer.writeAsString(packageConfigId, jsonEncode(_packageConfig));
  });

  group('--config', () {
    test('warns override config defines builders', () async {
      var logs = <LogRecord>[];
      final packageGraph = buildPackageGraph({
        rootPackage('a', path: path.absolute('a')): [],
      });
      var result = await _doBuild([
        copyABuildApplication
      ], {
        'a|build.yaml': '',
        'a|build.cool.yaml': '''
builders:
  fake:
    import: "a.dart"
    builder_factories: ["myFactory"]
    build_extensions: {"a": ["b"]}
'''
      }, writer,
          configKey: 'cool',
          logLevel: Level.WARNING,
          onLog: logs.add,
          packageGraph: packageGraph);
      expect(result.status, BuildStatus.success);
      expect(
          logs.first.message,
          contains('Ignoring `builders` configuration in `build.cool.yaml` - '
              'overriding builder configuration is not supported.'));
    });
  });
}

Future<BuildResult> _doBuild(List<BuilderApplication> builders,
    Map<String, String> inputs, InMemoryRunnerAssetWriter writer,
    {PackageGraph packageGraph,
    void Function(LogRecord) onLog,
    Level logLevel,
    String configKey}) async {
  onLog ??= (_) {};
  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAssetId(serializedId), contents);
  });
  packageGraph ??=
      buildPackageGraph({rootPackage('a', path: path.absolute('a')): []});
  final reader = InMemoryRunnerAssetReader.shareAssetCache(writer.assets,
      rootPackage: packageGraph.root.name);

  return await build_impl.build(builders,
      configKey: configKey,
      deleteFilesByDefault: true,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      logLevel: logLevel,
      onLog: onLog,
      skipBuildScriptCheck: true);
}

const _packageConfig = {
  'configVersion': 2,
  'packages': [
    {'name': 'a', 'rootUri': 'file://fake/pkg/path', 'packageUri': 'lib/'},
  ],
};
