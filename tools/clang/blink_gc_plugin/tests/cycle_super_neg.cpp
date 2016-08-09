// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "cycle_super_neg.h"

namespace blink {

void B::trace(Visitor* visitor) {
    A::trace(visitor);
}

void D::trace(Visitor* visitor) {
    visitor->trace(m_c);
    A::trace(visitor);
}

}
