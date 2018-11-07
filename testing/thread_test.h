// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_THREAD_TEST_H_
#define FLUTTER_TESTING_THREAD_TEST_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "gtest/gtest.h"

namespace testing {

class ThreadTest : public Test {
 public:
  fml::RefPtr<fml::TaskRunner> GetCurrentTaskRunner();

  fml::RefPtr<fml::TaskRunner> GetThreadTaskRunner();

 protected:
  void SetUp() override;

  void TearDown() override;

 private:
  std::unique_ptr<fml::Thread> thread_;
  fml::RefPtr<fml::TaskRunner> thread_task_runner_;
  fml::RefPtr<fml::TaskRunner> current_task_runner_;
};

}  // namespace testing

#endif  // FLUTTER_TESTING_THREAD_TEST_H_
