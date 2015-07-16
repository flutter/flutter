// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_TEST_EMBEDDER_H_
#define MOJO_EDK_EMBEDDER_TEST_EMBEDDER_H_

#include "mojo/edk/system/system_impl_export.h"

namespace mojo {
namespace embedder {
namespace test {

// Calls |Init()| with a |SimplePlatformSupport| (use this in tests if, e.g.,
// you don't care about sandboxing, etc.).
MOJO_SYSTEM_IMPL_EXPORT void InitWithSimplePlatformSupport();

// This shuts down the global, singleton instance. (Note: "Real" embedders are
// not expected to ever shut down this instance. This |Shutdown()| function will
// do more work to ensure that tests don't leak, etc.) Returns true if there
// were no problems, false if there were leaks -- i.e., handles still open -- or
// any other problems.
//
// Note: It is up to the caller to ensure that there are not outstanding
// callbacks from |CreateChannel()| before calling this.
MOJO_SYSTEM_IMPL_EXPORT bool Shutdown();

}  // namespace test
}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_TEST_EMBEDDER_H_
