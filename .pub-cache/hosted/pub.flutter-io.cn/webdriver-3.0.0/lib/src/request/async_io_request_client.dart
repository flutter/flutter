import 'dart:async';
import 'dart:convert';
import 'dart:io' show ContentType, HttpClient, HttpHeaders, HttpClientRequest;

import '../../support/async.dart';

import '../common/request.dart';
import '../common/request_client.dart';

/// Async request client using dart:io package.
class AsyncIoRequestClient extends AsyncRequestClient {
  final HttpClient client = HttpClient();
  final Map<String, String> _headers;

  final Lock _lock = Lock();

  AsyncIoRequestClient(Uri prefix, {Map<String, String> headers = const {}})
      : _headers = headers,
        super(prefix);

  @override
  Future<WebDriverResponse> sendRaw(WebDriverRequest request) async {
    await _lock.acquire();
    late HttpClientRequest httpRequest;

    switch (request.method) {
      case HttpMethod.httpGet:
        httpRequest = await client.getUrl(resolve(request.uri!));
        break;
      case HttpMethod.httpPost:
        httpRequest = await client.postUrl(resolve(request.uri!));
        break;
      case HttpMethod.httpDelete:
        httpRequest = await client.deleteUrl(resolve(request.uri!));
        break;
    }

    httpRequest.followRedirects = true;
    _headers.forEach(httpRequest.headers.add);
    httpRequest.headers.add(HttpHeaders.acceptHeader, 'application/json');
    httpRequest.headers.add(HttpHeaders.acceptCharsetHeader, utf8.name);
    httpRequest.headers.add(HttpHeaders.cacheControlHeader, 'no-cache');

    if (request.body != null && request.body!.isNotEmpty) {
      httpRequest.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      final body = utf8.encode(request.body!);
      httpRequest.contentLength = body.length;
      httpRequest.add(body);
    }

    try {
      final response = await httpRequest.close();

      return WebDriverResponse(response.statusCode, response.reasonPhrase,
          await utf8.decodeStream(response.cast<List<int>>()));
    } finally {
      _lock.release();
    }
  }

  @override
  String toString() => 'AsyncIo';
}
