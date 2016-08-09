// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/forwarder2/pipe_notifier.h"

#include <fcntl.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>

#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"

namespace forwarder2 {

PipeNotifier::PipeNotifier() {
  int pipe_fd[2];
  int ret = pipe(pipe_fd);
  CHECK_EQ(0, ret);
  receiver_fd_ = pipe_fd[0];
  sender_fd_ = pipe_fd[1];
  fcntl(sender_fd_, F_SETFL, O_NONBLOCK);
}

PipeNotifier::~PipeNotifier() {
  close(receiver_fd_);
  close(sender_fd_);
}

bool PipeNotifier::Notify() {
  CHECK_NE(-1, sender_fd_);
  errno = 0;
  int ret = HANDLE_EINTR(write(sender_fd_, "1", 1));
  if (ret < 0) {
    PLOG(ERROR) << "write";
    return false;
  }
  return true;
}

void PipeNotifier::Reset() {
  char c;
  int ret = HANDLE_EINTR(read(receiver_fd_, &c, 1));
  if (ret < 0) {
    PLOG(ERROR) << "read";
    return;
  }
  DCHECK_EQ(1, ret);
  DCHECK_EQ('1', c);
}

}  // namespace forwarder
