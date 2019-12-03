// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/testing/thread_test.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkRefCnt.h"

namespace flutter {
namespace testing {

using SkiaGpuObjectTest = flutter::testing::ThreadTest;

class TestSkObject : public SkRefCnt {
 public:
  TestSkObject(std::shared_ptr<fml::AutoResetWaitableEvent> latch,
               fml::TaskQueueId* dtor_task_queue_id)
      : latch_(latch), dtor_task_queue_id_(dtor_task_queue_id) {}

  ~TestSkObject() {
    *dtor_task_queue_id_ = fml::MessageLoop::GetCurrentTaskQueueId();
    latch_->Signal();
  }

 private:
  std::shared_ptr<fml::AutoResetWaitableEvent> latch_;
  fml::TaskQueueId* dtor_task_queue_id_;
};

TEST_F(SkiaGpuObjectTest, UnrefQueue) {
  fml::RefPtr<fml::TaskRunner> task_runner = CreateNewThread();
  fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
      task_runner, fml::TimeDelta::FromSeconds(0));

  std::shared_ptr<fml::AutoResetWaitableEvent> latch =
      std::make_shared<fml::AutoResetWaitableEvent>();
  fml::TaskQueueId dtor_task_queue_id(0);
  SkRefCnt* ref_object = new TestSkObject(latch, &dtor_task_queue_id);

  queue->Unref(ref_object);
  latch->Wait();
  ASSERT_EQ(dtor_task_queue_id, task_runner->GetTaskQueueId());
}

}  // namespace testing
}  // namespace flutter
