// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CustomElementSyncMicrotaskQueue_h
#define CustomElementSyncMicrotaskQueue_h

#include "sky/engine/core/dom/custom/CustomElementMicrotaskQueueBase.h"

namespace blink {

class CustomElementSyncMicrotaskQueue : public CustomElementMicrotaskQueueBase {
public:
    static PassRefPtr<CustomElementSyncMicrotaskQueue> create() { return adoptRef(new CustomElementSyncMicrotaskQueue()); }

    void enqueue(PassOwnPtr<CustomElementMicrotaskStep>);

private:
    CustomElementSyncMicrotaskQueue() { }
    virtual void doDispatch();
};

}

#endif
