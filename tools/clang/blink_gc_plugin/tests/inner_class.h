// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef INNER_CLASS_H_
#define INNER_CLASS_H_

#include "heap/stubs.h"

namespace blink {

class SomeObject {
private:
    class InnerObject : public GarbageCollected<InnerObject> {
    public:
        void trace(Visitor*);
    private:
        Member<InnerObject> m_obj;
    };
};

}

#endif
