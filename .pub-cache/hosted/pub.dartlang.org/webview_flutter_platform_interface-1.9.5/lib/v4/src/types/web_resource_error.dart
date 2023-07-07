// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

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

/// Error returned in `WebView.onWebResourceError` when a web resource loading error has occurred.
///
/// Platform specific implementations can add additional fields by extending
/// this class.
///
/// {@tool sample}
/// This example demonstrates how to extend the [WebResourceError] to
/// provide additional platform specific parameters.
///
/// When extending [WebResourceError] additional parameters should always
/// accept `null` or have a default value to prevent breaking changes.
///
/// ```dart
/// class IOSWebResourceError extends WebResourceError {
///   IOSWebResourceError._(WebResourceError error, {required this.domain})
///       : super(
///           errorCode: error.errorCode,
///           description: error.description,
///           errorType: error.errorType,
///         );
///
///   factory IOSWebResourceError.fromWebResourceError(
///     WebResourceError error, {
///     required String? domain,
///   }) {
///     return IOSWebResourceError._(error, domain: domain);
///   }
///
///   final String? domain;
/// }
/// ```
/// {@end-tool}
@immutable
class WebResourceError {
  /// Used by the platform implementation to create a new [WebResourceError].
  const WebResourceError({
    required this.errorCode,
    required this.description,
    this.errorType,
  });

  /// Raw code of the error from the respective platform.
  final int errorCode;

  /// Description of the error that can be used to communicate the problem to the user.
  final String description;

  /// The type this error can be categorized as.
  final WebResourceErrorType? errorType;
}
