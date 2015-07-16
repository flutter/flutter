// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/forwarder2/forwarders_manager.h"

#include <sys/select.h>
#include <unistd.h>

#include <algorithm>

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/callback_helpers.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/message_loop/message_loop_proxy.h"
#include "base/posix/eintr_wrapper.h"
#include "tools/android/forwarder2/forwarder.h"
#include "tools/android/forwarder2/socket.h"

namespace forwarder2 {

ForwardersManager::ForwardersManager() : thread_("ForwardersManagerThread") {
  thread_.Start();
  WaitForEventsOnInternalThreadSoon();
}


ForwardersManager::~ForwardersManager() {
  deletion_notifier_.Notify();
}

void ForwardersManager::CreateAndStartNewForwarder(scoped_ptr<Socket> socket1,
                                                   scoped_ptr<Socket> socket2) {
  // Note that the internal Forwarder vector is populated on the internal thread
  // which is the only thread from which it's accessed.
  thread_.message_loop_proxy()->PostTask(
      FROM_HERE,
      base::Bind(&ForwardersManager::CreateNewForwarderOnInternalThread,
                 base::Unretained(this), base::Passed(&socket1),
                 base::Passed(&socket2)));

  // Guarantees that the CreateNewForwarderOnInternalThread callback posted to
  // the internal thread gets executed immediately.
  wakeup_notifier_.Notify();
}

void ForwardersManager::CreateNewForwarderOnInternalThread(
    scoped_ptr<Socket> socket1,
    scoped_ptr<Socket> socket2) {
  DCHECK(thread_.message_loop_proxy()->RunsTasksOnCurrentThread());
  forwarders_.push_back(new Forwarder(socket1.Pass(), socket2.Pass()));
}

void ForwardersManager::WaitForEventsOnInternalThreadSoon() {
  thread_.message_loop_proxy()->PostTask(
      FROM_HERE,
      base::Bind(&ForwardersManager::WaitForEventsOnInternalThread,
                 base::Unretained(this)));
}

void ForwardersManager::WaitForEventsOnInternalThread() {
  DCHECK(thread_.message_loop_proxy()->RunsTasksOnCurrentThread());
  fd_set read_fds;
  fd_set write_fds;

  FD_ZERO(&read_fds);
  FD_ZERO(&write_fds);

  // Populate the file descriptor sets.
  int max_fd = -1;
  for (ScopedVector<Forwarder>::iterator it = forwarders_.begin();
       it != forwarders_.end(); ++it) {
    Forwarder* const forwarder = *it;
    forwarder->RegisterFDs(&read_fds, &write_fds, &max_fd);
  }

  const int notifier_fds[] = {
    wakeup_notifier_.receiver_fd(),
    deletion_notifier_.receiver_fd(),
  };

  for (size_t i = 0; i < arraysize(notifier_fds); ++i) {
    const int notifier_fd = notifier_fds[i];
    DCHECK_GT(notifier_fd, -1);
    FD_SET(notifier_fd, &read_fds);
    max_fd = std::max(max_fd, notifier_fd);
  }

  const int ret = HANDLE_EINTR(
      select(max_fd + 1, &read_fds, &write_fds, NULL, NULL));
  if (ret < 0) {
    PLOG(ERROR) << "select";
    return;
  }

  const bool must_shutdown = FD_ISSET(
      deletion_notifier_.receiver_fd(), &read_fds);
  if (must_shutdown && forwarders_.empty())
    return;

  base::ScopedClosureRunner wait_for_events_soon(
      base::Bind(&ForwardersManager::WaitForEventsOnInternalThreadSoon,
                 base::Unretained(this)));

  if (FD_ISSET(wakeup_notifier_.receiver_fd(), &read_fds)) {
    // Note that the events on FDs other than the wakeup notifier one, if any,
    // will be processed upon the next select().
    wakeup_notifier_.Reset();
    return;
  }

  // Notify the Forwarder instances and remove the ones that are closed.
  for (size_t i = 0; i < forwarders_.size(); ) {
    Forwarder* const forwarder = forwarders_[i];
    forwarder->ProcessEvents(read_fds, write_fds);

    if (must_shutdown)
      forwarder->Shutdown();

    if (!forwarder->IsClosed()) {
      ++i;
      continue;
    }

    std::swap(forwarders_[i], forwarders_.back());
    forwarders_.pop_back();
  }
}

}  // namespace forwarder2
