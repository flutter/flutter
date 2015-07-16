// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_DEBUG_LEAK_TRACKER_H_
#define BASE_DEBUG_LEAK_TRACKER_H_

#include "build/build_config.h"

// Only enable leak tracking in non-uClibc debug builds.
#if !defined(NDEBUG) && !defined(__UCLIBC__)
#define ENABLE_LEAK_TRACKER
#endif

#ifdef ENABLE_LEAK_TRACKER
#include "base/containers/linked_list.h"
#include "base/debug/stack_trace.h"
#include "base/logging.h"
#endif  // ENABLE_LEAK_TRACKER

// LeakTracker is a helper to verify that all instances of a class
// have been destroyed.
//
// It is particularly useful for classes that are bound to a single thread --
// before destroying that thread, one can check that there are no remaining
// instances of that class.
//
// For example, to enable leak tracking for class net::URLRequest, start by
// adding a member variable of type LeakTracker<net::URLRequest>.
//
//   class URLRequest {
//     ...
//    private:
//     base::LeakTracker<URLRequest> leak_tracker_;
//   };
//
//
// Next, when we believe all instances of net::URLRequest have been deleted:
//
//   LeakTracker<net::URLRequest>::CheckForLeaks();
//
// Should the check fail (because there are live instances of net::URLRequest),
// then the allocation callstack for each leaked instances is dumped to
// the error log.
//
// If ENABLE_LEAK_TRACKER is not defined, then the check has no effect.

namespace base {
namespace debug {

#ifndef ENABLE_LEAK_TRACKER

// If leak tracking is disabled, do nothing.
template<typename T>
class LeakTracker {
 public:
  ~LeakTracker() {}
  static void CheckForLeaks() {}
  static int NumLiveInstances() { return -1; }
};

#else

// If leak tracking is enabled we track where the object was allocated from.

template<typename T>
class LeakTracker : public LinkNode<LeakTracker<T> > {
 public:
  LeakTracker() {
    instances()->Append(this);
  }

  ~LeakTracker() {
    this->RemoveFromList();
  }

  static void CheckForLeaks() {
    // Walk the allocation list and print each entry it contains.
    size_t count = 0;

    // Copy the first 3 leak allocation callstacks onto the stack.
    // This way if we hit the CHECK() in a release build, the leak
    // information will be available in mini-dump.
    const size_t kMaxStackTracesToCopyOntoStack = 3;
    StackTrace stacktraces[kMaxStackTracesToCopyOntoStack];

    for (LinkNode<LeakTracker<T> >* node = instances()->head();
         node != instances()->end();
         node = node->next()) {
      StackTrace& allocation_stack = node->value()->allocation_stack_;

      if (count < kMaxStackTracesToCopyOntoStack)
        stacktraces[count] = allocation_stack;

      ++count;
      if (LOG_IS_ON(ERROR)) {
        LOG_STREAM(ERROR) << "Leaked " << node << " which was allocated by:";
        allocation_stack.OutputToStream(&LOG_STREAM(ERROR));
      }
    }

    CHECK_EQ(0u, count);

    // Hack to keep |stacktraces| and |count| alive (so compiler
    // doesn't optimize it out, and it will appear in mini-dumps).
    if (count == 0x1234) {
      for (size_t i = 0; i < kMaxStackTracesToCopyOntoStack; ++i)
        stacktraces[i].Print();
    }
  }

  static int NumLiveInstances() {
    // Walk the allocation list and count how many entries it has.
    int count = 0;
    for (LinkNode<LeakTracker<T> >* node = instances()->head();
         node != instances()->end();
         node = node->next()) {
      ++count;
    }
    return count;
  }

 private:
  // Each specialization of LeakTracker gets its own static storage.
  static LinkedList<LeakTracker<T> >* instances() {
    static LinkedList<LeakTracker<T> > list;
    return &list;
  }

  StackTrace allocation_stack_;
};

#endif  // ENABLE_LEAK_TRACKER

}  // namespace debug
}  // namespace base

#endif  // BASE_DEBUG_LEAK_TRACKER_H_
