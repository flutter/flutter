// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/thread.h"

#include <memory>
#include <string>

#include "flutter/fml/message_loop.h"
#include "lib/ftl/build_config.h"
#include "lib/ftl/synchronization/waitable_event.h"

#if OS_MACOSX
#include <pthread/pthread.h>
#elif OS_LINUX || OS_ANDROID
#include <pthread.h>
#else
#error Unsupported Platform
#endif

namespace fml {

Thread::Thread(const std::string& name) : joined_(false) {
  ftl::AutoResetWaitableEvent latch;
  ftl::RefPtr<ftl::TaskRunner> runner;
  thread_ = std::make_unique<std::thread>([&latch, &runner, name]() -> void {
    SetCurrentThreadName(name);
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = MessageLoop::GetCurrent();
    runner = loop.GetTaskRunner();
    latch.Signal();
    loop.Run();
  });
  latch.Wait();
  task_runner_ = runner;
}

Thread::~Thread() {
  Join();
}

ftl::RefPtr<ftl::TaskRunner> Thread::GetTaskRunner() const {
  return task_runner_;
}

void Thread::Join() {
  if (joined_) {
    return;
  }
  joined_ = true;
  task_runner_->PostTask([]() { MessageLoop::GetCurrent().Terminate(); });
  thread_->join();
}

void Thread::SetCurrentThreadName(const std::string& name) {
  if (name == "") {
    return;
  }
#if OS_MACOSX
  pthread_setname_np(name.c_str());
#elif OS_LINUX || OS_ANDROID
  pthread_setname_np(pthread_self(), name.c_str());
#else
#error Unsupported Platform
#endif
}

}  // namespace fml
