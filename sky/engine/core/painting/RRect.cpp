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

PassRefPtr<RRect> RRect::shift(const Offset& offset) {
    RefPtr<RRect> rrect = RRect::create();
    rrect->m_rrect = m_rrect;
    rrect->m_rrect.offset(offset.sk_size.width(), offset.sk_size.height());
    return rrect.release();
}

} // namespace blink
