// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Object specifying creation parameters for creating a [PlatformWebViewCookieManager].
///
/// Platform specific implementations can add additional fields by extending
/// this class.
///
/// {@tool sample}
/// This example demonstrates how to extend the [PlatformWebViewCookieManagerCreationParams] to
/// provide additional platform specific parameters.
///
/// When extending [PlatformWebViewCookieManagerCreationParams] additional
/// parameters should always accept `null` or have a default value to prevent
/// breaking changes.
///
/// ```dart
/// class WKWebViewCookieManagerCreationParams
///     extends PlatformWebViewCookieManagerCreationParams {
///   WKWebViewCookieManagerCreationParams._(
///     // This parameter prevents breaking changes later.
///     // ignore: avoid_unused_constructor_parameters
///     PlatformWebViewCookieManagerCreationParams params, {
///     this.uri,
///   }) : super();
///
///   factory WKWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
///     PlatformWebViewCookieManagerCreationParams params, {
///     Uri? uri,
///   }) {
///     return WKWebViewCookieManagerCreationParams._(params, uri: uri);
///   }
///
///   final Uri? uri;
/// }
/// ```
/// {@end-tool}
@immutable
class PlatformWebViewCookieManagerCreationParams {
  /// Used by the platform implementation to create a new [PlatformWebViewCookieManagerDelegate].
  const PlatformWebViewCookieManagerCreationParams();
}
