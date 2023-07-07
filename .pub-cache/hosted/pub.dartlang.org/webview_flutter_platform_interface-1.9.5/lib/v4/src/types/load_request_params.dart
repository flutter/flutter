// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../platform_webview_controller.dart';

/// Defines the supported HTTP methods for loading a page in [PlatformWebViewController].
enum LoadRequestMethod {
  /// HTTP GET method.
  get,

  /// HTTP POST method.
  post,
}

/// Extension methods on the [LoadRequestMethod] enum.
extension LoadRequestMethodExtensions on LoadRequestMethod {
  /// Converts [LoadRequestMethod] to [String] format.
  String serialize() {
    switch (this) {
      case LoadRequestMethod.get:
        return 'get';
      case LoadRequestMethod.post:
        return 'post';
    }
  }
}

/// Defines the parameters that can be used to load a page with the [PlatformWebViewController].
///
/// Platform specific implementations can add additional fields by extending
/// this class.
///
/// {@tool sample}
/// This example demonstrates how to extend the [LoadRequestParams] to
/// provide additional platform specific parameters.
///
/// When extending [LoadRequestParams] additional parameters should always
/// accept `null` or have a default value to prevent breaking changes.
///
/// ```dart
/// class AndroidLoadRequestParams extends LoadRequestParams {
///   AndroidLoadRequestParams._({
///     required LoadRequestParams params,
///     this.historyUrl,
///   }) : super(
///     uri: params.uri,
///     method: params.method,
///     body: params.body,
///     headers: params.headers,
///   );
///
///   factory AndroidLoadRequestParams.fromLoadRequestParams(
///     LoadRequestParams params, {
///     Uri? historyUrl,
///   }) {
///     return AndroidLoadRequestParams._(params, historyUrl: historyUrl);
///   }
///
///   final Uri? historyUrl;
/// }
/// ```
/// {@end-tool}
@immutable
class LoadRequestParams {
  /// Used by the platform implementation to create a new [LoadRequestParams].
  const LoadRequestParams({
    required this.uri,
    required this.method,
    required this.headers,
    this.body,
  });

  /// URI for the request.
  final Uri uri;

  /// HTTP method used to make the request.
  final LoadRequestMethod method;

  /// Headers for the request.
  final Map<String, String> headers;

  /// HTTP body for the request.
  final Uint8List? body;
}
