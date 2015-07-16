// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TEMPLATED_CLASS_WITH_LOCAL_CLASS_REQUIRES_TRACE_H
#define TEMPLATED_CLASS_WITH_LOCAL_CLASS_REQUIRES_TRACE_H

#include "heap/stubs.h"

namespace blink {

class NonHeapObject { };

class HeapObject : public GarbageCollected<HeapObject> {
public:
    HeapObject() { }

    void trace(Visitor*) { }
};

template<typename T>
class TemplatedObject final
    : public GarbageCollectedFinalized<TemplatedObject<T> > {
public:
    TemplatedObject(T*)
    {
    }

    void trace(Visitor*);

private:
    class Local final : public GarbageCollected<Local> {
    public:
        void trace(Visitor* visitor)
        {
            visitor->trace(m_heapObject);
            visitor->trace(m_object);
        }
    private:
        Member<HeapObject> m_heapObject;
        OwnPtr<HeapObject> m_object;
    };

    Member<Local> m_local;
    Member<T> m_memberRef;
    OwnPtr<T> m_ownRef;
};

} // namespace blink

#endif // TEMPLATED_CLASS_WITH_LOCAL_CLASS_REQUIRES_TRACE_H

