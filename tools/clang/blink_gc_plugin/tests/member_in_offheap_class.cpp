// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "member_in_offheap_class.h"

namespace blink {

void OffHeapObject::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
}

void PartObject::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
}

void InlineObject::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
}

}
