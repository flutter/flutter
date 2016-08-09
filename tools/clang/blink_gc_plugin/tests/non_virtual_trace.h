// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NON_VIRTUAL_TRACE_H_
#define NON_VIRTUAL_TRACE_H_

#include "heap/stubs.h"

namespace blink {

class A : public GarbageCollected<A> {
public:
    void trace(Visitor*);
};

class B : public A {
};

class C : public B {
public:
    void trace(Visitor*); // Cannot override a non-virtual trace.
};

class D : public B {
public:
    virtual void trace(Visitor*); // Cannot override a non-virtual trace.
};

}

#endif
