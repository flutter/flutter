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


/// If this value is a positive number, the framework will check that images
/// it renders are not more than that many kilobytes greater than the minimum
/// size needed to display the image at its current resolution without scaling.
///
/// For example, if a 100x100 image is decoded it takes roughly 53kb in memory
/// (including mipmapping overhead). If it is only ever displayed at 50x50, it
/// would take only 13kb if the cacheHeight/cacheWidth parameters had been
/// specified at that size. This problem becomes more serious for larger
/// images, such as a high resolution image from a 12MP camera, which would be
/// 64mb when decoded.
///
/// When using this setting, developers should consider whether the image will
/// be panned or scaled up in the application, how many images are being
/// displayed, and whether the application will run on multiple devices with
/// different resolutions and memory capacities.
int debugImageOverheadAllowedInKilobytes;

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
        debugNetworkImageHttpClientProvider != null ||
        debugImageOverheadAllowedInKilobytes != null) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}
