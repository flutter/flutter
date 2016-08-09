// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IGNORE_FIELDS_H_
#define IGNORE_FIELDS_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject : public GarbageCollected<HeapObject> {
public:
    virtual void trace(Visitor*) { }
};

// Don't warn about raw pointers to heap allocated objects.
class A : public GarbageCollected<A>{
private:
    GC_PLUGIN_IGNORE("http://crbug.com/12345")
    HeapObject* m_obj;
};

// Don't require trace method when (all) GC fields are ignored.
class B : public GarbageCollected<B> {
private:
    GC_PLUGIN_IGNORE("http://crbug.com/12345")
    Member<HeapObject> m_one;
};

// Don't require tracing an ignored field.
class C : public GarbageCollected<C> {
public:
    void trace(Visitor*);
private:
    Member<HeapObject> m_one;
    GC_PLUGIN_IGNORE("http://crbug.com/12345")
    Member<HeapObject> m_two;
};

}

#endif
