// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Possible error type categorizations used by [WebResourceError].
enum WebResourceErrorType {
  /// User authentication failed on server.
  authentication,

  /// Malformed URL.
  badUrl,

  /// Failed to connect to the server.
  connect,

  /// Failed to perform SSL handshake.
  failedSslHandshake,

  /// Generic file error.
  file,

  /// File not found.
  fileNotFound,

  /// Server or proxy hostname lookup failed.
  hostLookup,

  /// Failed to read or write to the server.
  io,

  /// User authentication failed on proxy.
  proxyAuthentication,

  /// Too many redirects.
  redirectLoop,

  /// Connection timed out.
  timeout,

  /// Too many requests during this load.
  tooManyRequests,

  /// Generic error.
  unknown,

  /// Resource load was canceled by Safe Browsing.
  unsafeResource,

  /// Unsupported authentication scheme (not basic or digest).
  unsupportedAuthScheme,

  /// Unsupported URI scheme.
  unsupportedScheme,

  /// The web content process was terminated.
  webContentProcessTerminated,

  /// The web view was invalidated.
  webViewInvalidated,

  /// A JavaScript exception occurred.
  javaScriptExceptionOccurred,

  /// The result of JavaScript execution could not be returned.
  javaScriptResultTypeIsUnsupported,
}
