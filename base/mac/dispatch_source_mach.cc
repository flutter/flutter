// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/dispatch_source_mach.h"

namespace base {

DispatchSourceMach::DispatchSourceMach(const char* name,
                                       mach_port_t port,
                                       void (^event_handler)())
    // TODO(rsesek): Specify DISPATCH_QUEUE_SERIAL, in the 10.7 SDK. NULL
    // means the same thing but is not symbolically clear.
    : DispatchSourceMach(dispatch_queue_create(name, NULL),
                         port,
                         event_handler) {
  // Since the queue was created above in the delegated constructor, and it was
  // subsequently retained, release it here.
  dispatch_release(queue_);
}

DispatchSourceMach::DispatchSourceMach(dispatch_queue_t queue,
                                       mach_port_t port,
                                       void (^event_handler)())
    : queue_(queue),
      source_(dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV,
          port, 0, queue_)),
      source_canceled_(dispatch_semaphore_create(0)) {
  dispatch_retain(queue);

  dispatch_source_set_event_handler(source_, event_handler);
  dispatch_source_set_cancel_handler(source_, ^{
      dispatch_semaphore_signal(source_canceled_);
  });
}

DispatchSourceMach::~DispatchSourceMach() {
  Cancel();
}

void DispatchSourceMach::Resume() {
  dispatch_resume(source_);
}

void DispatchSourceMach::Cancel() {
  if (source_) {
    dispatch_source_cancel(source_);
    dispatch_release(source_);
    source_ = NULL;

    dispatch_semaphore_wait(source_canceled_, DISPATCH_TIME_FOREVER);
    dispatch_release(source_canceled_);
    source_canceled_ = NULL;
  }

  if (queue_) {
    dispatch_release(queue_);
    queue_ = NULL;
  }
}

}  // namespace base
