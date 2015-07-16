// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRACE_IF_NEEDED_H_
#define TRACE_IF_NEEDED_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject : public GarbageCollected<HeapObject> { };

template<typename T>
class TemplatedObject : public GarbageCollected<TemplatedObject<T> > {
public:
    virtual void trace(Visitor*);
private:
    T m_one;
    T m_two;
};

class InstantiatedObject : public TemplatedObject<Member<HeapObject> > { };

}

#endif
