// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/raster_thread_merger.h"

#include <atomic>
#include <thread>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "gtest/gtest.h"

namespace fml {
namespace testing {

TEST(RasterThreadMerger, RemainMergedTillLeaseExpires) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });

  latch1.Wait();
  latch2.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);
  const int kNumFramesMerged = 5;

  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->MergeWithLease(kNumFramesMerged);

  for (int i = 0; i < kNumFramesMerged; i++) {
    ASSERT_TRUE(raster_thread_merger_->IsMerged());
    raster_thread_merger_->DecrementLease();
  }

  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

TEST(RasterThreadMerger, IsNotOnRasterizingThread) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  std::thread thread1([&loop1, &latch1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    loop1->GetTaskRunner()->PostTask([&]() { latch1.Signal(); });
    loop1->Run();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  std::thread thread2([&loop2, &latch2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    loop2->GetTaskRunner()->PostTask([&]() { latch2.Signal(); });
    loop2->Run();
  });

  latch1.Wait();
  latch2.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);

  fml::CountDownLatch pre_merge(2), post_merge(2), post_unmerge(2);

  loop1->GetTaskRunner()->PostTask([&]() {
    ASSERT_FALSE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_TRUE(raster_thread_merger_->IsOnPlatformThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    pre_merge.CountDown();
  });

  loop2->GetTaskRunner()->PostTask([&]() {
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_FALSE(raster_thread_merger_->IsOnPlatformThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid2);
    pre_merge.CountDown();
  });

  pre_merge.Wait();

  raster_thread_merger_->MergeWithLease(1);

  loop1->GetTaskRunner()->PostTask([&]() {
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_TRUE(raster_thread_merger_->IsOnPlatformThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    post_merge.CountDown();
  });

  loop2->GetTaskRunner()->PostTask([&]() {
    // this will be false since this is going to be run
    // on loop1 really.
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_TRUE(raster_thread_merger_->IsOnPlatformThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    post_merge.CountDown();
  });

  post_merge.Wait();

  raster_thread_merger_->DecrementLease();

  loop1->GetTaskRunner()->PostTask([&]() {
    ASSERT_FALSE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_TRUE(raster_thread_merger_->IsOnPlatformThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    post_unmerge.CountDown();
  });

  loop2->GetTaskRunner()->PostTask([&]() {
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_FALSE(raster_thread_merger_->IsOnPlatformThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid2);
    post_unmerge.CountDown();
  });

  post_unmerge.Wait();

  loop1->GetTaskRunner()->PostTask([&]() { loop1->Terminate(); });

  loop2->GetTaskRunner()->PostTask([&]() { loop2->Terminate(); });

  thread1.join();
  thread2.join();
}

TEST(RasterThreadMerger, LeaseExtension) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });

  latch1.Wait();
  latch2.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);
  const int kNumFramesMerged = 5;

  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->MergeWithLease(kNumFramesMerged);

  // let there be one more turn till the leases expire.
  for (int i = 0; i < kNumFramesMerged - 1; i++) {
    ASSERT_TRUE(raster_thread_merger_->IsMerged());
    raster_thread_merger_->DecrementLease();
  }

  // extend the lease once.
  raster_thread_merger_->ExtendLeaseTo(kNumFramesMerged);

  // we will NOT last for 1 extra turn, we just set it.
  for (int i = 0; i < kNumFramesMerged; i++) {
    ASSERT_TRUE(raster_thread_merger_->IsMerged());
    raster_thread_merger_->DecrementLease();
  }

  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

TEST(RasterThreadMerger, WaitUntilMerged) {
  fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger;

  fml::AutoResetWaitableEvent create_thread_merger_latch;
  fml::MessageLoop* loop_platform = nullptr;
  fml::AutoResetWaitableEvent latch_platform;
  fml::AutoResetWaitableEvent term_platform;
  fml::AutoResetWaitableEvent latch_merged;
  std::thread thread_platform([&]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop_platform = &fml::MessageLoop::GetCurrent();
    latch_platform.Signal();
    create_thread_merger_latch.Wait();
    raster_thread_merger->WaitUntilMerged();
    latch_merged.Signal();
    term_platform.Wait();
  });

  const int kNumFramesMerged = 5;
  fml::MessageLoop* loop_raster = nullptr;
  fml::AutoResetWaitableEvent term_raster;
  std::thread thread_raster([&]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop_raster = &fml::MessageLoop::GetCurrent();
    latch_platform.Wait();
    fml::TaskQueueId qid_platform =
        loop_platform->GetTaskRunner()->GetTaskQueueId();
    fml::TaskQueueId qid_raster =
        loop_raster->GetTaskRunner()->GetTaskQueueId();
    raster_thread_merger =
        fml::MakeRefCounted<fml::RasterThreadMerger>(qid_platform, qid_raster);
    ASSERT_FALSE(raster_thread_merger->IsMerged());
    create_thread_merger_latch.Signal();
    raster_thread_merger->MergeWithLease(kNumFramesMerged);
    term_raster.Wait();
  });

  latch_merged.Wait();
  ASSERT_TRUE(raster_thread_merger->IsMerged());

  for (int i = 0; i < kNumFramesMerged; i++) {
    ASSERT_TRUE(raster_thread_merger->IsMerged());
    raster_thread_merger->DecrementLease();
  }

  ASSERT_FALSE(raster_thread_merger->IsMerged());

  term_platform.Signal();
  term_raster.Signal();
  thread_platform.join();
  thread_raster.join();
}

TEST(RasterThreadMerger, HandleTaskQueuesAreTheSame) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  latch1.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = qid1;
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);
  // Statically merged.
  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  // Test decrement lease and unmerge are both no-ops.
  // The task queues should be always merged.
  const int kNumFramesMerged = 5;
  raster_thread_merger_->MergeWithLease(kNumFramesMerged);

  for (int i = 0; i < kNumFramesMerged; i++) {
    ASSERT_TRUE(raster_thread_merger_->IsMerged());
    raster_thread_merger_->DecrementLease();
  }

  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  // Wait until merged should also return immediately.
  raster_thread_merger_->WaitUntilMerged();
  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  term1.Signal();
  thread1.join();
}

TEST(RasterThreadMerger, Enable) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });

  latch1.Wait();
  latch2.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);

  raster_thread_merger_->Disable();
  raster_thread_merger_->MergeWithLease(1);
  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->Enable();
  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->MergeWithLease(1);
  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->DecrementLease();
  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

TEST(RasterThreadMerger, Disable) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });

  latch1.Wait();
  latch2.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);

  raster_thread_merger_->Disable();
  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->MergeWithLease(1);
  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->Enable();
  raster_thread_merger_->MergeWithLease(1);
  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->Disable();
  raster_thread_merger_->UnMergeNow();
  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  {
    auto decrement_result = raster_thread_merger_->DecrementLease();
    ASSERT_EQ(fml::RasterThreadStatus::kRemainsMerged, decrement_result);
  }

  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->Enable();
  raster_thread_merger_->UnMergeNow();
  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  raster_thread_merger_->MergeWithLease(1);

  ASSERT_TRUE(raster_thread_merger_->IsMerged());

  {
    auto decrement_result = raster_thread_merger_->DecrementLease();
    ASSERT_EQ(fml::RasterThreadStatus::kUnmergedNow, decrement_result);
  }

  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

TEST(RasterThreadMerger, IsEnabled) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });

  latch1.Wait();
  latch2.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);
  ASSERT_TRUE(raster_thread_merger_->IsEnabled());

  raster_thread_merger_->Disable();
  ASSERT_FALSE(raster_thread_merger_->IsEnabled());

  raster_thread_merger_->Enable();
  ASSERT_TRUE(raster_thread_merger_->IsEnabled());

  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

TEST(RasterThreadMerger, RunExpiredTasksWhileFirstTaskMergesThreads) {
  fml::MessageLoop* loop_platform = nullptr;
  fml::AutoResetWaitableEvent latch1;
  std::thread thread_platform([&loop_platform, &latch1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop_platform = &fml::MessageLoop::GetCurrent();
    loop_platform->GetTaskRunner()->PostTask([&]() { latch1.Signal(); });
    loop_platform->Run();
  });

  fml::MessageLoop* loop_raster = nullptr;
  fml::AutoResetWaitableEvent latch2;
  std::thread thread_raster([&loop_raster, &loop_platform, &latch1, &latch2]() {
    latch1.Wait();

    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop_raster = &fml::MessageLoop::GetCurrent();
    fml::TaskQueueId qid_platform =
        loop_platform->GetTaskRunner()->GetTaskQueueId();
    fml::TaskQueueId qid_raster =
        loop_raster->GetTaskRunner()->GetTaskQueueId();
    fml::CountDownLatch post_merge(2);
    const auto raster_thread_merger_ =
        fml::MakeRefCounted<fml::RasterThreadMerger>(qid_platform, qid_raster);
    loop_raster->GetTaskRunner()->PostTask([&]() {
      ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
      ASSERT_FALSE(raster_thread_merger_->IsOnPlatformThread());
      ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid_raster);
      raster_thread_merger_->MergeWithLease(1);
      post_merge.CountDown();
    });

    loop_raster->GetTaskRunner()->PostTask([&]() {
      ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
      ASSERT_TRUE(raster_thread_merger_->IsOnPlatformThread());
      ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid_platform);
      raster_thread_merger_->DecrementLease();
      post_merge.CountDown();
    });

    loop_raster->RunExpiredTasksNow();
    post_merge.Wait();
    latch2.Signal();
  });

  latch2.Wait();
  loop_platform->GetTaskRunner()->PostTask(
      [&]() { loop_platform->Terminate(); });

  thread_platform.join();
  thread_raster.join();
}

TEST(RasterThreadMerger, RunExpiredTasksWhileFirstTaskUnMergesThreads) {
  fml::MessageLoop* loop_platform = nullptr;
  fml::AutoResetWaitableEvent latch1;
  std::thread thread_platform([&loop_platform, &latch1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop_platform = &fml::MessageLoop::GetCurrent();
    loop_platform->GetTaskRunner()->PostTask([&]() { latch1.Signal(); });
    loop_platform->Run();
  });

  fml::MessageLoop* loop_raster = nullptr;
  fml::AutoResetWaitableEvent latch2;
  std::thread thread_raster([&loop_raster, &loop_platform, &latch1, &latch2]() {
    latch1.Wait();

    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop_raster = &fml::MessageLoop::GetCurrent();
    fml::TaskQueueId qid_platform =
        loop_platform->GetTaskRunner()->GetTaskQueueId();
    fml::TaskQueueId qid_raster =
        loop_raster->GetTaskRunner()->GetTaskQueueId();
    fml::CountDownLatch post_merge(2);

    const auto raster_thread_merger_ =
        fml::MakeRefCounted<fml::RasterThreadMerger>(qid_platform, qid_raster);
    loop_raster->GetTaskRunner()->PostTask([&]() {
      raster_thread_merger_->MergeWithLease(1);
      post_merge.CountDown();
    });

    loop_raster->RunExpiredTasksNow();

    loop_raster->GetTaskRunner()->PostTask([&]() {
      ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
      ASSERT_TRUE(raster_thread_merger_->IsOnPlatformThread());
      ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid_platform);
      raster_thread_merger_->DecrementLease();
      post_merge.CountDown();
    });

    loop_raster->GetTaskRunner()->PostTask([&]() {
      ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
      ASSERT_FALSE(raster_thread_merger_->IsOnPlatformThread());
      ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid_platform);
      post_merge.CountDown();
    });

    loop_raster->RunExpiredTasksNow();
    post_merge.Wait();
    latch2.Signal();
  });

  latch2.Wait();
  loop_platform->GetTaskRunner()->PostTask(
      [&]() { loop_platform->Terminate(); });

  thread_platform.join();
  thread_raster.join();
}

TEST(RasterThreadMerger, SetMergeUnmergeCallback) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });

  latch1.Wait();
  latch2.Wait();

  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();

  const auto raster_thread_merger =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);

  int callbacks = 0;
  raster_thread_merger->SetMergeUnmergeCallback(
      [&callbacks]() { callbacks++; });

  ASSERT_EQ(0, callbacks);

  raster_thread_merger->MergeWithLease(1);
  ASSERT_EQ(1, callbacks);

  raster_thread_merger->DecrementLease();
  ASSERT_EQ(2, callbacks);

  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

}  // namespace testing
}  // namespace fml
