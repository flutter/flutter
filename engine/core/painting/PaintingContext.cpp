// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/PaintingContext.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/painting/PaintingTasks.h"
#include "sky/engine/platform/geometry/IntRect.h"

namespace blink {

PassRefPtr<PaintingContext> PaintingContext::create(PassRefPtr<Element> element, const FloatSize& size)
{
    return adoptRef(new PaintingContext(element, size));
}

PaintingContext::PaintingContext(PassRefPtr<Element> element, const FloatSize& size)
    : Canvas(size)
    , m_element(element)
{
}

PaintingContext::~PaintingContext()
{
}

void PaintingContext::commit()
{
    if (!isRecording())
        return;
    PaintingTasks::enqueueCommit(m_element, finishRecording());
    m_element->document().scheduleVisualUpdate();
}

} // namespace blink
