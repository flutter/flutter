// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/testing/thread_test.h"

namespace testing {

void ThreadTest::SetUp() {
  thread_ = std::make_unique<fml::Thread>();
  thread_task_runner_ = thread_->GetTaskRunner();

  fml::MessageLoop::EnsureInitializedForCurrentThread();
  current_task_runner_ = fml::MessageLoop::GetCurrent().GetTaskRunner();
}

void ThreadTest::TearDown() {
  thread_task_runner_ = nullptr;
  thread_ = nullptr;
  current_task_runner_ = nullptr;
}

fml::RefPtr<fml::TaskRunner> ThreadTest::GetCurrentTaskRunner() {
  return current_task_runner_;
}

fml::RefPtr<fml::TaskRunner> ThreadTest::GetThreadTaskRunner() {
  return thread_task_runner_;
}

}  // namespace testing
