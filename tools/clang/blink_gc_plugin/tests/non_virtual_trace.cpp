// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "non_virtual_trace.h"

namespace blink {

void A::trace(Visitor* visitor)
{
}

void C::trace(Visitor* visitor)
{
    B::trace(visitor);
}

void D::trace(Visitor* visitor)
{
    B::trace(visitor);
}

}
