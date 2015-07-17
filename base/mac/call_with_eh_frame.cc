// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/call_with_eh_frame.h"

#include <unwind.h>

#include "build/build_config.h"

namespace base {
namespace mac {

_Unwind_Reason_Code CxxPersonalityRoutine(
    int version,
    _Unwind_Action actions,
    uint64_t exceptionClass,
    struct _Unwind_Exception* exceptionObject,
    struct _Unwind_Context* context) {
  // Tell libunwind that this is the end of the stack. When it encounters the
  // CallWithEHFrame, it will stop searching for an exception handler. The
  // result is that no exception handler has been found higher on the stack,
  // and any that are lower on the stack (e.g. in CFRunLoopRunSpecific), will
  // now be skipped. Since this is reporting the end of the stack, and no
  // exception handler will have been found, std::terminate() will be called.
  return _URC_END_OF_STACK;
}

#if defined(OS_IOS)
// No iOS assembly implementation exists, so just call the block directly.
void CallWithEHFrame(void (^block)(void)) {
  block();
}
#endif

}  // namespace mac
}  // namespace base
