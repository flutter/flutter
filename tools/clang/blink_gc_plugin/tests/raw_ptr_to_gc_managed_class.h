// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RAW_PTR_TO_GC_MANAGED_CLASS_H_
#define RAW_PTR_TO_GC_MANAGED_CLASS_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject;

class PartObject {
    DISALLOW_ALLOCATION();
private:
    RawPtr<HeapObject> m_obj;
};

class HeapObject : public GarbageCollected<HeapObject> {
public:
    void trace(Visitor*);
private:
    PartObject m_part;
    HeapVector<HeapObject*> m_objs;
};

}

#endif
