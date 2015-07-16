// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PURE_VIRTUAL_TRACE_H_
#define PURE_VIRTUAL_TRACE_H_

#include "heap/stubs.h"

namespace blink {

class A : public GarbageCollected<A> {
public:
    virtual void trace(Visitor*) = 0;
};

}

#endif
