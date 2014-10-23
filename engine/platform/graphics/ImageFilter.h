// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ImageFilter_h
#define ImageFilter_h

#include "platform/geometry/FloatRect.h"

class SkImageFilter;

namespace blink {

typedef SkImageFilter ImageFilter;

PLATFORM_EXPORT FloatRect mapImageFilterRect(ImageFilter*, const FloatRect&);

} // namespace blink

#endif // ImageFilter_h
