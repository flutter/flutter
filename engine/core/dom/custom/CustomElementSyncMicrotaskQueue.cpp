// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/dom/custom/CustomElementSyncMicrotaskQueue.h"

namespace blink {

void CustomElementSyncMicrotaskQueue::enqueue(PassOwnPtrWillBeRawPtr<CustomElementMicrotaskStep> step)
{
    m_queue.append(step);
}

void CustomElementSyncMicrotaskQueue::doDispatch()
{
    unsigned i;

    for (i = 0; i < m_queue.size(); ++i) {
        if (CustomElementMicrotaskStep::Processing == m_queue[i]->process())
            break;
    }

    m_queue.remove(0, i);
}

} // namespace blink
