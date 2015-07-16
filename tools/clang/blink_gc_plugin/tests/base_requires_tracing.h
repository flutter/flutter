// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_REQUIRES_TRACING_H_
#define BASE_REQUIRES_TRACING_H_

#include "heap/stubs.h"

namespace blink {

class A : public GarbageCollected<A> {
public:
    virtual void trace(Visitor*);
};

class B : public A {
    // Does not need trace
};

class C : public B {
public:
    void trace(Visitor*);
private:
    Member<A> m_a;
};

class D : public C {
public:
    void trace(Visitor*);
private:
    Member<A> m_a;
};

}

#endif
