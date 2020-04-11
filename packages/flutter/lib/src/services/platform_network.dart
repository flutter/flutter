// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// Allows an operation executed via [action] to access insecure HTTP URLs.
///
/// On some platforms (notably iOS and Android), HTTP is disallowed by default.
/// You should strive to access secure URLs from your app, but we recognize that
/// sometimes that is not possible. In such cases, use the function below to
/// allow access to HTTP URLs.
///
/// Sample usage:
///
/// ```dart
/// import 'package:flutter/services.dart' as services;
///
/// final Image image = services.allowHttp(() => Image.network('http://some_insecure_url');
/// ```
///
/// Best Practices:
/// - Do not wrap your entire app with [allowHttp]. Wrap *exactly* what you need and nothing more.
/// - Avoid libraries that require accessing HTTP URLs.
T allowHttp<T>(T action()) {
  return runZoned<T>(action, zoneValues: <Symbol, bool>{#dart.library.io.allow_http: true});
}
