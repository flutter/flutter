// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_LINUX_MESSAGE_LOOP_LINUX_H_
#define FLUTTER_FML_PLATFORM_LINUX_MESSAGE_LOOP_LINUX_H_

#include <atomic>

#include "flutter/fml/message_loop_impl.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/macros.h"

namespace fml {

class MessageLoopLinux : public MessageLoopImpl {
 private:
  fxl::UniqueFD epoll_fd_;
  fxl::UniqueFD timer_fd_;
  bool running_;

  MessageLoopLinux();

  ~MessageLoopLinux() override;

  void Run() override;

  void Terminate() override;

  void WakeUp(fxl::TimePoint time_point) override;

  void OnEventFired();

  bool AddOrRemoveTimerSource(bool add);

  FRIEND_MAKE_REF_COUNTED(MessageLoopLinux);
  FRIEND_REF_COUNTED_THREAD_SAFE(MessageLoopLinux);
  FXL_DISALLOW_COPY_AND_ASSIGN(MessageLoopLinux);
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_LINUX_MESSAGE_LOOP_LINUX_H_
