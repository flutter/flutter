// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base_requires_tracing.h"

namespace blink {

void A::trace(Visitor* visitor) { }

void C::trace(Visitor* visitor) {
  visitor->trace(m_a);
  // Missing B::trace(visitor)
}

void D::trace(Visitor* visitor) {
  visitor->trace(m_a);
  C::trace(visitor);
}

}
