// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
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

part of universal_io.http;

const _asyncRunZoned = runZoned;

final _httpOverridesToken = Object();

/// This class facilitates overriding [HttpClient] with a mock implementation.
/// It should be extended by another class in client code with overrides
/// that construct a mock implementation. The implementation in this base class
/// defaults to the actual [HttpClient] implementation. For example:
///
/// ```
/// class MyHttpClient implements HttpClient {
///   ...
///   // An implementation of the HttpClient interface
///   ...
/// }
///
/// main() {
///   HttpOverrides.runZoned(() {
///     ...
///     // Operations will use MyHttpClient instead of the real HttpClient
///     // implementation whenever HttpClient is used.
///     ...
///   }, createHttpClient: (SecurityContext c) => new MyHttpClient(c));
/// }
/// ```
abstract class HttpOverrides {
  static HttpOverrides? _global;

  static HttpOverrides? get current {
    return Zone.current[_httpOverridesToken] ?? _global;
  }

  /// The [HttpOverrides] to use in the root [Zone].
  ///
  /// These are the [HttpOverrides] that will be used in the root Zone, and in
  /// Zone's that do not set [HttpOverrides] and whose ancestors up to the root
  /// Zone do not set [HttpOverrides].
  static set global(HttpOverrides? overrides) {
    _global = overrides;
  }

  /// Returns a new [HttpClient] using the given [context].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new HttpClient`.
  HttpClient createHttpClient(SecurityContext? context) {
    return choose.newHttpClient();
  }

  /// Resolves the proxy server to be used for HTTP connections.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `HttpClient.findProxyFromEnvironment`.
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return 'DIRECT';
  }

  /// Runs [body] in a fresh [Zone] using the overrides found in [overrides].
  ///
  /// Note that [overrides] should be an instance of a class that extends
  /// [HttpOverrides].
  static R runWithHttpOverrides<R>(R Function() body, HttpOverrides overrides) {
    return _asyncRunZoned<R>(body,
        zoneValues: {_httpOverridesToken: overrides});
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(R Function() body,
      {HttpClient Function(SecurityContext?)? createHttpClient,
      String Function(Uri uri, Map<String, String>? environment)?
          findProxyFromEnvironment}) {
    HttpOverrides overrides =
        _HttpOverridesScope(createHttpClient, findProxyFromEnvironment);
    return _asyncRunZoned<R>(body,
        zoneValues: {_httpOverridesToken: overrides});
  }
}

class _HttpOverridesScope extends HttpOverrides {
  final HttpOverrides? _previous = HttpOverrides.current;
  final HttpClient Function(SecurityContext?)? _createHttpClient;
  final String Function(Uri uri, Map<String, String>? environment)?
      _findProxyFromEnvironment;

  _HttpOverridesScope(this._createHttpClient, this._findProxyFromEnvironment);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    var createHttpClient = _createHttpClient;
    if (createHttpClient != null) return createHttpClient(context);
    var previous = _previous;
    if (previous != null) return previous.createHttpClient(context);
    return super.createHttpClient(context);
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    var findProxyFromEnvironment = _findProxyFromEnvironment;
    if (findProxyFromEnvironment != null) {
      return findProxyFromEnvironment(url, environment);
    }
    var previous = _previous;
    if (previous != null) {
      return previous.findProxyFromEnvironment(url, environment);
    }
    return super.findProxyFromEnvironment(url, environment);
  }
}
