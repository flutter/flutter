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

import 'package:universal_io/io.dart';

/// Implemented by [HttpClientRequest] when the application runs in browser.
abstract class BrowserHttpClientRequest extends HttpClientRequest {
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
}
