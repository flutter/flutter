// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DESTRUCTOR_EAGERLY_FINALIZED_H_
#define DESTRUCTOR_EAGERLY_FINALIZED_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject : public GarbageCollected<HeapObject> {
public:
    void trace(Visitor*) { }
    void foo() { }
};

class HeapObjectEagerFinalized
    : public GarbageCollectedFinalized<HeapObjectEagerFinalized> {
public:
    EAGERLY_FINALIZED();
    ~HeapObjectEagerFinalized();
    void trace(Visitor*);

    void foo() { }

private:
    Member<HeapObject> m_obj;
};

// Accessing other eagerly finalized objects during finalization is not allowed.
class HeapObjectEagerFinalizedAlso
    : public GarbageCollectedFinalized<HeapObjectEagerFinalizedAlso> {
public:
    EAGERLY_FINALIZED();
    ~HeapObjectEagerFinalizedAlso();
    void trace(Visitor*);

private:
    Member<HeapObject> m_heapObject;
    Member<HeapObjectEagerFinalized> m_heapObjectFinalized;
    HeapVector<Member<HeapObjectEagerFinalized>> m_heapVector;
};

} // namespace blink

#endif // DESTRUCTOR_EAGERLY_FINALIZED_H_
