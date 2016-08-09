// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fields_require_tracing.h"

namespace blink {

void PartObject::trace(Visitor* visitor) {
    m_obj1->trace(visitor); // Don't allow direct tracing.
    visitor->trace(m_obj2);
    // Missing visitor->trace(m_obj3);
    visitor->trace(m_parts);
}

void PartBObject::trace(Visitor* visitor) {
  // Missing visitor->trace(m_set);
  visitor->trace(m_vector);
}

void HeapObject::trace(Visitor* visitor) {
    // Missing visitor->trace(m_part);
    visitor->trace(m_obj);
}

}
