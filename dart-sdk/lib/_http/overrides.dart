// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._http;

final _httpOverridesToken = Object();

/// This class facilitates overriding [HttpClient] with a mock implementation.
/// It should be extended by another class in client code with overrides
/// that construct a mock implementation. The implementation in this base class
/// defaults to the actual [HttpClient] implementation. For example:
///
/// ```dart import:io
/// // An implementation of the HttpClient interface
/// class MyHttpClient implements HttpClient {
///   MyHttpClient(SecurityContext? c);
///
///   @override
///   noSuchMethod(Invocation invocation) {
///     // your implementation here
///   }
/// }
///
/// void main() {
///   HttpOverrides.runZoned(() {
///     // Operations will use MyHttpClient instead of the real HttpClient
///     // implementation whenever HttpClient is used.
///   }, createHttpClient: (SecurityContext? c) => MyHttpClient(c));
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

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(R Function() body,
      {HttpClient Function(SecurityContext?)? createHttpClient,
      String Function(Uri uri, Map<String, String>? environment)?
          findProxyFromEnvironment}) {
    HttpOverrides overrides =
        _HttpOverridesScope(createHttpClient, findProxyFromEnvironment);
    return dart_async.runZoned<R>(body,
        zoneValues: {_httpOverridesToken: overrides});
  }

  /// Runs [body] in a fresh [Zone] using the overrides found in [overrides].
  ///
  /// Note that [overrides] should be an instance of a class that extends
  /// [HttpOverrides].
  static R runWithHttpOverrides<R>(R Function() body, HttpOverrides overrides) {
    return dart_async.runZoned<R>(body,
        zoneValues: {_httpOverridesToken: overrides});
  }

  /// Returns a new [HttpClient] using the given [context].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new HttpClient`.
  HttpClient createHttpClient(SecurityContext? context) {
    return _HttpClient(context);
  }

  /// Resolves the proxy server to be used for HTTP connections.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `HttpClient.findProxyFromEnvironment`.
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return _HttpClient._findProxyFromEnvironment(url, environment);
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
