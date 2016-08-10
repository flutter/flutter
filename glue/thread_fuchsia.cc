// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/glue/thread.h"

#include <utility>

#include "lib/mtl/threading/create_thread.h"

namespace glue {

class Thread::ThreadImpl {
 public:
  std::thread thread_;
};

Thread::Thread(std::string name) : impl_(new ThreadImpl()) {}

Thread::~Thread() {}

bool Thread::Start() {
  impl_->thread_ = mtl::CreateThread(&task_runner_);
  return true;
}

}  // namespace glue
