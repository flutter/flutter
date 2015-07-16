// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_THREADING_THREAD_CHECKER_H_
#define BASE_THREADING_THREAD_CHECKER_H_

// Apart from debug builds, we also enable the thread checker in
// builds with DCHECK_ALWAYS_ON so that trybots and waterfall bots
// with this define will get the same level of thread checking as
// debug bots.
//
// Note that this does not perfectly match situations where DCHECK is
// enabled.  For example a non-official release build may have
// DCHECK_ALWAYS_ON undefined (and therefore ThreadChecker would be
// disabled) but have DCHECKs enabled at runtime.
#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON))
#define ENABLE_THREAD_CHECKER 1
#else
#define ENABLE_THREAD_CHECKER 0
#endif

#include "base/threading/thread_checker_impl.h"

namespace base {

// Do nothing implementation, for use in release mode.
//
// Note: You should almost always use the ThreadChecker class to get the
// right version for your build configuration.
class ThreadCheckerDoNothing {
 public:
  bool CalledOnValidThread() const WARN_UNUSED_RESULT {
    return true;
  }

  void DetachFromThread() {}
};

// ThreadChecker is a helper class used to help verify that some methods of a
// class are called from the same thread. It provides identical functionality to
// base::NonThreadSafe, but it is meant to be held as a member variable, rather
// than inherited from base::NonThreadSafe.
//
// While inheriting from base::NonThreadSafe may give a clear indication about
// the thread-safety of a class, it may also lead to violations of the style
// guide with regard to multiple inheritance. The choice between having a
// ThreadChecker member and inheriting from base::NonThreadSafe should be based
// on whether:
//  - Derived classes need to know the thread they belong to, as opposed to
//    having that functionality fully encapsulated in the base class.
//  - Derived classes should be able to reassign the base class to another
//    thread, via DetachFromThread.
//
// If neither of these are true, then having a ThreadChecker member and calling
// CalledOnValidThread is the preferable solution.
//
// Example:
// class MyClass {
//  public:
//   void Foo() {
//     DCHECK(thread_checker_.CalledOnValidThread());
//     ... (do stuff) ...
//   }
//
//  private:
//   ThreadChecker thread_checker_;
// }
//
// In Release mode, CalledOnValidThread will always return true.
#if ENABLE_THREAD_CHECKER
class ThreadChecker : public ThreadCheckerImpl {
};
#else
class ThreadChecker : public ThreadCheckerDoNothing {
};
#endif  // ENABLE_THREAD_CHECKER

#undef ENABLE_THREAD_CHECKER

}  // namespace base

#endif  // BASE_THREADING_THREAD_CHECKER_H_
