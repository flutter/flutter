// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Service exposed to Flutter apps that implements a subset of Dart's
/// http package API.
///
/// This library will probably be moved into a separate package eventually.
///
/// This library depends only on core Dart libraries as well as the `mojo`,
/// `mojo_services`, and `sky_services` and packages.
library http;

export 'src/http/http.dart';
export 'src/http/response.dart';
