// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/testing/thread_test.h"

namespace flutter {
namespace testing {

// |testing::Test|
void ThreadTest::SetUp() {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  current_task_runner_ = fml::MessageLoop::GetCurrent().GetTaskRunner();
}

// |testing::Test|
void ThreadTest::TearDown() {
  current_task_runner_ = nullptr;
  extra_threads_.clear();
}

fml::RefPtr<fml::TaskRunner> ThreadTest::GetCurrentTaskRunner() {
  return current_task_runner_;
}

fml::RefPtr<fml::TaskRunner> ThreadTest::CreateNewThread(std::string name) {
  auto thread = std::make_unique<fml::Thread>(name);
  auto runner = thread->GetTaskRunner();
  extra_threads_.emplace_back(std::move(thread));
  return runner;
}

}  // namespace testing
}  // namespace flutter
