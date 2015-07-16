// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_SEQUENCED_WORKER_POOL_OWNER_H_
#define BASE_TEST_SEQUENCED_WORKER_POOL_OWNER_H_

#include <cstddef>
#include <string>

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/compiler_specific.h"
#include "base/memory/ref_counted.h"
#include "base/synchronization/lock.h"
#include "base/threading/sequenced_worker_pool.h"

namespace base {

class MessageLoop;

// Wrapper around SequencedWorkerPool for testing that blocks destruction
// until the pool is actually destroyed.  This is so that a
// SequencedWorkerPool from one test doesn't outlive its test and cause
// strange races with other tests that touch global stuff (like histograms and
// logging).  However, this requires that nothing else on this thread holds a
// ref to the pool when the SequencedWorkerPoolOwner is destroyed.
class SequencedWorkerPoolOwner : public SequencedWorkerPool::TestingObserver {
 public:
  SequencedWorkerPoolOwner(size_t max_threads,
                           const std::string& thread_name_prefix);

  ~SequencedWorkerPoolOwner() override;

  // Don't change the returned pool's testing observer.
  const scoped_refptr<SequencedWorkerPool>& pool();

  // The given callback will be called on WillWaitForShutdown().
  void SetWillWaitForShutdownCallback(const Closure& callback);

  int has_work_call_count() const;

 private:
  // SequencedWorkerPool::TestingObserver implementation.
  void OnHasWork() override;
  void WillWaitForShutdown() override;
  void OnDestruct() override;

  MessageLoop* const constructor_message_loop_;
  scoped_refptr<SequencedWorkerPool> pool_;
  Closure will_wait_for_shutdown_callback_;

  mutable Lock has_work_lock_;
  int has_work_call_count_;

  DISALLOW_COPY_AND_ASSIGN(SequencedWorkerPoolOwner);
};

}  // namespace base

#endif  // BASE_TEST_SEQUENCED_WORKER_POOL_OWNER_H_
