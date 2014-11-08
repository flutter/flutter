// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CustomElementMicrotaskRunQueue_h
#define CustomElementMicrotaskRunQueue_h

#include "base/memory/weak_ptr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

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

#endif
