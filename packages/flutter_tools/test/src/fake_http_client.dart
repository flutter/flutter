// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';

import 'dart:io';

/// The HTTP verb for a [FakeRequest].
enum HttpMethod {
  get,
  put,
  delete,
  post,
  patch,
  head,
}

HttpMethod _fromMethodString(String value) {
  final String name = value.toLowerCase();
  switch (name) {
    case 'get':
      return HttpMethod.get;
    case 'put':
      return HttpMethod.put;
    case 'delete':
      return HttpMethod.delete;
    case 'post':
      return HttpMethod.post;
    case 'patch':
      return HttpMethod.patch;
    case 'head':
      return HttpMethod.head;
    default:
      throw StateError('Unrecognized HTTP method $value');
  }
}

String _toMethodString(HttpMethod method) {
  switch (method) {
    case HttpMethod.get:
      return 'GET';
    case HttpMethod.put:
      return 'PUT';
    case HttpMethod.delete:
      return 'DELETE';
    case HttpMethod.post:
      return 'POST';
    case HttpMethod.patch:
      return 'PATCH';
    case HttpMethod.head:
      return 'HEAD';
  }
  assert(false);
  return null;
}

/// Override the creation of all [HttpClient] objects with a zone injection.
///
/// This should only be used when the http client cannot be set directly, such as
/// when testing `package:http` code.
Future<void> overrideHttpClients(Future<void> Function() callback,  FakeHttpClient httpClient) async {
  final HttpOverrides overrides = _FakeHttpClientOverrides(httpClient);
  await HttpOverrides.runWithHttpOverrides(callback, overrides);
}

class _FakeHttpClientOverrides extends HttpOverrides {
  _FakeHttpClientOverrides(this.httpClient);

  final FakeHttpClient httpClient;

  @override
  HttpClient createHttpClient(SecurityContext context) {
    return httpClient;
  }
}

/// Create a fake request that configures the [FakeHttpClient] to respond
/// with the provided [response].
///
/// By default, returns a response with a 200 OK status code and an
/// empty response. If [responseError] is non-null, will throw this instead
/// of returning the response when closing the request.
class FakeRequest {
  const FakeRequest(this.uri, {
    this.method = HttpMethod.get,
    this.response = FakeResponse.empty,
    this.responseError,
  });

  final Uri uri;
  final HttpMethod method;
  final FakeResponse response;
  final dynamic responseError;

  @override
  String toString() => 'Request{${_toMethodString(method)}, $uri}';
}

/// The response the server will create for a given [FakeRequest].
class FakeResponse {
  const FakeResponse({
    this.statusCode = HttpStatus.ok,
    this.body = const <int>[],
    this.headers = const <String, List<String>>{},
  });

  static const FakeResponse empty = FakeResponse();

  final int statusCode;
  final List<int> body;
  final Map<String, List<String>> headers;
}

/// A fake implementation of the HttpClient used for testing.
///
/// This does not fully implement the HttpClient. If an additional method
/// is actually needed by the test script, then it should be added here
/// instead of in another fake.
class FakeHttpClient implements HttpClient {
  /// Creates an HTTP client that responses to each provided
  /// fake request with the provided fake response.
  ///
  /// This does not enforce any order on the requests, but if multiple
  /// requests match then the first will be selected;
  FakeHttpClient.list(List<FakeRequest> requests)
    : _requests = requests.toList();

  /// Creates an HTTP client that always returns an empty 200 request.
  FakeHttpClient.any() : _any = true, _requests = <FakeRequest>[];

  bool _any = false;
  final List<FakeRequest> _requests;

  @override
  bool autoUncompress;

  @override
  Duration connectionTimeout;

  @override
  Duration idleTimeout;

  @override
  int maxConnectionsPerHost;

