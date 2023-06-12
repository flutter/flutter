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

import 'package:universal_io/io.dart';

/// Implemented by [HttpClient] when the application runs in browser.
abstract class BrowserHttpClient implements HttpClient {
  /// HTTP request header "Accept" MIMEs that will cause XMLHttpRequest
  /// to use request type "text", which also makes it possible to read the
  /// HTTP response body progressively in chunks.
  static const Set<String> defaultTextMimes = {
    'application/grpc-web-text',
    'application/grpc-web-text+proto',
    'text/*',
  };

  /// Enables you to set [BrowserHttpClientRequest.browserRequestType] before
  /// any _XHR_ request is sent to the server.
  FutureOr<void> Function(BrowserHttpClientRequest request)?
      onBrowserHttpClientRequestClose;

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

  BrowserHttpClient.constructor();
}
