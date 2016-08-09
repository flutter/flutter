// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_PIPE_NOTIFIER_H_
#define TOOLS_ANDROID_FORWARDER2_PIPE_NOTIFIER_H_

#include "base/basictypes.h"

namespace forwarder2 {

// Helper class used to create a unix pipe that sends notifications to the
// |receiver_fd_| file descriptor when called |Notify()|.  This should be used
// by the main thread to notify other threads that it must exit.
// The |receiver_fd_| can be put into a fd_set and used in a select together
// with a socket waiting to accept or read.
class PipeNotifier {
 public:
  PipeNotifier();
  ~PipeNotifier();

  bool Notify();

  int receiver_fd() const { return receiver_fd_; }

  void Reset();

 private:
  int sender_fd_;
  int receiver_fd_;

  DISALLOW_COPY_AND_ASSIGN(PipeNotifier);
};

}  // namespace forwarder

#endif  // TOOLS_ANDROID_FORWARDER2_PIPE_NOTIFIER_H_
