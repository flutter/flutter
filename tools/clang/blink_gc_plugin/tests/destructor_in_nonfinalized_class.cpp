// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "destructor_in_nonfinalized_class.h"

namespace blink {

HeapObject::~HeapObject()
{
    // Do something when destructed...
    (void)this;
}

void HeapObject::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
}

}
