// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_LINUX_MESSAGE_LOOP_LINUX_H_
#define FLUTTER_FML_PLATFORM_LINUX_MESSAGE_LOOP_LINUX_H_

#include <atomic>

#include "flutter/fml/message_loop_impl.h"
#include "lib/ftl/files/unique_fd.h"
#include "lib/ftl/macros.h"

namespace fml {

class MessageLoopLinux : public MessageLoopImpl {
 private:
  ftl::UniqueFD epoll_fd_;
  ftl::UniqueFD timer_fd_;
  bool running_;

  MessageLoopLinux();

  ~MessageLoopLinux() override;

  void Run() override;

  void Terminate() override;

  void WakeUp(ftl::TimePoint time_point) override;

  void OnEventFired();

  bool AddOrRemoveTimerSource(bool add);

  FRIEND_MAKE_REF_COUNTED(MessageLoopLinux);
  FRIEND_REF_COUNTED_THREAD_SAFE(MessageLoopLinux);
  FTL_DISALLOW_COPY_AND_ASSIGN(MessageLoopLinux);
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_LINUX_MESSAGE_LOOP_LINUX_H_
