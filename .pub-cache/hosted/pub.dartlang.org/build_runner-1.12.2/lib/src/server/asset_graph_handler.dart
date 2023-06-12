// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'path_to_asset_id.dart';

/// A handler for `/$graph` requests under a specific `rootDir`.
class AssetGraphHandler {
  final AssetReader _reader;
  final String _rootPackage;
  final AssetGraph _assetGraph;

  AssetGraphHandler(this._reader, this._rootPackage, this._assetGraph);

  /// Returns a response with the information about a specific node in the
  /// graph.
  ///
  /// For an empty path, returns the HTML page to render the graph.
  ///
  /// For queries with `q=QUERY` will look for the assetNode referenced.
  /// QUERY can be an [AssetId] or a path.
  ///
  /// [AssetId] as `package|path`
  ///
  /// path as:
  /// - `packages/<package>/<path_under_lib>`
  /// - `<path_under_root_package>`
  /// - `<path_under_rootDir>`
  ///
  /// There may be some ambiguity between paths which are under the top-level of
  /// the root package, and those which are under the rootDir. Preference is
  /// given to the asset (if it exists) which is not under the implicit
  /// `rootDir`. For instance if the request is `$graph/web/main.dart` this will
  /// prefer to serve `<package>|web/main.dart`, but if it does not exist will
  /// fall back to `<package>|web/web/main.dart`.
  FutureOr<shelf.Response> handle(shelf.Request request, String rootDir) async {
    switch (request.url.path) {
      case '':
        if (!request.url.hasQuery) {
          return shelf.Response.ok(
              await _reader.readAsString(
                  AssetId('build_runner', 'lib/src/server/graph_viz.html')),
              headers: {HttpHeaders.contentTypeHeader: 'text/html'});
        }

        var query = request.url.queryParameters['q']?.trim();
        if (query != null && query.isNotEmpty) {
          var filter = request.url.queryParameters['f']?.trim();
          return _handleQuery(query, rootDir, filter: filter);
        }
        break;
      case 'assets.json':
        return _jsonResponse(_assetGraph.serialize());
    }

    return shelf.Response.notFound('Bad request: "${request.url}".');
  }

  Future<shelf.Response> _handleQuery(String query, String rootDir,
      {String filter}) async {
    var filterGlob = filter != null ? Glob(filter) : null;
    var pipeIndex = query.indexOf('|');

    AssetId assetId;
    if (pipeIndex < 0) {
      var querySplit = query.split('/');

      assetId = pathToAssetId(
          _rootPackage, querySplit.first, querySplit.skip(1).toList());

      if (!_assetGraph.contains(assetId)) {
        var secondTry = pathToAssetId(_rootPackage, rootDir, querySplit);

        if (!_assetGraph.contains(secondTry)) {
          return shelf.Response.notFound(
              'Could not find asset for path "$query". Tried:\n'
              '- $assetId\n'
              '- $secondTry');
        }
        assetId = secondTry;
      }
    } else {
      assetId = AssetId.parse(query);
      if (!_assetGraph.contains(assetId)) {
        return shelf.Response.notFound(
            'Could not find asset in build graph: $assetId');
      }
    }
    var node = _assetGraph.get(assetId);
    var currentEdge = 0;
    var nodes = [
      {'id': '${node.id}', 'label': '${node.id}'}
    ];
    var edges = <Map<String, String>>[];
    for (final output in node.outputs) {
      if (filterGlob != null && !filterGlob.matches(output.toString())) {
        continue;
      }
      edges.add(
          {'from': '${node.id}', 'to': '$output', 'id': 'e${currentEdge++}'});
      nodes.add({'id': '$output', 'label': '$output'});
    }
    if (node is NodeWithInputs) {
      for (final input in node.inputs) {
        if (filterGlob != null && !filterGlob.matches(input.toString())) {
          continue;
        }
        edges.add(
            {'from': '$input', 'to': '${node.id}', 'id': 'e${currentEdge++}'});
        nodes.add({'id': '$input', 'label': '$input'});
      }
    }
    var result = <String, dynamic>{
      'primary': {
        'id': '${node.id}',
        'hidden': node is GeneratedAssetNode ? node.isHidden : null,
        'state': node is NodeWithInputs ? '${node.state}' : null,
        'wasOutput': node is GeneratedAssetNode ? node.wasOutput : null,
        'isFailure': node is GeneratedAssetNode ? node.isFailure : null,
        'phaseNumber': node is NodeWithInputs ? node.phaseNumber : null,
        'type': node.runtimeType.toString(),
        'glob': node is GlobAssetNode ? node.glob.pattern : null,
        'lastKnownDigest': node.lastKnownDigest.toString(),
      },
      'edges': edges,
      'nodes': nodes,
    };
    return _jsonResponse(_jsonUtf8Encoder.convert(result));
  }
}

final _jsonUtf8Encoder = JsonUtf8Encoder();

shelf.Response _jsonResponse(List<int> body) => shelf.Response.ok(body,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'});
