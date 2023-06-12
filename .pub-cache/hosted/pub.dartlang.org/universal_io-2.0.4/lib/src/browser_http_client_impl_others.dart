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

// Annotate as 'internal' so developers don't accidentally import this.
@internal
library universal_io.browser_http_client.impl_others;

import 'dart:async';

import 'package:meta/meta.dart';

import 'io_impl_vm.dart'
    if (dart.library.io) 'io_impl_vm.dart'
    if (dart.library.js) 'io_impl_js.dart';

/// Implemented by [HttpClient] when the application runs in browser.
abstract class BrowserHttpClient implements HttpClient {
  /// Enables you to set [BrowserHttpClientRequest.browserRequestType] before
  /// any _XHR_ request is sent to the server.
  FutureOr<void> Function(BrowserHttpClientRequest request)?
      onBrowserHttpClientRequestClose;

  factory BrowserHttpClient() {
    throw UnimplementedError();
  }

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
  bool get browserCredentialsMode;
}

/// May be thrown by [BrowserHttpClientRequest.close()] in browsers.
abstract class BrowserHttpClientException implements SocketException {
  /// Can be used to disable verbose messages in development mode.
  static bool verbose = true;

  BrowserHttpClientException._();

  /// Browser "credentials mode".
  bool get browserCredentialsMode;

  /// Browser response type.
  String get browserResponseType;

  /// HTTP headers
  HttpHeaders get headers;

  /// HTTP method ("GET, "POST, etc.)
  String get method;

  /// Origin of the HTTP request.
  String? get origin;

  /// URL of the HTTP request.
  String get url;
}

/// Implemented by [HttpClientRequest] when the application runs in browser.
abstract class BrowserHttpClientRequest implements HttpClientRequest {
  /// Sets _responseType_ in XMLHttpRequest for this _XHR_ request.
  ///
  /// # Possible values
  ///   * "arraybuffer" or `null` (default)
  ///   * "json"
  ///   * "text" (makes streaming possible)
  ///
  String? browserResponseType;

  /// Enables ["credentials mode"](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
  /// for this _XHR_ request. Disabled by default.
  ///
  /// "Credentials mode" causes cookies and other credentials to be sent and
  /// received. It has complicated implications for CORS headers required from
  /// the server.
  ///
  /// # Example
  /// ```
  /// Future<void> main() async {
  ///   final client = HttpClient();
  ///   final request = client.getUrl(Url.parse('http://host/path'));
  ///   if (request is BrowserHttpClientRequest) {
  ///     request.browserCredentialsMode = true;
  ///   }
  ///   final response = await request.close();
  ///   // ...
  /// }
  ///  ```
  bool browserCredentialsMode = false;

  BrowserHttpClientRequest._();
}

/// Implemented by [HttpClientResponse] when the application runs in browser.
abstract class BrowserHttpClientResponse implements HttpClientResponse {
  BrowserHttpClientResponse._();

  /// Response object of _XHR_ request.
  ///
  /// You need to finish reading this [HttpClientResponse] to get the final
  /// value.
  dynamic get browserResponse;
}
