// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the factory functions declared in
// //mojo/edk/platform/test_message_loops.h (using
// |mojo::platform::MessageLoop|s based on //base, i.e., using
// |base_edk::PlatformMessageLoopImpl|).

#include "mojo/edk/platform/test_message_loops.h"

#include "mojo/edk/base_edk/platform_message_loop_for_io_impl.h"
#include "mojo/edk/base_edk/platform_message_loop_impl.h"
#include "mojo/edk/util/make_unique.h"

using mojo::util::MakeUnique;

namespace mojo {
namespace platform {
namespace test {

std::unique_ptr<MessageLoop> CreateTestMessageLoop() {
  return MakeUnique<base_edk::PlatformMessageLoopImpl>();
}

std::unique_ptr<MessageLoopForIO> CreateTestMessageLoopForIO() {
  return MakeUnique<base_edk::PlatformMessageLoopForIOImpl>();
}

}  // namespace test
}  // namespace platform
}  // namespace mojo
