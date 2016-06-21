// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/environment/scoped_chromium_init.h"

#include "base/command_line.h"
#include "base/debug/stack_trace.h"

namespace mojo {

ScopedChromiumInit::ScopedChromiumInit() {
  base::CommandLine::Init(0, nullptr);

#if !defined(NDEBUG) && !defined(OS_NACL)
  base::debug::EnableInProcessStackDumping();
#endif
}

ScopedChromiumInit::~ScopedChromiumInit() {}

}  // namespace mojo
