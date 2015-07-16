// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sequence_checker_impl.h"

namespace base {

SequenceCheckerImpl::SequenceCheckerImpl()
    : sequence_token_assigned_(false) {
  AutoLock auto_lock(lock_);
  EnsureSequenceTokenAssigned();
}

SequenceCheckerImpl::~SequenceCheckerImpl() {}

bool SequenceCheckerImpl::CalledOnValidSequencedThread() const {
  AutoLock auto_lock(lock_);
  EnsureSequenceTokenAssigned();

  // If this thread is not associated with a SequencedWorkerPool,
  // SequenceChecker behaves as a ThreadChecker. See header for details.
  if (!sequence_token_.IsValid())
    return thread_checker_.CalledOnValidThread();

  return sequence_token_.Equals(
      SequencedWorkerPool::GetSequenceTokenForCurrentThread());
}

void SequenceCheckerImpl::DetachFromSequence() {
  AutoLock auto_lock(lock_);
  thread_checker_.DetachFromThread();
  sequence_token_assigned_ = false;
  sequence_token_ = SequencedWorkerPool::SequenceToken();
}

void SequenceCheckerImpl::EnsureSequenceTokenAssigned() const {
  lock_.AssertAcquired();
  if (sequence_token_assigned_)
    return;

  sequence_token_assigned_ = true;
  sequence_token_ = SequencedWorkerPool::GetSequenceTokenForCurrentThread();
}

}  // namespace base
