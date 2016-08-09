// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "destructor_eagerly_finalized.h"

namespace blink {

HeapObjectEagerFinalized::~HeapObjectEagerFinalized()
{
    // Valid access to a non-eagerly finalized field
    m_obj->foo();
}

void HeapObjectEagerFinalized::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
}

HeapObjectEagerFinalizedAlso::~HeapObjectEagerFinalizedAlso()
{
    // Valid access to a non-eagerly finalized field
    m_heapObject->foo();

    // Non-valid accesses to eagerly finalized fields.
    m_heapObjectFinalized->foo();
    m_heapVector[0]->foo();
}

void HeapObjectEagerFinalizedAlso::trace(Visitor* visitor)
{
    visitor->trace(m_heapObject);
    visitor->trace(m_heapObjectFinalized);
    visitor->trace(m_heapVector);
}

} // namespace blink
