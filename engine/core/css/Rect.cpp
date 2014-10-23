// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/Rect.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(RectBase)

void RectBase::trace(Visitor* visitor)
{
    visitor->trace(m_top);
    visitor->trace(m_right);
    visitor->trace(m_bottom);
    visitor->trace(m_left);
}

}
