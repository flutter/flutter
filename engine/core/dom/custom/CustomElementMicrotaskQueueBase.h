// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CustomElementMicrotaskQueueBase_h
#define CustomElementMicrotaskQueueBase_h

#include "core/dom/custom/CustomElementMicrotaskStep.h"
#include "platform/heap/Handle.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

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

#endif // CustomElementMicrotaskQueueBase_h
