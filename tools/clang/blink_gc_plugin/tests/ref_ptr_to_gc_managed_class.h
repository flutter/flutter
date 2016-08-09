// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef REF_PTR_TO_GC_MANAGED_CLASS_H_
#define REF_PTR_TO_GC_MANAGED_CLASS_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject;

class PartObject {
    DISALLOW_ALLOCATION();
private:
    RefPtr<HeapObject> m_obj;
};

class HeapObject : public GarbageCollectedFinalized<HeapObject> {
public:
    void trace(Visitor*);
private:
    PartObject m_part;
    Vector<RefPtr<HeapObject> > m_objs;
};

}

#endif
