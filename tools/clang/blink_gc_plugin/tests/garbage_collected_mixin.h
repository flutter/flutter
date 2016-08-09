// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GARBAGE_COLLECTED_MIXIN_H_
#define GARBAGE_COLLECTED_MIXIN_H_

#include "heap/stubs.h"

namespace blink {

class Mixin : public GarbageCollectedMixin {
public:
    virtual void trace(Visitor*) override;
private:
    Member<Mixin> m_self;
};

class HeapObject : public GarbageCollected<HeapObject>, public Mixin {
    USING_GARBAGE_COLLECTED_MIXIN(HeapObject);
public:
    virtual void trace(Visitor*) override;
private:
    Member<Mixin> m_mix;
};

}

#endif
