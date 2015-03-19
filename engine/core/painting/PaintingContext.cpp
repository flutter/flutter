// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/PaintingContext.h"

#include "base/bind.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

PaintingContext::PaintingContext(const FloatSize& size, const CommitCallback& commitCallback)
    : m_size(size)
    , m_commitCallback(commitCallback)
{
    m_displayList = adoptRef(new DisplayList);
    m_canvas = m_displayList->beginRecording(expandedIntSize(size));
}

PaintingContext::~PaintingContext()
{
}

void PaintingContext::drawCircle(double x, double y, double radius, Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawCircle(x, y, radius, paint->paint());
}

void PaintingContext::commit()
{
    if (!m_canvas)
        return;
    m_displayList->endRecording();
    m_canvas = nullptr;
    Microtask::enqueueMicrotask(base::Bind(m_commitCallback, this));
}

} // namespace blink
