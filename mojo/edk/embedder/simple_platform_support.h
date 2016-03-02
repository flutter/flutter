// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_SIMPLE_PLATFORM_SUPPORT_H_
#define MOJO_EDK_EMBEDDER_SIMPLE_PLATFORM_SUPPORT_H_

#include <memory>

#include "mojo/edk/embedder/platform_support.h"

namespace mojo {
namespace embedder {

// Creates a simple implementation of |PlatformSupport| that works when
// sandboxing and multiprocess support are not issues (e.g., in most tests).
// Note: Instances of |PlatformSupport| created by this function have no state,
// and different instances are mutually compatible (i.e., you don't need to use
// a single instance of it everywhere -- you may simply create one
// whenever/wherever you need it).
std::unique_ptr<PlatformSupport> CreateSimplePlatformSupport();

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_SIMPLE_PLATFORM_SUPPORT_H_
