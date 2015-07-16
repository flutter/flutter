// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CYCLE_SUPER_NEG_H_
#define CYCLE_SUPER_NEG_H_

#include "heap/stubs.h"

namespace blink {

class C;

// The chain:
//   C -per-> B -sup-> A -sub-> D -ref-> C
// is not a leaking cycle, because the super-class relationship
// should not transitively imply sub-class relationships.
// I.e. B -/-> D

class A : public GarbageCollectedFinalized<A> {
public:
    virtual void trace(Visitor*) {}
};

class B : public A {
public:
    virtual void trace(Visitor*);
};

class C : public RefCounted<C> {
private:
    Persistent<B> m_b;
};

class D : public A {
public:
    virtual void trace(Visitor*);
private:
    RefPtr<C> m_c;
};

}

#endif
