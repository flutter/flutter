// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    // Use the local CanvasKit bundle instead of the CDN to reduce test flakiness.
    canvasKitBaseUrl: "/canvaskit/",
  },
});
