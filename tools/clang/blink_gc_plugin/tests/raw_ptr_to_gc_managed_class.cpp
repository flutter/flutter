// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "raw_ptr_to_gc_managed_class.h"

namespace blink {

void HeapObject::trace(Visitor* visitor) {
    visitor->trace(m_objs);
}

}
