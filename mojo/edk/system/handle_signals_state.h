// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_HANDLE_SIGNALS_STATE_H_
#define MOJO_EDK_SYSTEM_HANDLE_SIGNALS_STATE_H_

#include "mojo/public/c/system/types.h"

namespace mojo {
namespace system {

// Just "add" some constructors and methods to the C struct
// |MojoHandleSignalsState| (for convenience). This should add no overhead.
struct HandleSignalsState final : public MojoHandleSignalsState {
  HandleSignalsState() {
    satisfied_signals = MOJO_HANDLE_SIGNAL_NONE;
    satisfiable_signals = MOJO_HANDLE_SIGNAL_NONE;
  }
  HandleSignalsState(MojoHandleSignals satisfied,
                     MojoHandleSignals satisfiable) {
    satisfied_signals = satisfied;
    satisfiable_signals = satisfiable;
  }

  bool equals(const HandleSignalsState& other) const {
    return satisfied_signals == other.satisfied_signals &&
           satisfiable_signals == other.satisfiable_signals;
  }

  bool satisfies(MojoHandleSignals signals) const {
    return !!(satisfied_signals & signals);
  }

  bool can_satisfy(MojoHandleSignals signals) const {
    return !!(satisfiable_signals & signals);
  }

  // (Copy and assignment allowed.)
};
static_assert(sizeof(HandleSignalsState) == sizeof(MojoHandleSignalsState),
              "HandleSignalsState should add no overhead");

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_HANDLE_SIGNALS_STATE_H_
