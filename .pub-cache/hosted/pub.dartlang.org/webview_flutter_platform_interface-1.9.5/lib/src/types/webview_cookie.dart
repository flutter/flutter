// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A cookie that can be set globally for all web views
/// using [WebViewCookieManagerPlatform].
class WebViewCookie {
  /// Constructs a new [WebViewCookie].
  const WebViewCookie(
      {required this.name,
      required this.value,
      required this.domain,
      this.path = '/'});

  /// The cookie-name of the cookie.
  ///
  /// Its value should match "cookie-name" in RFC6265bis:
  /// https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-02#section-4.1.1
  final String name;

  /// The cookie-value of the cookie.
  ///
  /// Its value should match "cookie-value" in RFC6265bis:
  /// https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-02#section-4.1.1
  final String value;

  /// The domain-value of the cookie.
  ///
  /// Its value should match "domain-value" in RFC6265bis:
  /// https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-02#section-4.1.1
  final String domain;

  /// The path-value of the cookie.
  /// Is set to `/` in the constructor by default.
  ///
  /// Its value should match "path-value" in RFC6265bis:
  /// https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-02#section-4.1.1
  final String path;

  /// Serializes the [WebViewCookie] to a Map<String, String>.
  Map<String, String> toJson() {
    return <String, String>{
      'name': name,
      'value': value,
      'domain': domain,
      'path': path
    };
  }
}
