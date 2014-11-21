// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTSYNCMICROTASKQUEUE_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTSYNCMICROTASKQUEUE_H_

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

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTSYNCMICROTASKQUEUE_H_
