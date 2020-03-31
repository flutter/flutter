// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <atomic>
#include <thread>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "gtest/gtest.h"

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
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    pre_merge.CountDown();
  });

  loop2->GetTaskRunner()->PostTask([&]() {
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid2);
    pre_merge.CountDown();
  });

  pre_merge.Wait();

  raster_thread_merger_->MergeWithLease(1);

  loop1->GetTaskRunner()->PostTask([&]() {
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    post_merge.CountDown();
  });

  loop2->GetTaskRunner()->PostTask([&]() {
    // this will be false since this is going to be run
    // on loop1 really.
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    post_merge.CountDown();
  });

  post_merge.Wait();

  raster_thread_merger_->DecrementLease();

  loop1->GetTaskRunner()->PostTask([&]() {
    ASSERT_FALSE(raster_thread_merger_->IsOnRasterizingThread());
    ASSERT_EQ(fml::MessageLoop::GetCurrentTaskQueueId(), qid1);
    post_unmerge.CountDown();
  });

  loop2->GetTaskRunner()->PostTask([&]() {
    ASSERT_TRUE(raster_thread_merger_->IsOnRasterizingThread());
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
