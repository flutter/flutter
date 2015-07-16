// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "class_requires_trace_method.h"

namespace blink {

void Mixin2::trace(Visitor* visitor)
{
  Mixin::trace(visitor);
}

void Mixin3::trace(Visitor* visitor)
{
  Mixin::trace(visitor);
}

} // namespace blink
