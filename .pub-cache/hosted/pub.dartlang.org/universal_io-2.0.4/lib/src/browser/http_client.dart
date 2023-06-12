// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import '../io_impl_js.dart';
import 'http_client_request.dart';

/// Browser implementation of _dart:io_ [HttpClient].
class BrowserHttpClient implements HttpClient {
  /// Enables [CORS "credentials mode"](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
  /// for all _XHR_ requests. Disabled by default.
  ///
  /// "Credentials mode" causes cookies and other credentials to be sent and
  /// received. It has complicated implications for CORS headers required from
  /// the server.
  ///
  /// # Example
  /// ```
  /// Future<void> main() async {
  ///   final client = HttpClient();
  ///   if (client is BrowserHttpClient) {
  ///     client.browserCredentialsMode = true;
  ///   }
  ///   // ...
  /// }
  ///  ```
  bool browserCredentialsMode = false;

  @override
  Duration idleTimeout = Duration(seconds: 15);

  @override
  Duration? connectionTimeout;

  @override
  int? maxConnectionsPerHost;

  @override
  bool autoUncompress = true;

  @override
  String? userAgent;

  @override
  Future<bool> Function(Uri url, String scheme, String realm)? authenticate;

  @override
  Future<bool> Function(String host, int port, String scheme, String realm)?
      authenticateProxy;

  @override
  bool Function(X509Certificate cert, String host, int port)?
      badCertificateCallback;

  @override
  String Function(Uri url)? findProxy;

  bool _isClosed = false;

  /// Enables you to set [BrowserHttpClientRequest.browserRequestType] before
  /// any _XHR_ request is sent to the server.
  FutureOr<void> Function(BrowserHttpClientRequest request)?
      onBrowserHttpClientRequestClose;

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    throw UnimplementedError();
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  void close({bool force = false}) {
    _isClosed = true;
  }

  @override
  Future<HttpClientRequest> delete(String host, int? port, String path) {
    return open('DELETE', host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return openUrl('DELETE', url);
  }

  @override
  Future<HttpClientRequest> get(String host, int? port, String path) {
    return open('GET', host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return openUrl('GET', url);
  }

  @override
  Future<HttpClientRequest> head(String host, int? port, String path) {
    return open('HEAD', host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return openUrl('HEAD', url);
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int? port, String path) {
    String? query;
    final i = path.indexOf('?');
    if (i >= 0) {
      query = path.substring(i + 1);
      path = path.substring(0, i);
    }
    final uri = Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: path,
      query: query,
      fragment: null,
    );
    return openUrl(method, uri);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (_isClosed) {
      throw StateError('HTTP client is closed');
    }
    var scheme = url.scheme;
    var needsNewUrl = false;
    if (scheme.isEmpty) {
      scheme = 'https';
      needsNewUrl = true;
    } else {
      switch (scheme) {
        case '':
          scheme = 'https';
          needsNewUrl = true;
          break;
        case 'http':
          break;
        case 'https':
          break;
        default:
          throw ArgumentError.value(
            url,
            'url',
            'Unsupported scheme',
          );
      }
    }
    if (needsNewUrl) {
      url = Uri(
        scheme: scheme,
        userInfo: url.userInfo,
        host: url.host,
        port: url.port,
        query: url.query,
        fragment: url.fragment,
      );
    }
    return BrowserHttpClientRequest(this, method, url);
  }

  @override
  Future<HttpClientRequest> patch(String host, int? port, String path) {
    return open('PATCH', host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return openUrl('PATCH', url);
  }

  @override
  Future<HttpClientRequest> post(String host, int? port, String path) {
    return open('POST', host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return openUrl('POST', url);
  }

  @override
  Future<HttpClientRequest> put(String host, int? port, String path) {
    return open('PUT', host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return openUrl('PUT', url);
  }
}
