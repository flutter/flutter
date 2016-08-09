// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CLASS_MULTIPLE_TRACE_BASES_H_
#define CLASS_MULTIPLE_TRACE_BASES_H_

#include "heap/stubs.h"

namespace blink {

class Base : public GarbageCollected<Base> {
public:
    virtual void trace(Visitor*);
};

class Mixin : public GarbageCollectedMixin {
public:
    void trace(Visitor*);
};

class Derived : public Base, public Mixin {
    USING_GARBAGE_COLLECTED_MIXIN(HeapObject);
    // Requires trace method.
};

}

#endif
