// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/simple_dispatcher.h"

#include "base/logging.h"

namespace mojo {
namespace system {

SimpleDispatcher::SimpleDispatcher() {
}

SimpleDispatcher::~SimpleDispatcher() {
}

void SimpleDispatcher::HandleSignalsStateChangedNoLock() {
  mutex().AssertHeld();
  awakable_list_.AwakeForStateChange(GetHandleSignalsStateImplNoLock());
}

void SimpleDispatcher::CancelAllStateNoLock() {
  mutex().AssertHeld();
  awakable_list_.CancelAll();
}

MojoResult SimpleDispatcher::AddAwakableImplNoLock(
    Awakable* awakable,
    MojoHandleSignals signals,
    bool force,
    uint64_t context,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();

  HandleSignalsState state(GetHandleSignalsStateImplNoLock());
  if (state.satisfies(signals)) {
    if (force)
      awakable_list_.Add(awakable, signals, context);
    if (signals_state)
      *signals_state = state;
    return MOJO_RESULT_ALREADY_EXISTS;
  }
  if (!state.can_satisfy(signals)) {
    if (signals_state)
      *signals_state = state;
    return MOJO_RESULT_FAILED_PRECONDITION;
  }

  awakable_list_.Add(awakable, signals, context);
  return MOJO_RESULT_OK;
}

void SimpleDispatcher::RemoveAwakableImplNoLock(
    Awakable* awakable,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  awakable_list_.Remove(awakable);
  if (signals_state)
    *signals_state = GetHandleSignalsStateImplNoLock();
}

}  // namespace system
}  // namespace mojo
