// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WebDeviceEmulationParams_h
#define WebDeviceEmulationParams_h

#include "public/platform/WebFloatPoint.h"
#include "public/platform/WebRect.h"
#include "public/platform/WebSize.h"

namespace blink {

// All sizes are measured in device independent pixels.
struct WebDeviceEmulationParams {
    // For mobile, screen has the same size as view, which is positioned at (0;0).
    // For desktop, screen size and view position are preserved.
    enum ScreenPosition {
        Desktop,
        Mobile
    };

    ScreenPosition screenPosition;

    // If zero, the original device scale factor is preserved.
    float deviceScaleFactor;

    // Emulated view size. Empty size means no override.
    WebSize viewSize;

    // Whether emulated view should be scaled down if necessary to fit into available space.
    bool fitToView;

    // Offset of emulated view inside available space, not in fit to view mode.
    WebFloatPoint offset;

    // Scale of emulated view inside available space, not in fit to view mode.
    float scale;

    WebDeviceEmulationParams()
        : screenPosition(Desktop)
        , deviceScaleFactor(0)
        , fitToView(false)
        , scale(1) { }
};

} // namespace blink

#endif
