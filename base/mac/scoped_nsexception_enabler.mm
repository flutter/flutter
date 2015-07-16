// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/mac/scoped_nsexception_enabler.h"

#import "base/lazy_instance.h"
#import "base/threading/thread_local.h"

// To make the |g_exceptionsAllowed| declaration readable.
using base::LazyInstance;
using base::ThreadLocalBoolean;

// When C++ exceptions are disabled, the C++ library defines |try| and
// |catch| so as to allow exception-expecting C++ code to build properly when
// language support for exceptions is not present.  These macros interfere
// with the use of |@try| and |@catch| in Objective-C files such as this one.
// Undefine these macros here, after everything has been #included, since
// there will be no C++ uses and only Objective-C uses from this point on.
#undef try
#undef catch

namespace {

// Whether to allow NSExceptions to be raised on the current thread.
LazyInstance<ThreadLocalBoolean>::Leaky
    g_exceptionsAllowed = LAZY_INSTANCE_INITIALIZER;

}  // namespace

namespace base {
namespace mac {

bool GetNSExceptionsAllowed() {
  return g_exceptionsAllowed.Get().Get();
}

void SetNSExceptionsAllowed(bool allowed) {
  return g_exceptionsAllowed.Get().Set(allowed);
}

id RunBlockIgnoringExceptions(BlockReturningId block) {
  id ret = nil;
  @try {
    base::mac::ScopedNSExceptionEnabler enable;
    ret = block();
  }
  @catch(id exception) {
  }
  return ret;
}

ScopedNSExceptionEnabler::ScopedNSExceptionEnabler() {
  was_enabled_ = GetNSExceptionsAllowed();
  SetNSExceptionsAllowed(true);
}

ScopedNSExceptionEnabler::~ScopedNSExceptionEnabler() {
  SetNSExceptionsAllowed(was_enabled_);
}

}  // namespace mac
}  // namespace base
