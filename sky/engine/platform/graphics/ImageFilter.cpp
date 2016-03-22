// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/platform/graphics/ImageFilter.h"

#include "third_party/skia/include/core/SkImageFilter.h"

namespace blink {

FloatRect mapImageFilterRect(ImageFilter* filter, const FloatRect& rect)
{
    return filter->computeFastBounds(rect);
}

} // namespace blink
