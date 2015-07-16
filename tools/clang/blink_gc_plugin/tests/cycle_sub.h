// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CYCLE_SUB_H_
#define CYCLE_SUB_H_

#include "heap/stubs.h"

namespace blink {

class C;

// This contains a leaking cycle:
// C -per-> A -sub-> B -ref-> C

class A : public GarbageCollectedFinalized<A> {
public:
    virtual void trace(Visitor*) {}
};

class B : public A {
public:
    virtual void trace(Visitor*);
private:
    RefPtr<C> m_c;
};

class C : public RefCounted<C> {
private:
    Persistent<A> m_a;
};

}

#endif
