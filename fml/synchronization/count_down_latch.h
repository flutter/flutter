// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <atomic>

#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/waitable_event.h"

namespace fml {

class CountDownLatch {
 public:
  CountDownLatch(size_t count);

  ~CountDownLatch();

  void Wait();

  void CountDown();

 private:
  std::atomic_size_t count_;
  ManualResetWaitableEvent waitable_event_;

  FML_DISALLOW_COPY_AND_ASSIGN(CountDownLatch);
};

}  // namespace fml
