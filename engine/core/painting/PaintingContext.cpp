// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

// TODO(iansf): Get rid of PaintingContext, which is only relevant to DOM-based
//              Sky apps, which are now deprecated.  For now, make the compiler
//              happy by constructing Canvas with a nullptr.
PaintingContext::PaintingContext(PassRefPtr<Element> element, const FloatSize& size)
    : Canvas(nullptr)
    , m_element(element)
{
}

PaintingContext::~PaintingContext()
{
}

void PaintingContext::commit()
{
    m_element->document().scheduleVisualUpdate();
}

} // namespace blink
