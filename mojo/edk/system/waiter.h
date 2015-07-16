// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_WAITER_H_
#define MOJO_EDK_SYSTEM_WAITER_H_

#include <stdint.h>

#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "mojo/edk/system/awakable.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// IMPORTANT (all-caps gets your attention, right?): |Waiter| methods are called
// under other locks, in particular, |Dispatcher::lock_|s, so |Waiter| methods
// must never call out to other objects (in particular, |Dispatcher|s). This
// class is thread-safe.
class MOJO_SYSTEM_IMPL_EXPORT Waiter final : public Awakable {
 public:
  Waiter();
  ~Waiter();

  // A |Waiter| can be used multiple times; |Init()| should be called before
  // each time it's used.
  void Init();

  // Waits until a suitable |Awake()| is called. (|context| may be null, in
  // which case, obviously no context is ever returned.)
  // Returns:
  //   - The result given to the first call to |Awake()| (possibly before this
  //     call to |Wait()|); in this case, |*context| is set to the value passed
  //     to that call to |Awake()|.
  //   - |MOJO_RESULT_DEADLINE_EXCEEDED| if the deadline was exceeded; in this
  //     case |*context| is not modified.
  //
  // Usually, the context passed to |Awake()| will be the value passed to
  // |Dispatcher::AddAwakable()|, which is usually the index to the array of
  // handles passed to |MojoWaitMany()| (or 0 for |MojoWait()|).
  //
  // Typical |Awake()| results are:
  //   - |MOJO_RESULT_OK| if one of the flags passed to
  //     |MojoWait()|/|MojoWaitMany()| (hence |Dispatcher::AddAwakable()|) was
  //     satisfied;
  //   - |MOJO_RESULT_CANCELLED| if a handle (on which
  //     |MojoWait()|/|MojoWaitMany()| was called) was closed (hence the
  //     dispatcher closed); and
  //   - |MOJO_RESULT_FAILED_PRECONDITION| if one of the set of flags passed to
  //     |MojoWait()|/|MojoWaitMany()| cannot or can no longer be satisfied by
  //     the corresponding handle (e.g., if the other end of a message or data
  //     pipe is closed).
  MojoResult Wait(MojoDeadline deadline, uint32_t* context);

  // Wake the waiter up with the given result and context (or no-op if it's been
  // woken up already).
  bool Awake(MojoResult result, uintptr_t context) override;

 private:
  base::ConditionVariable cv_;  // Associated to |lock_|.
  base::Lock lock_;             // Protects the following members.
#ifndef NDEBUG
  bool initialized_;
#endif
  bool awoken_;
  MojoResult awake_result_;
  uintptr_t awake_context_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Waiter);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_WAITER_H_
