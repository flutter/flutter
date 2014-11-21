// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKDISPATCHER_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKDISPATCHER_H_

#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class CustomElementCallbackQueue;
class CustomElementMicrotaskImportStep;
class CustomElementMicrotaskStep;
class Document;
class HTMLImportLoader;

class CustomElementMicrotaskDispatcher final {
    WTF_MAKE_NONCOPYABLE(CustomElementMicrotaskDispatcher);
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CustomElementMicrotaskDispatcher);
public:
    static CustomElementMicrotaskDispatcher& instance();

    void enqueue(CustomElementCallbackQueue*);

    bool elementQueueIsEmpty() { return m_elements.isEmpty(); }

private:
    CustomElementMicrotaskDispatcher();

    void ensureMicrotaskScheduledForElementQueue();
    void ensureMicrotaskScheduled();

    static void dispatch();
    void doDispatch();

    bool m_hasScheduledMicrotask;
    enum {
        Quiescent,
        Resolving,
        DispatchingCallbacks
    } m_phase;

    Vector<RawPtr<CustomElementCallbackQueue> > m_elements;
};

}

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKDISPATCHER_H_
