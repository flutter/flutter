// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A [Future]-based library for making HTTP requests.
/// 
/// To use, import `package:flutter/http.dart`.
///
/// This library is based on Dart's `http` package, but differs in that it is a
/// `mojo`-based HTTP client and does not have a dependency on mirrors.
///
/// This library depends only on core Dart libraries as well as the `mojo`,
/// `mojo_services`, and `sky_services` packages.
library http;

export 'src/http/http.dart';
export 'src/http/mojo_client.dart';
export 'src/http/response.dart';
