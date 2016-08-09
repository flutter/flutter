// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_AWAKABLE_H_
#define MOJO_EDK_SYSTEM_AWAKABLE_H_

#include <stdint.h>

#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/public/c/system/result.h"

namespace mojo {
namespace system {

// An interface for things that may be awoken. E.g., |Waiter| is an
// implementation that blocks while waiting to be awoken.
class Awakable {
 public:
  // See |AwakableList| (in particular its |Add()| method) for information about
  // persistent versus one-shot awakables.
  enum class AwakeReason {
    // Sent to both persistent and one-shot awakables (after |Awake()| is
    // called with this, it will no longer be called by the same source):
    CANCELLED,
    // Sent to one-shot awakables:
    SATISFIED,
    UNSATISFIABLE,
    // Sent to persistent awakables:
    INITIALIZE,
    CHANGED,
  };

  // Helper function that translates:
  //   - |AwakeReason::CANCELLED| -> |MOJO_RESULT_CANCELLED|.
  //   - |AwakeReason::SATISFIED| -> |MOJO_RESULT_OK|,
  //   - |AwakeReason::UNSATISFIABLE| -> |MOJO_RESULT_FAILED_PRECONDITION|, and
  //   - |AwakeReason::INITIALIZE| -> |MOJO_RESULT_INTERNAL| (this function
  //     never be called with this reason).
  //   - |AwakeReason::CHANGED| -> |MOJO_RESULT_INTERNAL| (this function never
  //     be called with this reason).
  static MojoResult MojoResultForAwakeReason(AwakeReason reason);

  // |Awake()| must satisfy the following contract:
  //   - It must be thread-safe.
  //   - Since it is called with a mutex held, it must not call anything that
  //     takes "non-terminal" locks, i.e., those which are always safe to take.
  // If |reason| is |AwakeReason::CANCELLED|, |Awake()| will not be called
  // again (by the same source).
  virtual void Awake(uint64_t context,
                     AwakeReason reason,
                     const HandleSignalsState& signals_state) = 0;

 protected:
  Awakable() {}
  virtual ~Awakable() {}
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_AWAKABLE_H_
