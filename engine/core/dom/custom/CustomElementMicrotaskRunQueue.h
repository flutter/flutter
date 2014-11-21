// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKRUNQUEUE_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKRUNQUEUE_H_

#include "base/memory/weak_ptr.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class CustomElementSyncMicrotaskQueue;
class CustomElementAsyncImportMicrotaskQueue;
class CustomElementMicrotaskStep;
class HTMLImportLoader;

class CustomElementMicrotaskRunQueue : public RefCounted<CustomElementMicrotaskRunQueue> {
public:
    static PassRefPtr<CustomElementMicrotaskRunQueue> create() { return adoptRef(new CustomElementMicrotaskRunQueue()); }
    ~CustomElementMicrotaskRunQueue();

    void enqueue(HTMLImportLoader* parentLoader, PassOwnPtr<CustomElementMicrotaskStep>, bool importIsSync);
    void requestDispatchIfNeeded();
    bool isEmpty() const;

private:
    CustomElementMicrotaskRunQueue();

    void dispatch();

    RefPtr<CustomElementSyncMicrotaskQueue> m_syncQueue;
    RefPtr<CustomElementAsyncImportMicrotaskQueue> m_asyncQueue;
    bool m_dispatchIsPending;

    base::WeakPtrFactory<CustomElementMicrotaskRunQueue> m_weakFactory;
};

}

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKRUNQUEUE_H_
