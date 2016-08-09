// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRACE_COLLECTIONS_H_
#define TRACE_COLLECTIONS_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject : public GarbageCollected<HeapObject> {
public:
    void trace(Visitor*);
private:
    HeapVector<Member<HeapObject> > m_heapVector;
    Vector<Member<HeapObject>, 0, HeapAllocator> m_wtfVector;

    HeapDeque<Member<HeapObject> > m_heapDeque;
    Deque<Member<HeapObject>, 0, HeapAllocator> m_wtfDeque;

    HeapHashSet<Member<HeapObject> > m_heapSet;
    HashSet<Member<HeapObject>, void, HeapAllocator> m_wtfSet;

    HeapListHashSet<Member<HeapObject> > m_heapListSet;
    ListHashSet<Member<HeapObject>, void, HeapAllocator> m_wtfListSet;

    HeapLinkedHashSet<Member<HeapObject> > m_heapLinkedSet;
    LinkedHashSet<Member<HeapObject>, void, HeapAllocator> m_wtfLinkedSet;

    HeapHashCountedSet<Member<HeapObject> > m_heapCountedSet;
    HashCountedSet<Member<HeapObject>, void, HeapAllocator> m_wtfCountedSet;

    HeapHashMap<int, Member<HeapObject> > m_heapMapKey;
    HeapHashMap<Member<HeapObject>, int > m_heapMapVal;
    HashMap<int, Member<HeapObject>, void, void, void, HeapAllocator>
    m_wtfMapKey;
    HashMap<Member<HeapObject>, int, void, void, void, HeapAllocator>
    m_wtfMapVal;
};

}

#endif
