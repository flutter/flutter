// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_EXCEPTION_STATE_PLACEHOLDER_H_
#define SKY_ENGINE_BINDINGS_EXCEPTION_STATE_PLACEHOLDER_H_

#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/wtf/Assertions.h"

namespace blink {

class IgnorableExceptionState final : public ExceptionState {
 public:
  ExceptionState& ReturnThis() { return *this; }
};

#define IGNORE_EXCEPTION (::blink::IgnorableExceptionState().ReturnThis())

#if ENABLE(ASSERT)

class NoExceptionStateAssertionChecker final : public ExceptionState {
 public:
  NoExceptionStateAssertionChecker(const char* file, int line);
  ExceptionState& ReturnThis() { return *this; }
};

#define ASSERT_NO_EXCEPTION \
  (::blink::NoExceptionStateAssertionChecker(__FILE__, __LINE__).ReturnThis())

#else

#define ASSERT_NO_EXCEPTION (::blink::IgnorableExceptionState().ReturnThis())

#endif

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_EXCEPTION_STATE_PLACEHOLDER_H_
