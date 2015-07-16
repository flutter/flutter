// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SEQUENCE_CHECKER_IMPL_H_
#define BASE_SEQUENCE_CHECKER_IMPL_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/synchronization/lock.h"
#include "base/threading/sequenced_worker_pool.h"
#include "base/threading/thread_checker_impl.h"

namespace base {

// SequenceCheckerImpl is used to help verify that some methods of a
// class are called in sequence -- that is, called from the same
// SequencedTaskRunner. It is a generalization of ThreadChecker; in
// particular, it behaves exactly like ThreadChecker if constructed
// on a thread that is not part of a SequencedWorkerPool.
class BASE_EXPORT SequenceCheckerImpl {
 public:
  SequenceCheckerImpl();
  ~SequenceCheckerImpl();

  // Returns whether the we are being called on the same sequence token
  // as previous calls. If there is no associated sequence, then returns
  // whether we are being called on the underlying ThreadChecker's thread.
  bool CalledOnValidSequencedThread() const;

  // Unbinds the checker from the currently associated sequence. The
  // checker will be re-bound on the next call to CalledOnValidSequence().
  void DetachFromSequence();

 private:
  void EnsureSequenceTokenAssigned() const;

  // Guards all variables below.
  mutable Lock lock_;

  // Used if |sequence_token_| is not valid.
  ThreadCheckerImpl thread_checker_;
  mutable bool sequence_token_assigned_;

  mutable SequencedWorkerPool::SequenceToken sequence_token_;

  DISALLOW_COPY_AND_ASSIGN(SequenceCheckerImpl);
};

}  // namespace base

#endif  // BASE_SEQUENCE_CHECKER_IMPL_H_
