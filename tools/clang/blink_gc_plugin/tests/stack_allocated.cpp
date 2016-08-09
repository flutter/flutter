// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "stack_allocated.h"

namespace blink {

// Verify that anon namespaces are checked.
namespace {

class AnonStackObject : public StackObject {
public:
    HeapObject* m_obj;
};

}

void HeapObject::trace(Visitor* visitor)
{
}

}
