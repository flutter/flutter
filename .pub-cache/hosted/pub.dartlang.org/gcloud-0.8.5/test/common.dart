// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:mime/mime.dart' as mime;
import 'package:test/test.dart';

const _contentTypeJsonUtf8 = 'application/json; charset=utf-8';

const _responseHeaders = {'content-type': _contentTypeJsonUtf8};

class MockClient extends http.BaseClient {
  static const bytes = [1, 2, 3, 4, 5];

  final _bytesHeaderRegexp = RegExp(r'bytes=(\d+)-(\d+)');

  final String hostname;
  final String rootPath;
  final Uri rootUri;

  Map<String, Map<Pattern, http_testing.MockClientHandler>> mocks = {};
  late http_testing.MockClient client;

  MockClient(this.hostname, this.rootPath)
      : rootUri = Uri.parse('https://$hostname$rootPath') {
    client = http_testing.MockClient(handler);
  }

  void register(
      String method, Pattern path, http_testing.MockClientHandler handler) {
    var map = mocks.putIfAbsent(method, () => {});
    if (path is RegExp) {
      map[RegExp('$rootPath${path.pattern}')] = handler;
    } else {
      map['$rootPath$path'] = handler;
    }
  }

  void registerUpload(
      String method, Pattern path, http_testing.MockClientHandler handler) {
    var map = mocks.putIfAbsent(method, () => {});
    map['/upload$rootPath$path'] = handler;
  }

  void registerResumableUpload(
      String method, Pattern path, http_testing.MockClientHandler handler) {
    var map = mocks.putIfAbsent(method, () => {});
    map['/resumable/upload$rootPath$path'] = handler;
  }

  void clear() {
    mocks = {};
  }

  Future<http.Response> handler(http.Request request) {
    expect(
      request.url.host,
      anyOf(rootUri.host, 'storage.googleapis.com'),
    );
    var path = request.url.path;
    if (mocks[request.method] == null) {
      throw 'No mock handler for method ${request.method} found. '
          'Request URL was: ${request.url}';
    }
    http_testing.MockClientHandler? mockHandler;
    mocks[request.method]!
        .forEach((pattern, http_testing.MockClientHandler handler) {
      if (pattern.matchAsPrefix(path) != null) {
        mockHandler = handler;
      }
    });
    if (mockHandler == null) {
      throw 'No mock handler for method ${request.method} and path '
          '[$path] found. Request URL was: ${request.url}';
    }
    return mockHandler!(request);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return client.send(request);
  }

  Future<http.Response> respond(response) {
    return Future.value(http.Response(jsonEncode(response.toJson()), 200,
        headers: _responseHeaders));
  }

  Future<http.Response> respondEmpty() {
    return Future.value(http.Response('{}', 200, headers: _responseHeaders));
  }

  Future<http.Response> respondInitiateResumableUpload(project) {
    final headers = Map<String, String>.from(_responseHeaders);
    headers['location'] = 'https://$hostname/resumable/upload$rootPath'
        'b/$project/o?uploadType=resumable&alt=json&'
        'upload_id=AEnB2UqucpaWy7d5cr5iVQzmbQcQlLDIKiClrm0SAX3rJ7UN'
        'Mu5bEoC9b4teJcJUKpqceCUeqKzuoP_jz2ps_dV0P0nT8OTuZQ';
    return Future.value(http.Response('', 200, headers: headers));
  }

  Future<http.Response> respondContinueResumableUpload() {
    return Future.value(http.Response('', 308, headers: _responseHeaders));
  }

  Future<http.Response> respondBytes(http.Request request) async {
    expect(request.url.queryParameters['alt'], 'media');

    var myBytes = bytes;
    var headers = Map<String, String>.from(_responseHeaders);

    var range = request.headers['range'];
    if (range != null) {
      var match = _bytesHeaderRegexp.allMatches(range).single;

      var start = int.parse(match[1]!);
      var end = int.parse(match[2]!);

      myBytes = bytes.sublist(start, end + 1);
      headers['content-length'] = myBytes.length.toString();
      headers['content-range'] = 'bytes $start-$end/';
    }

    return http.Response.bytes(myBytes, 200, headers: headers);
  }

  Future<http.Response> respondError(int statusCode) {
    var error = {
      'error': {'code': statusCode, 'message': 'error'}
    };
    return Future.value(http.Response(jsonEncode(error), statusCode,
        headers: _responseHeaders));
  }

  Future<NormalMediaUpload> processNormalMediaUpload(http.Request request) {
    var completer = Completer<NormalMediaUpload>();

    var contentType =
        http_parser.MediaType.parse(request.headers['content-type']!);
    expect(contentType.mimeType, 'multipart/related');
    var boundary = contentType.parameters['boundary'];

    var partCount = 0;
    String? json;
    Stream.fromIterable([
      request.bodyBytes,
      [13, 10]
    ])
        .transform(mime.MimeMultipartTransformer(boundary!))
        .listen(((mime.MimeMultipart mimeMultipart) {
      var contentType = mimeMultipart.headers['content-type']!;
      partCount++;
      if (partCount == 1) {
        // First part in the object JSON.
        expect(contentType, 'application/json; charset=utf-8');
        mimeMultipart
            .transform(utf8.decoder)
            .fold('', (p, e) => '$p$e')
            .then((j) => json = j);
      } else if (partCount == 2) {
        // Second part is the base64 encoded bytes.
        mimeMultipart
            .transform(ascii.decoder)
            .fold('', (p, e) => '$p$e')
            .then(base64.decode)
            .then((bytes) {
          completer.complete(NormalMediaUpload(json!, bytes, contentType));
        });
      } else {
        // Exactly two parts expected.
        throw 'Unexpected part count';
      }
    }));

    return completer.future;
  }
}

class NormalMediaUpload {
  final String json;
  final List<int> bytes;
  final String contentType;
  NormalMediaUpload(this.json, this.bytes, this.contentType);
}

// Implementation of http.Client which traces all requests and responses.
// Mainly useful for local testing.
class TraceClient extends http.BaseClient {
  final http.Client client;

  TraceClient(this.client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    print(request);
    return request.finalize().toBytes().then((body) {
      print('--- START REQUEST ---');
      print(utf8.decode(body));
      print('--- END REQUEST ---');
      var r = RequestImpl(request.method, request.url, body);
      r.headers.addAll(request.headers);
      return client.send(r).then((http.StreamedResponse rr) {
        return rr.stream.toBytes().then((body) {
          print('--- START RESPONSE ---');
          print(utf8.decode(body));
          print('--- END RESPONSE ---');
          return http.StreamedResponse(
              http.ByteStream.fromBytes(body), rr.statusCode,
              headers: rr.headers);
        });
      });
    });
  }

  @override
  void close() {
    client.close();
  }
}

// http.BaseRequest implementation used by the TraceClient.
class RequestImpl extends http.BaseRequest {
  final List<int> _body;

  RequestImpl(String method, Uri url, this._body) : super(method, url);

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream.fromBytes(_body);
  }
}
