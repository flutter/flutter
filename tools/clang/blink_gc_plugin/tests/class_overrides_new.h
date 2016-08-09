// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CLASS_OVERRIDES_NEW_H_
#define CLASS_OVERRIDES_NEW_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject : public GarbageCollected<HeapObject> {
    WTF_MAKE_FAST_ALLOCATED;
public:
    void trace(Visitor*) { }
};

}

#endif
