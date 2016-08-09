// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "virtual_and_trace_after_dispatch.h"

namespace blink {

static B* toB(A* a) { return static_cast<B*>(a); }

void A::trace(Visitor* visitor)
{
    switch (m_type) {
    case TB:
        toB(this)->traceAfterDispatch(visitor);
        break;
    }
}

void A::traceAfterDispatch(Visitor* visitor)
{
}

void B::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_a);
    A::traceAfterDispatch(visitor);
}

}
