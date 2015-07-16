// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CLASS_MUST_DEFINE_VIRTUAL_TRACE_H_
#define BASE_CLASS_MUST_DEFINE_VIRTUAL_TRACE_H_

#include "heap/stubs.h"

namespace blink {

class PartBase {
    DISALLOW_ALLOCATION();
    // Missing virtual trace.
};

class PartDerived : public PartBase {
    DISALLOW_ALLOCATION();
public:
    virtual void trace(Visitor*);
};

class HeapBase : public GarbageCollected<HeapBase> {
    // Missing virtual trace.
};


class HeapDerived : public HeapBase {
public:
    virtual void trace(Visitor*);
private:
    PartDerived m_part;
};


}

#endif
