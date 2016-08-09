// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DESTRUCTOR_ACCESS_FINALIZED_FIELD_H_
#define DESTRUCTOR_ACCESS_FINALIZED_FIELD_H_

#include "heap/stubs.h"

namespace blink {

class Other : public RefCounted<Other> {
public:
    bool foo() { return true; }
};

class HeapObject;

class PartOther {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    void trace(Visitor*);

    HeapObject* obj() { return m_obj; }

private:
    Member<HeapObject> m_obj;
};

class HeapObject : public GarbageCollectedFinalized<HeapObject> {
public:
    ~HeapObject();
    void trace(Visitor*);
    bool foo() { return true; }
    void bar(HeapObject*) { }
private:
    RefPtr<Other> m_ref;
    Member<HeapObject> m_obj;
    Vector<Member<HeapObject> > m_objs;
    PartOther m_part;
};

}

#endif
