// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_LOADER_IMAGELOADERCALLBACK_H_
#define SKY_ENGINE_CORE_LOADER_IMAGELOADERCALLBACK_H_

#include "sky/engine/core/painting/CanvasImage.h"

namespace blink {

class ImageLoaderCallback {
public:
    virtual ~ImageLoaderCallback() {}
    virtual void handleEvent(CanvasImage* result) = 0;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_LOADER_IMAGELOADERCALLBACK_H_
