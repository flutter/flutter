// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "class_multiple_trace_bases.h"

namespace blink {

void Base::trace(Visitor* visitor) { }

void Mixin::trace(Visitor* visitor) { }

// Missing: Derived::trace(visitor)

}
