// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_WAITER_H_
#define MOJO_EDK_SYSTEM_WAITER_H_

#include <stdint.h>

#include "mojo/edk/system/awakable.h"
#include "mojo/edk/util/cond_var.h"
#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/c/system/result.h"
#include "mojo/public/c/system/time.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// An implementation of |Awakable| that is used for blocking waits. This should
// be used in a non-persistent way (i.e., |Awake()| should be called at most
// once by each source, and only for "leading edges").
//
// IMPORTANT: |Waiter| methods are called under other locks, in particular,
// |Dispatcher::lock_|s, so |Waiter| methods must never call out to other
// objects (in particular, |Dispatcher|s).
//
// This class is thread-safe.
class Waiter final : public Awakable {
 public:
  Waiter();
  ~Waiter() override;

  // A |Waiter| can be used multiple times; |Init()| should be called before
  // each time it's used.
  void Init() MOJO_NOT_THREAD_SAFE;

  // Waits until a suitable |Awake()| is called. (|context| may be null, in
  // which case, obviously no context is ever returned.)
  // Returns:
  //   - |MOJO_RESULT_OK| if |Awake()| was called with |AwakeReason::SATISFIED|;
  //   - |MOJO_RESULT_CANCELLED| if |Awake()| was called with
  //     |AwakeReason::CANCELLED|;
  //   - |MOJO_RESULT_FAILED_PRECONDITION| if |Awake()| was called with
  //     |AwakeReason::UNSATISFIABLE|; or
  //   - |MOJO_RESULT_DEADLINE_EXCEEDED| if the deadline was exceeded.
  //
  // In all the cases except |MOJO_RESULT_DEADLINE_EXCEEDED|, the context and
  // signals state passed to |Awake()| be made available via |*context| and
  // |*signals_state|, respectively (unless the respective pointer is null).
  MojoResult Wait(MojoDeadline deadline,
                  uint64_t* context,
                  HandleSignalsState* signals_state);

  // |Awakable| implementation:
  void Awake(uint64_t context,
             AwakeReason reason,
             const HandleSignalsState& signals_state) override;

 private:
  util::CondVar cv_;  // Associated to |mutex_|.
  util::Mutex mutex_;
#ifndef NDEBUG
  bool initialized_ MOJO_GUARDED_BY(mutex_);
#endif
  bool awoken_ MOJO_GUARDED_BY(mutex_);
  AwakeReason awake_reason_ MOJO_GUARDED_BY(mutex_);
  HandleSignalsState signals_state_ MOJO_GUARDED_BY(mutex_);
  uint64_t awake_context_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(Waiter);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_WAITER_H_
