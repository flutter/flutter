// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "class_requires_finalization_mixin.h"

namespace blink {

void MixinFinalizable::trace(Visitor* visitor)
{
    visitor->trace(m_onHeap);
}

void MixinNotFinalizable::trace(Visitor* visitor)
{
    visitor->trace(m_onHeap);
}

void NeedsFinalizer::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
    MixinFinalizable::trace(visitor);
}

void HasFinalizer::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
    MixinFinalizable::trace(visitor);
}

void NeedsNoFinalization::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
    MixinNotFinalizable::trace(visitor);
}

}
