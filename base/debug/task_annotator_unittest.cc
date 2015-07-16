// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/debug/task_annotator.h"
#include "base/bind.h"
#include "base/pending_task.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace debug {
namespace {

void TestTask(int* result) {
  *result = 123;
}

}  // namespace

TEST(TaskAnnotatorTest, QueueAndRunTask) {
  int result = 0;
  PendingTask pending_task(FROM_HERE, Bind(&TestTask, &result));

  TaskAnnotator annotator;
  annotator.DidQueueTask("TaskAnnotatorTest::Queue", pending_task);
  EXPECT_EQ(0, result);
  annotator.RunTask(
      "TaskAnnotatorTest::Queue", "TaskAnnotatorTest::Run", pending_task);
  EXPECT_EQ(123, result);
}

}  // namespace debug
}  // namespace base
