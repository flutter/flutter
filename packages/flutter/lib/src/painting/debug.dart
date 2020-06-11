// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Whether to replace all shadows with solid color blocks.
///
/// This is useful when writing golden file tests (see [matchesGoldenFile]) since
/// the rendering of shadows is not guaranteed to be pixel-for-pixel identical from
/// version to version (or even from run to run).
bool debugDisableShadows = false;

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
/// This value is ignored in non-debug builds.
HttpClientProvider debugNetworkImageHttpClientProvider;

/// Returns true if none of the painting library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [the painting library](painting/painting-library.html) for a complete
/// list.
///
/// The `debugDisableShadowsOverride` argument can be provided to override
/// the expected value for [debugDisableShadows]. (This exists because the
/// test framework itself overrides this value in some cases.)
bool debugAssertAllPaintingVarsUnset(String reason, { bool debugDisableShadowsOverride = false }) {
  assert(() {
    if (debugDisableShadows != debugDisableShadowsOverride ||
        debugNetworkImageHttpClientProvider != null) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}
