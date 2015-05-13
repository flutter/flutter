// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/PictureRecorder.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/painting/PaintingTasks.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

Canvas::Canvas(const FloatSize& size)
    : m_size(size)
{
    m_displayList = adoptRef(new DisplayList);
    m_canvas = m_displayList->beginRecording(expandedIntSize(m_size));
}

Canvas::~Canvas()
{
}

void Canvas::drawCircle(double x, double y, double radius, Paint* paint)
{
    if (!m_canvas)
        return;
    ASSERT(paint);
    ASSERT(m_displayList->isRecording());
    m_canvas->drawCircle(x, y, radius, paint->paint());
}

PassRefPtr<DisplayList> Canvas::finishRecording()
{
    if (!isRecording())
        return nullptr;
    m_canvas = nullptr;
    m_displayList->endRecording();
    return m_displayList.release();
}

} // namespace blink
