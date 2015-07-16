// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CYCLE_PTRS_H_
#define CYCLE_PTRS_H_

#include "heap/stubs.h"

namespace blink {

class B;
class C;
class D;
class E;

// This contains a leaking cycle:
// E -per-> A -mem-> B -ref-> C -own-> D -own-vec-> E

// The traced cycle from A -> B -> A does not leak.

class A : public GarbageCollected<A> {
public:
    virtual void trace(Visitor*);
private:
    Member<B> m_b;
};

class B : public GarbageCollectedFinalized<B> {
public:
    virtual void trace(Visitor*);
private:
    Member<A> m_a;
    RefPtr<C> m_c;
};

class C : public RefCounted<C> {
private:
    OwnPtr<D> m_d;
};

class D {
private:
    Vector<OwnPtr<E> > m_es;
};

class E {
private:
    Persistent<A> m_a;
};

}

#endif
