// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Returns the URL to load an asset from this example app as a network source.
//
// TODO(stuartmorgan): Convert this to a local `HttpServer` that vends the
// assets directly, https://github.com/flutter/flutter/issues/95420
String getUrlForAssetAsNetworkSource(String assetKey) {
  return 'https://github.com/flutter/plugins/blob/'
      // This hash can be rolled forward to pick up newly-added assets.
      'cb381ced070d356799dddf24aca38ce0579d3d7b'
      '/packages/video_player/video_player/example/'
      '$assetKey'
      '?raw=true';
}
