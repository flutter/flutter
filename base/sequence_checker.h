// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SEQUENCE_CHECKER_H_
#define BASE_SEQUENCE_CHECKER_H_

// See comments for the similar block in thread_checker.h.
#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON))
#define ENABLE_SEQUENCE_CHECKER 1
#else
#define ENABLE_SEQUENCE_CHECKER 0
#endif

#include "base/sequence_checker_impl.h"

namespace base {

// Do nothing implementation, for use in release mode.
//
// Note: You should almost always use the SequenceChecker class to get
// the right version for your build configuration.
class SequenceCheckerDoNothing {
 public:
  bool CalledOnValidSequencedThread() const {
    return true;
  }

  void DetachFromSequence() {}
};

// SequenceChecker is a helper class used to help verify that some
// methods of a class are called in sequence -- that is, called from
// the same SequencedTaskRunner. It is a generalization of
// ThreadChecker; see comments in sequence_checker_impl.h for details.
//
// Example:
// class MyClass {
//  public:
//   void Foo() {
//     DCHECK(sequence_checker_.CalledOnValidSequencedThread());
//     ... (do stuff) ...
//   }
//
//  private:
//   SequenceChecker sequence_checker_;
// }
//
// In Release mode, CalledOnValidSequencedThread() will always return true.
#if ENABLE_SEQUENCE_CHECKER
class SequenceChecker : public SequenceCheckerImpl {
};
#else
class SequenceChecker : public SequenceCheckerDoNothing {
};
#endif  // ENABLE_SEQUENCE_CHECKER

#undef ENABLE_SEQUENCE_CHECKER

}  // namespace base

#endif  // BASE_SEQUENCE_CHECKER_H_
