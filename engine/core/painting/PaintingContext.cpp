// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/PaintingContext.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/painting/PaintingTasks.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

PassRefPtr<PaintingContext> PaintingContext::create(PassRefPtr<Element> element, const FloatSize& size)
{
    return adoptRef(new PaintingContext(element, size));
}

PaintingContext::PaintingContext(PassRefPtr<Element> element, const FloatSize& size)
    : m_element(element)
    , m_size(size)
{
    m_displayList = adoptRef(new DisplayList);
    m_canvas = m_displayList->beginRecording(expandedIntSize(m_size));
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
    PaintingTasks::enqueueCommit(m_element, m_displayList.release());
    m_element->document().scheduleVisualUpdate();
}

} // namespace blink
