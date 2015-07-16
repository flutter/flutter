// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "class_does_not_require_finalization.h"

namespace blink {

void DoesNotNeedFinalizer::trace(Visitor* visitor)
{
}

DoesNotNeedFinalizer2::~DoesNotNeedFinalizer2()
{
}

void DoesNotNeedFinalizer2::trace(Visitor* visitor)
{
}


}
