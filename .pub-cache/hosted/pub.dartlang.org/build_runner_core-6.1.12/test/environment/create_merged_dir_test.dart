// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';
import 'package:_test_common/test_environment.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/asset_graph/optional_output_tracker.dart';
import 'package:build_runner_core/src/environment/create_merged_dir.dart';
import 'package:build_runner_core/src/generate/finalized_assets_view.dart';
import 'package:build_runner_core/src/generate/phase.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('createMergedDir', () {
    AssetGraph graph;
    final phases = [
      InBuildPhase(
          TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt')),
          'a'),
      InBuildPhase(
          TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt')),
          'b')
    ];
    final sources = {
      makeAssetId('a|lib/a.txt'): 'a',
      makeAssetId('a|web/b.txt'): 'b',
      makeAssetId('b|lib/c.txt'): 'c',
      makeAssetId('b|test/outside.txt'): 'not in lib',
      makeAssetId('a|foo/d.txt'): 'd',
      makeAssetId('a|.dart_tool/package_config.json'): '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "a",
      "rootUri": "file:///packages/a",
      "packageUri": "lib/"
    }, {
      "name": "b",
      "rootUri": "file:///packages/b",
      "packageUri": "lib/"
    }
  ]
}
'''
    };
    final packageGraph = buildPackageGraph({
      rootPackage('a'): ['b'],
      package('b'): []
    });
    Directory tmpDir;
    Directory anotherTmpDir;
    TestBuildEnvironment environment;
    InMemoryRunnerAssetReader assetReader;
    OptionalOutputTracker optionalOutputTracker;
    FinalizedAssetsView finalizedAssetsView;

    setUp(() async {
      assetReader = InMemoryRunnerAssetReader(sources);
      environment = TestBuildEnvironment(reader: assetReader);
      graph = await AssetGraph.build(
          phases, sources.keys.toSet(), <AssetId>{}, packageGraph, assetReader);
      optionalOutputTracker = OptionalOutputTracker(graph, {}, {}, phases);
      finalizedAssetsView =
          FinalizedAssetsView(graph, packageGraph, optionalOutputTracker);
      for (var id in graph.outputs) {
        var node = graph.get(id) as GeneratedAssetNode
          ..state = NodeState.upToDate
          ..wasOutput = true
          ..isFailure = false;
        assetReader.cacheStringAsset(id, sources[node.primaryInput]);
      }
      tmpDir = await Directory.systemTemp.createTemp('build_tests');
      anotherTmpDir = await Directory.systemTemp.createTemp('build_tests');
    });

    tearDown(() async {
      await tmpDir.delete(recursive: true);
    });

    test('creates a valid merged output directory', () async {
      var success = await createMergedOutputDirectories(
          {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);

      _expectAllFiles(tmpDir);
    });

    test('doesnt write deleted files', () async {
      var node =
          graph.get(AssetId('b', 'lib/c.txt.copy')) as GeneratedAssetNode;
      node.deletedBy.add(node.id.addExtension('.post_anchor.1'));

      var success = await createMergedOutputDirectories(
          {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);

      var file = File(p.join(tmpDir.path, 'packages/b/c.txt.copy'));
      expect(file.existsSync(), isFalse);
    });

    test('does not include non-lib files from non-root packages', () {
      expect(finalizedAssetsView.allAssets(),
          isNot(contains(makeAssetId('b|test/outside.txt'))));
    });

    test('can create multiple merged directories', () async {
      var success = await createMergedOutputDirectories({
        BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
        BuildDirectory('', outputLocation: OutputLocation(anotherTmpDir.path))
      }, packageGraph, environment, assetReader, finalizedAssetsView, false);
      expect(success, isTrue);

      _expectAllFiles(tmpDir);
      _expectAllFiles(anotherTmpDir);
    });

    test('errors if there are conflicting directories', () async {
      var success = await createMergedOutputDirectories({
        BuildDirectory('web', outputLocation: OutputLocation(tmpDir.path)),
        BuildDirectory('foo', outputLocation: OutputLocation(tmpDir.path))
      }, packageGraph, environment, assetReader, finalizedAssetsView, false);
      expect(success, isFalse);
      expect(Directory(tmpDir.path).listSync(), isEmpty);
    });

    test('succeeds if no output directory requested ', () async {
      var success = await createMergedOutputDirectories(
          {BuildDirectory('web'), BuildDirectory('foo')},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);
    });

    test('removes the provided root from the output path', () async {
      var success = await createMergedOutputDirectories(
          {BuildDirectory('web', outputLocation: OutputLocation(tmpDir.path))},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);

      var webFiles = <String, dynamic>{
        'b.txt': 'b',
        'b.txt.copy': 'b',
      };

      _expectFiles(webFiles, tmpDir);
    });

    test('skips output directories with no assets', () async {
      var success = await createMergedOutputDirectories({
        BuildDirectory('no_assets_here',
            outputLocation: OutputLocation(tmpDir.path))
      }, packageGraph, environment, assetReader, finalizedAssetsView, false);
      expect(success, isFalse);
      expect(Directory(tmpDir.path).listSync(), isEmpty);
    });

    test('does not output the input directory', () async {
      var success = await createMergedOutputDirectories(
          {BuildDirectory('web', outputLocation: OutputLocation(tmpDir.path))},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);

      expect(Directory(p.join(tmpDir.path, 'web')).existsSync(), isFalse);
    });

    test('outputs the packages when input root is provided', () async {
      var success = await createMergedOutputDirectories({
        BuildDirectory('web', outputLocation: OutputLocation(tmpDir.path)),
        BuildDirectory('foo',
            outputLocation: OutputLocation(anotherTmpDir.path))
      }, packageGraph, environment, assetReader, finalizedAssetsView, false);
      expect(success, isTrue);

      var webFiles = <String, dynamic>{
        'packages/a/a.txt': 'a',
        'packages/a/a.txt.copy': 'a',
        'packages/b/c.txt': 'c',
        'packages/b/c.txt.copy': 'c',
        '.packages': 'a:packages/a/\r\nb:packages/b/\r\n\$sdk:packages/\$sdk/',
        '.dart_tool/package_config.json':
            _expectedPackageConfig('a', ['a', 'b']),
      };

      _expectFiles(webFiles, tmpDir);
    });

    test('does not nest packages symlinks with no root', () async {
      var success = await createMergedOutputDirectories(
          {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);
      _expectNoFiles(<String>{'packages/packages/a/a.txt'}, tmpDir);
    });

    test('only outputs files contained in the provided root', () async {
      var success = await createMergedOutputDirectories({
        BuildDirectory('web', outputLocation: OutputLocation(tmpDir.path)),
        BuildDirectory('foo',
            outputLocation: OutputLocation(anotherTmpDir.path))
      }, packageGraph, environment, assetReader, finalizedAssetsView, false);
      expect(success, isTrue);

      var webFiles = <String, dynamic>{
        'b.txt': 'b',
        'b.txt.copy': 'b',
      };

      var webNoFiles = <String>{}..addAll(['d.txt', 'd.txt.copy']);

      var fooFiles = <String, dynamic>{
        'd.txt': 'd',
        'd.txt.copy': 'd',
      };

      var fooNoFiles = <String>{}..addAll(['b.txt', 'b.txt.copy']);

      _expectFiles(webFiles, tmpDir);
      _expectNoFiles(webNoFiles, tmpDir);
      _expectFiles(fooFiles, anotherTmpDir);
      _expectNoFiles(fooNoFiles, anotherTmpDir);
    });

    test('doesnt write files that werent output', () async {
      graph.get(AssetId('b', 'lib/c.txt.copy')) as GeneratedAssetNode
        ..wasOutput = false
        ..isFailure = false;

      var success = await createMergedOutputDirectories(
          {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);

      var file = File(p.join(tmpDir.path, 'packages/b/c.txt.copy'));
      expect(file.existsSync(), isFalse);
    });

    test('doesnt always write files not matching outputDirs', () async {
      optionalOutputTracker = OptionalOutputTracker(graph, {'foo'}, {}, phases);
      finalizedAssetsView =
          FinalizedAssetsView(graph, packageGraph, optionalOutputTracker);
      var success = await createMergedOutputDirectories(
          {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
          packageGraph,
          environment,
          assetReader,
          finalizedAssetsView,
          false);
      expect(success, isTrue);

      var expectedFiles = <String, dynamic>{
        'foo/d.txt': 'd',
        'foo/d.txt.copy': 'd',
        'packages/a/a.txt': 'a',
        'packages/b/c.txt': 'c',
        'web/b.txt': 'b',
        '.packages': 'a:packages/a/\r\nb:packages/b/\r\n\$sdk:packages/\$sdk/',
        '.dart_tool/package_config.json':
            _expectedPackageConfig('a', ['a', 'b'])
      };
      _expectFiles(expectedFiles, tmpDir);
    });

    group('existing output dir handling', () {
      File garbageFile;
      Directory emptyDirectory;
      setUp(() {
        garbageFile = File(p.join(tmpDir.path, 'garbage_file.txt'))
          ..createSync();
        emptyDirectory = Directory(p.join(tmpDir.path, 'empty_directory'))
          ..createSync();
      });

      test('fails in non-interactive mode', () async {
        environment =
            TestBuildEnvironment(reader: assetReader, throwOnPrompt: true);
        var success = await createMergedOutputDirectories(
            {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isFalse);
      });

      test('can skip creating the directory', () async {
        environment.nextPromptResponse = 0;
        var success = await createMergedOutputDirectories(
            {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isFalse,
            reason: 'Skipping creation of the directory should be considered a '
                'failure.');

        expect(garbageFile.existsSync(), isTrue,
            reason: 'Should not delete existing files.');
        var file = File(p.join(tmpDir.path, 'web/b.txt'));
        expect(file.existsSync(), isFalse,
            reason: 'Should not copy any files.');
      });

      test('can delete the entire existing directory', () async {
        environment.nextPromptResponse = 1;
        var success = await createMergedOutputDirectories(
            {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isTrue);

        expect(garbageFile.existsSync(), isFalse);
        _expectAllFiles(tmpDir);
      });

      test('outputs all root directories when emptry string is provided',
          () async {
        environment.nextPromptResponse = 1;
        var success = await createMergedOutputDirectories(
            {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isTrue);

        _expectAllFiles(tmpDir);
      });

      test('fails if the input path is invalid', () async {
        environment.nextPromptResponse = 1;
        var success = await createMergedOutputDirectories(
            {BuildDirectory(null, outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isFalse);
      });

      test('can merge into the existing directory', () async {
        environment.nextPromptResponse = 2;
        var success = await createMergedOutputDirectories(
            {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isTrue);

        expect(garbageFile.existsSync(), isTrue,
            reason: 'Existing files should be left alone.');
        expect(emptyDirectory.existsSync(), isTrue,
            reason: 'Does not remove existing empty directories.');
        _expectAllFiles(tmpDir);
      });
    });

    group('Empty directory cleanup', () {
      test('removes directories that become empty', () async {
        var success = await createMergedOutputDirectories(
            {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isTrue);
        final removes = ['a|lib/a.txt', 'a|lib/a.txt.copy'];
        for (var remove in removes) {
          graph
              .get(makeAssetId(remove))
              .deletedBy
              .add(makeAssetId(remove).addExtension('.post_anchor.1'));
        }
        success = await createMergedOutputDirectories(
            {BuildDirectory('', outputLocation: OutputLocation(tmpDir.path))},
            packageGraph,
            environment,
            assetReader,
            finalizedAssetsView,
            false);
        expect(success, isTrue);
        var packageADir = p.join(tmpDir.path, 'packages', 'a');
        expect(Directory(packageADir).existsSync(), isFalse);
      });
    });
  });
}

String _expectedPackageConfig(String rootPackage, List<String> packages) =>
    jsonEncode({
      'configVersion': 2,
      'packages': [
        for (var package in packages)
          if (package == rootPackage)
            {
              'name': '$package',
              'rootUri': '../',
              'packageUri': 'packages/$package',
            }
          else
            {
              'name': '$package',
              'rootUri': '../packages/$package',
              'packageUri': '',
            },
      ]
    });

void _expectFiles(Map<String, dynamic> expectedFiles, Directory dir) {
  expectedFiles['.build.manifest'] =
      allOf(expectedFiles.keys.map(contains).toList());
  expectedFiles.forEach((path, content) {
    var file = File(p.join(dir.path, path));
    expect(file.existsSync(), isTrue, reason: 'Missing file at $path.');
    expect(file.readAsStringSync(), content,
        reason: 'Incorrect content for file at $path');
  });
}

void _expectNoFiles(Set<String> expectedFiles, Directory dir) {
  for (var path in expectedFiles) {
    var file = File(p.join(dir.path, path));
    expect(!file.existsSync(), isTrue, reason: 'File found at $path.');
  }
}

void _expectAllFiles(Directory dir) {
  var expectedFiles = <String, dynamic>{
    'foo/d.txt': 'd',
    'foo/d.txt.copy': 'd',
    'packages/a/a.txt': 'a',
    'packages/a/a.txt.copy': 'a',
    'packages/b/c.txt': 'c',
    'packages/b/c.txt.copy': 'c',
    'web/b.txt': 'b',
    'web/b.txt.copy': 'b',
    '.packages': 'a:packages/a/\r\nb:packages/b/\r\n\$sdk:packages/\$sdk/',
    '.dart_tool/package_config.json': _expectedPackageConfig('a', ['a', 'b'])
  };
  _expectFiles(expectedFiles, dir);
}
