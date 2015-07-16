// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DESTRUCTOR_IN_NONFINALIZED_CLASS_H_
#define DESTRUCTOR_IN_NONFINALIZED_CLASS_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject : public GarbageCollected<HeapObject> {
public:
    ~HeapObject();
    void trace(Visitor*);
private:
    Member<HeapObject> m_obj;
};

}

#endif
