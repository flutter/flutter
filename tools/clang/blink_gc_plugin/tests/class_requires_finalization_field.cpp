// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "class_requires_finalization_field.h"

namespace blink {

void NeedsFinalizer::trace(Visitor* visitor)
{
    visitor->trace(m_as);
    A::trace(visitor);
}

void AlsoNeedsFinalizer::trace(Visitor* visitor)
{
    visitor->trace(m_bs);
    A::trace(visitor);
}

void DoesNotNeedFinalizer::trace(Visitor* visitor)
{
    visitor->trace(m_bs);
    A::trace(visitor);
}

void AlsoDoesNotNeedFinalizer::trace(Visitor* visitor)
{
    visitor->trace(m_as);
    visitor->trace(m_cs);
    A::trace(visitor);
}

}
