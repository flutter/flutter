// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A [Future]-based library for making HTTP requests.
///
/// To use, import `package:flutter/http.dart`.
///
/// This library is based on Dart's `http` package, but differs in that it does
/// not have a dependency on mirrors.
///
// TODO(chinmaygarde): The contents of `lib/src/http` will become redundant
// once https://github.com/dart-lang/http/issues/1 is fixed (removes the use
// of mirrors). Once that issue is addressed, we should get rid this directory
// and use `dart-lang/http` directly.
library http;

export 'src/http/http.dart';
export 'src/http/response.dart';
export 'src/http/mock_client.dart';
