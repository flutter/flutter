// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/RRect.h"

namespace blink {

RRect::RRect()
{
}

RRect::~RRect()
{
}

void RRect::setRectXY(const Rect& rect, float xRad, float yRad)
{
 	m_rrect.setRectXY(rect.sk_rect, xRad, yRad);
}

} // namespace blink
