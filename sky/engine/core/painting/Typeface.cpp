// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Typeface.h"

namespace blink {

Typeface::Typeface(PassRefPtr<SkTypeface> typeface)
    : typeface_(typeface) {
}

Typeface::~Typeface()
{
}

} // namespace blink
