// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PART_OBJECT_TO_GC_DERIVED_CLASS_H_
#define PART_OBJECT_TO_GC_DERIVED_CLASS_H_

#include "heap/stubs.h"

namespace blink {

class A : public GarbageCollected<A> { };

class B : public GarbageCollected<B> {
public:
    void trace(Visitor*);
private:
    A m_a;
};

}

#endif
