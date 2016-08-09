// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "cycle_super.h"

namespace blink {

void A::trace(Visitor* visitor) {
    visitor->trace(m_d);
}

void B::trace(Visitor* visitor) {
    A::trace(visitor);
}

void C::trace(Visitor* visitor) {
    B::trace(visitor);
}

}
