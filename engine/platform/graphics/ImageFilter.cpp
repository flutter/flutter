// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "ImageFilter.h"

#include "third_party/skia/include/core/SkImageFilter.h"

namespace blink {

FloatRect mapImageFilterRect(ImageFilter* filter, const FloatRect& rect)
{
    SkRect dest;
    filter->computeFastBounds(rect, &dest);
    return dest;
}

} // namespace blink
