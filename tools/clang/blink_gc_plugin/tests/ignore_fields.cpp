// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ignore_fields.h"

namespace blink {

void C::trace(Visitor* visitor)
{
    // Missing trace of m_one.
    // Not missing ignored field m_two.
}

}
