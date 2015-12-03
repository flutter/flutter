// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an interface for "message loops for I/O", which are used
// within the EDK itself.

#ifndef MOJO_EDK_PLATFORM_MESSAGE_LOOP_FOR_IO_H_
#define MOJO_EDK_PLATFORM_MESSAGE_LOOP_FOR_IO_H_

#include "mojo/edk/platform/message_loop.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace platform {

// Interface for "message loops for I/O", which are |MessageLoop|s that can
// watch native handles (file descriptors).
// TODO(vtl): Currently, we don't add any methods. Obviously, we'll need to do
// so in the future. (Currently, things will just reach out in appropriately and
// get the |base::MessageLoopForIO|.)
class MessageLoopForIO : public MessageLoop {
 public:
  ~MessageLoopForIO() override {}

 protected:
  MessageLoopForIO() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(MessageLoopForIO);
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_MESSAGE_LOOP_FOR_IO_H_
