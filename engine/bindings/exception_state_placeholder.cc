// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/bindings/exception_state_placeholder.h"

namespace blink {

#if ENABLE(ASSERT)

NoExceptionStateAssertionChecker::NoExceptionStateAssertionChecker(
    const char* file,
    int line) {
}

#endif

}  // namespace blink
