// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_MESSAGE_LOOP_HELPER_H_
#define MOJO_EDK_PLATFORM_MESSAGE_LOOP_HELPER_H_

namespace mojo {
namespace platform {

class MessageLoop;

namespace test {

// This does a basic, generic test of the given message loop.
void MessageLoopTestHelper(MessageLoop* message_loop);

}  // namespace test
}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_MESSAGE_LOOP_HELPER_H_