  @override
  String userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {
    throw UnimplementedError();
  }

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {
    throw UnimplementedError();
  }

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String realm) f) {
    throw UnimplementedError();
  }

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String realm) f) {
    throw UnimplementedError();
  }

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port) callback) {
    throw UnimplementedError();
  }

  @override
  void close({bool force = false}) { }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    final Uri uri = Uri(host: host, port: port, path: path);
    return deleteUrl(uri);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async {
    return _findRequest(HttpMethod.delete, url);
  }

  @override
  set findProxy(String Function(Uri url) f) { }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    final Uri uri = Uri(host: host, port: port, path: path);
    return getUrl(uri);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _findRequest(HttpMethod.get, url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    final Uri uri = Uri(host: host, port: port, path: path);
    return headUrl(uri);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) async {
    return _findRequest(HttpMethod.head, url);
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    final Uri uri = Uri(host: host, port: port, path: path);
    return openUrl(method, uri);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _findRequest(_fromMethodString(method), url);
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    final Uri uri = Uri(host: host, port: port, path: path);
    return patchUrl(uri);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async {
    return _findRequest(HttpMethod.patch, url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    final Uri uri = Uri(host: host, port: port, path: path);
    return postUrl(uri);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _findRequest(HttpMethod.post, url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    final Uri uri = Uri(host: host, port: port, path: path);
    return putUrl(uri);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) async {
    return _findRequest(HttpMethod.put, url);
  }

  int _requestCount = 0;

  _FakeHttpClientRequest _findRequest(HttpMethod method, Uri uri) {
    // Ensure the fake client throws similar errors to the real client.
    if (uri.host.isEmpty) {
      throw ArgumentError('No host specified in URI $uri');
    } else if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError("Unsupported scheme '${uri.scheme}' in URI $uri");
    }
    final String methodString = _toMethodString(method);
    if (_any) {
      return _FakeHttpClientRequest(
        FakeResponse.empty,
        uri,
        methodString,
        null,
      );
    }
    FakeRequest matchedRequest;
    for (final FakeRequest request in _requests) {
      if (request.method == method && request.uri.toString() == uri.toString()) {
        matchedRequest = request;
        break;
      }
    }
    if (matchedRequest == null) {
      throw StateError(
        'Unexpected request for $method to $uri after $_requestCount requests.\n'
        'Pending requests: ${_requests.join(',')}'
      );
    }
    _requestCount += 1;
    _requests.remove(matchedRequest);
    return _FakeHttpClientRequest(
      matchedRequest.response,
      uri,
      methodString,
      matchedRequest.responseError,
    );
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this._response, this._uri, this._method, this._responseError);

  final FakeResponse _response;
  final String _method;
  final Uri _uri;
  final dynamic _responseError;

  @override
  bool bufferOutput;

  @override
  int contentLength = 0;

  @override
  Encoding encoding;

  @override
  bool followRedirects;

  @override
  int maxRedirects;

  @override
  bool persistentConnection;

  @override
  void abort([Object exception, StackTrace stackTrace]) {
    throw UnimplementedError();
  }

  @override
  void add(List<int> data) { }

  @override
  void addError(Object error, [StackTrace stackTrace]) { }

  @override
  Future<void> addStream(Stream<List<int>> stream) async { }

  @override
  Future<HttpClientResponse> close() async {
    if (_responseError != null) {
      return Future<HttpClientResponse>.error(_responseError);
    }
    return _FakeHttpClientResponse(_response);
  }

  @override
  HttpConnectionInfo get connectionInfo => throw UnimplementedError();

  @override
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  Future<HttpClientResponse> get done => throw UnimplementedError();

  @override
  Future<void> flush() async { }

  @override
  final HttpHeaders headers = _FakeHttpHeaders(<String, List<String>>{});

  @override
  String get method => _method;

  @override
  Uri get uri => _uri;

  @override
  void write(Object object) { }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) { }

  @override
  void writeCharCode(int charCode) { }

  @override
  void writeln([Object object = '']) { }
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeHttpClientResponse(this._response)
      : headers = _FakeHttpHeaders(Map<String, List<String>>.from(_response.headers));

  final FakeResponse _response;

  @override
  X509Certificate get certificate => throw UnimplementedError();

  @override
  HttpClientResponseCompressionState get compressionState => throw UnimplementedError();

  @override
  HttpConnectionInfo get connectionInfo => throw UnimplementedError();

  @override
  int get contentLength => _response.body.length;

  @override
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  final HttpHeaders headers;

  @override
  bool get isRedirect => throw UnimplementedError();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    final Stream<List<int>> response = Stream<List<int>>.fromIterable(<List<int>>[
      _response.body,
    ]);
    return response.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  bool get persistentConnection => throw UnimplementedError();

  @override
  String get reasonPhrase => 'OK';

  @override
  Future<HttpClientResponse> redirect([String method, Uri url, bool followLoops]) {
    throw UnimplementedError();
  }

  @override
  List<RedirectInfo> get redirects => throw UnimplementedError();

  @override
  int get statusCode => _response.statusCode;
}

class _FakeHttpHeaders extends HttpHeaders {
  _FakeHttpHeaders(this._backingData);

  final Map<String, List<String>> _backingData;

  @override
  List<String> operator [](String name) => _backingData[name];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _backingData[name] ??= <String>[];
    _backingData[name].add(value.toString());
  }

  @override
  void clear() {
    _backingData.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) { }

  @override
  void noFolding(String name) {  }

  @override
  void remove(String name, Object value) {
    _backingData[name]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _backingData.remove(name);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _backingData[name] = <String>[value.toString()];
  }

  @override
  String value(String name) {
    return _backingData[name]?.join('; ');
  }
}
