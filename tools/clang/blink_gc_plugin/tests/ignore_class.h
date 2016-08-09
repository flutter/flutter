// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IGNORE_CLASS_H_
#define IGNORE_CLASS_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject : public GarbageCollected<HeapObject> { };

// Don't require trace method on ignored class.
class GC_PLUGIN_IGNORE("http://crbug.com/12345") A;
class A : public GarbageCollected<A> {
private:
    Member<HeapObject> m_obj;
};

// Don't require tracing of fields on ignored class.
class GC_PLUGIN_IGNORE("http://crbug.com/12345") B;
class B : public GarbageCollected<B> {
public:
    virtual void trace(Visitor*);
private:
    Member<HeapObject> m_obj;
};

// Don't require tracing of an ignored base class.
class C : public B {
public:
    void trace(Visitor*);
private:
    Member<HeapObject> m_obj;
};

}

#endif
