// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner/src/server/server.dart';

import 'package:_test_common/common.dart';

void main() {
  AssetHandler handler;
  FinalizedReader reader;
  InMemoryRunnerAssetReader delegate;
  AssetGraph graph;

  setUp(() async {
    graph = await AssetGraph.build([], <AssetId>{}, <AssetId>{},
        buildPackageGraph({rootPackage('foo'): []}), null);
    delegate = InMemoryRunnerAssetReader();
    reader = FinalizedReader(delegate, graph, [], 'a');
    handler = AssetHandler(reader, 'a');
  });

  void _addAsset(String id, String content, {bool deleted = false}) {
    var node = makeAssetNode(id, [], computeDigest(AssetId.parse(id), 'a'));
    if (deleted) {
      node.deletedBy.add(node.id.addExtension('.post_anchor.1'));
    }
    graph.add(node);
    delegate.cacheStringAsset(node.id, content);
  }

  test('can not read deleted nodes', () async {
    _addAsset('a|web/index.html', 'content', deleted: true);
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/index.html')),
        rootDir: 'web');
    expect(response.statusCode, 404);
    expect(await response.readAsString(), 'Not Found');
  });

  test('can read from the root package', () async {
    _addAsset('a|web/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/index.html')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('can read from dependencies', () async {
    _addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('properly sets charset for dart content', () async {
    _addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        rootDir: 'web');
    expect(response.headers['content-type'], contains('charset=utf-8'));
  });

  test('can read from dependencies nested under top-level dir', () async {
    _addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if path is empty', () async {
    _addAsset('a|web/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if URI ends with slash', () async {
    _addAsset('a|web/sub/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/sub/')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('does not default to index.html if URI does not end in slash', () async {
    _addAsset('a|web/sub/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/sub')),
        rootDir: 'web');
    expect(response.statusCode, 404);
  });

  test('Fails request for failed outputs', () async {
    graph.add(GeneratedAssetNode(
      makeAssetId('a|web/main.ddc.js'),
      builderOptionsId: null,
      phaseNumber: null,
      state: NodeState.upToDate,
      isHidden: false,
      wasOutput: true,
      isFailure: true,
      primaryInput: null,
    ));
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/main.ddc.js')),
        rootDir: 'web');
    expect(response.statusCode, HttpStatus.internalServerError);
  });
}
