// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKQUEUEBASE_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKQUEUEBASE_H_

#include "sky/engine/core/dom/custom/CustomElementMicrotaskStep.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class CustomElementMicrotaskQueueBase : public RefCounted<CustomElementMicrotaskQueueBase> {
    WTF_MAKE_NONCOPYABLE(CustomElementMicrotaskQueueBase);
public:
    virtual ~CustomElementMicrotaskQueueBase() { }

    bool isEmpty() const { return m_queue.isEmpty(); }
    void dispatch();

protected:
    CustomElementMicrotaskQueueBase() : m_inDispatch(false) { }
    virtual void doDispatch() = 0;

    Vector<OwnPtr<CustomElementMicrotaskStep> > m_queue;
    bool m_inDispatch;
};

}

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKQUEUEBASE_H_
