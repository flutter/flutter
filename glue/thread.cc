// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "glue/thread.h"

#include <utility>

#include "base/threading/thread.h"
#include "glue/task_runner_adaptor.h"

namespace glue {

class Thread::ThreadImpl : public base::Thread {
 public:
  ThreadImpl(std::string name) : base::Thread(std::move(name)) {}
};

Thread::Thread(std::string name) : impl_(new ThreadImpl(name)) {
  task_runner_ = ftl::MakeRefCounted<TaskRunnerAdaptor>(impl_->task_runner());
}

Thread::~Thread() {}

bool Thread::Start() {
  return impl_->Start();
}

}  // namespace glue
