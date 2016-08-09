// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "weak_fields_require_tracing.h"

namespace blink {

void HeapObject::trace(Visitor* visitor)
{
    // Missing visitor->trace(m_obj1);
    // Missing visitor->trace(m_obj2);
    // visitor->trace(m_obj3) in callback.
    // Missing visitor->trace(m_set1);
    visitor->trace(m_set2);
    visitor->registerWeakMembers<HeapObject,
                                 &HeapObject::clearWeakMembers>(this);
}

void HeapObject::clearWeakMembers(Visitor* visitor)
{
    visitor->trace(m_obj1);  // Does not count.
    // Missing visitor->trace(m_obj2);
    visitor->trace(m_obj3);  // OK.
    visitor->trace(m_set1);  // Does not count.
}

}
