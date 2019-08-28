// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Signature for a method that returns an [HttpClient].
///
/// Used by [debugNetworkImageHttpClientProvider].
typedef HttpClientProvider = HttpClient Function();

/// Provider from which [NetworkImage] will get its [HttpClient] in debug builds.
///
/// If this value is unset, [NetworkImage] will use its own internally-managed
/// [HttpClient].
///
/// This setting can be overridden for testing to ensure that each test receives
/// a mock client that hasn't been affected by other tests.
///
/// This value is ignored in non-debug builds and on the web.
HttpClientProvider debugNetworkImageHttpClientProvider;
