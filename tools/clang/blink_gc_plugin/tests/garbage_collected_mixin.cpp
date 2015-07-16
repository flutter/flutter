// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "garbage_collected_mixin.h"

namespace blink {

void Mixin::trace(Visitor* visitor)
{
    // Missing: visitor->trace(m_self);
}

void HeapObject::trace(Visitor* visitor)
{
    visitor->trace(m_mix);
    // Missing: Mixin::trace(visitor);
}

}
