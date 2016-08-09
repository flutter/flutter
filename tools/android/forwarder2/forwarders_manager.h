// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_FORWARDERS_MANAGER_H_
#define TOOLS_ANDROID_FORWARDER2_FORWARDERS_MANAGER_H_

#include "base/memory/scoped_ptr.h"
#include "base/memory/scoped_vector.h"
#include "base/threading/thread.h"
#include "tools/android/forwarder2/pipe_notifier.h"

namespace forwarder2 {

class Forwarder;
class Socket;

// Creates, owns and notifies Forwarder instances on its own internal thread.
class ForwardersManager {
 public:
  ForwardersManager();

  // Must be called on the thread the constructor was called on.
  ~ForwardersManager();

  // Can be called on any thread.
  void CreateAndStartNewForwarder(scoped_ptr<Socket> socket1,
                                  scoped_ptr<Socket> socket2);

 private:
  void CreateNewForwarderOnInternalThread(scoped_ptr<Socket> socket1,
                                          scoped_ptr<Socket> socket2);

  void WaitForEventsOnInternalThreadSoon();
  void WaitForEventsOnInternalThread();

  ScopedVector<Forwarder> forwarders_;
  PipeNotifier deletion_notifier_;
  PipeNotifier wakeup_notifier_;
  base::Thread thread_;
};

}  // namespace forwarder2

#endif  // TOOLS_ANDROID_FORWARDER2_FORWARDERS_MANAGER_H_
