// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/dom/custom/CustomElementMicrotaskQueueBase.h"

#include "sky/engine/core/dom/custom/CustomElementProcessingStack.h"

namespace blink {

void CustomElementMicrotaskQueueBase::dispatch()
{
    ASSERT(!m_inDispatch);
    m_inDispatch = true;
    doDispatch();
    m_inDispatch = false;
}

} // namespace blink
