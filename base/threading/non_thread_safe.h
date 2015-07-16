// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_THREADING_NON_THREAD_SAFE_H_
#define BASE_THREADING_NON_THREAD_SAFE_H_

// Classes deriving from NonThreadSafe may need to suppress MSVC warning 4275:
// non dll-interface class 'Bar' used as base for dll-interface class 'Foo'.
// There is a specific macro to do it: NON_EXPORTED_BASE(), defined in
// compiler_specific.h
#include "base/compiler_specific.h"

// See comment at top of thread_checker.h
#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON))
#define ENABLE_NON_THREAD_SAFE 1
#else
#define ENABLE_NON_THREAD_SAFE 0
#endif

#include "base/threading/non_thread_safe_impl.h"

namespace base {

// Do nothing implementation of NonThreadSafe, for release mode.
//
// Note: You should almost always use the NonThreadSafe class to get
// the right version of the class for your build configuration.
class NonThreadSafeDoNothing {
 public:
  bool CalledOnValidThread() const {
    return true;
  }

 protected:
  ~NonThreadSafeDoNothing() {}
  void DetachFromThread() {}
};

// NonThreadSafe is a helper class used to help verify that methods of a
// class are called from the same thread.  One can inherit from this class
// and use CalledOnValidThread() to verify.
//
// This is intended to be used with classes that appear to be thread safe, but
// aren't.  For example, a service or a singleton like the preferences system.
//
// Example:
// class MyClass : public base::NonThreadSafe {
//  public:
//   void Foo() {
//     DCHECK(CalledOnValidThread());
//     ... (do stuff) ...
//   }
// }
//
// Note that base::ThreadChecker offers identical functionality to
// NonThreadSafe, but does not require inheritance. In general, it is preferable
// to have a base::ThreadChecker as a member, rather than inherit from
// NonThreadSafe. For more details about when to choose one over the other, see
// the documentation for base::ThreadChecker.
#if ENABLE_NON_THREAD_SAFE
typedef NonThreadSafeImpl NonThreadSafe;
#else
typedef NonThreadSafeDoNothing NonThreadSafe;
#endif  // ENABLE_NON_THREAD_SAFE

#undef ENABLE_NON_THREAD_SAFE

}  // namespace base

#endif  // BASE_THREADING_NON_THREAD_SAFE_H_
