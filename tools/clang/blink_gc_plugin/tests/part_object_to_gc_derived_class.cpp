// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "part_object_to_gc_derived_class.h"

namespace blink {

void B::trace(Visitor* visitor)
{
    visitor->trace(m_a);
}

}
