// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBSCREENORIENTATIONTYPE_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBSCREENORIENTATIONTYPE_H_

namespace blink {

enum WebScreenOrientationType {
    WebScreenOrientationUndefined = 0,
    WebScreenOrientationPortraitPrimary,
    WebScreenOrientationPortraitSecondary,
    WebScreenOrientationLandscapePrimary,
    WebScreenOrientationLandscapeSecondary
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBSCREENORIENTATIONTYPE_H_
