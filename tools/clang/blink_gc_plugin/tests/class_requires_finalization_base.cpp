// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "class_requires_finalization_base.h"

namespace blink {

void NeedsFinalizer::trace(Visitor* visitor)
{
    A::trace(visitor);
}

void DoesNotNeedFinalizer::trace(Visitor* visitor)
{
    A::trace(visitor);
}

void GCedClassWithAScriptWrappableBase::trace(Visitor* visitor)
{
    A::trace(visitor);
}

void GCedClassWithAScriptWrappableAndAFinalizableBase::trace(Visitor* visitor)
{
    GCedClassWithAScriptWrappableBase::trace(visitor);
}

}
