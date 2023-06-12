// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'asset_reader.dart';

/// A reader for resources provided by a proxy server.
class ProxyServerAssetReader implements AssetReader {
  final _logger = Logger('ProxyServerAssetReader');

  late final Handler _handler;
  late final http.Client _client;

  ProxyServerAssetReader(int assetServerPort,
      {String root = '', String host = 'localhost', bool isHttps = false}) {
    final scheme = isHttps ? 'https://' : 'http://';
    final inner = HttpClient()
      ..maxConnectionsPerHost = 200
      ..idleTimeout = const Duration(seconds: 30)
      ..connectionTimeout = const Duration(seconds: 30);
    _client = isHttps
        ? IOClient(inner..badCertificateCallback = (cert, host, port) => true)
        : IOClient(inner);
    var url = '$scheme$host:$assetServerPort/';
    if (root.isNotEmpty) url += '$root/';
    _handler = proxyHandler(url, client: _client);
  }

  @override
  Future<String?> dartSourceContents(String serverPath) =>
      _readResource(serverPath);

  @override
  Future<String?> sourceMapContents(String serverPath) =>
      _readResource(serverPath);

  Future<String?> _readResource(String path) async {
    // Handlers expect a fully formed HTML URI. The actual hostname and port
    // does not matter.
    final response =
        await _handler(Request('GET', Uri.parse('http://foo:0000/$path')));

    if (response.statusCode != HttpStatus.ok) {
      _logger.warning('''
      Failed to load asset at path: $path.

      Status code: ${response.statusCode}

      Headers:
      ${const JsonEncoder.withIndent('  ').convert(response.headers)}
      ''');
      return null;
    } else {
      return await response.readAsString();
    }
  }

  @override
  Future<String?> metadataContents(String serverPath) =>
      _readResource(serverPath);

  @override
  Future<void> close() async => _client.close();
}
