// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/mock_simple_dispatcher.h"

#include "base/logging.h"
#include "mojo/edk/util/thread_annotations.h"

using mojo::util::MakeRefCounted;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace test {

void MockSimpleDispatcher::SetSatisfiedSignals(
    MojoHandleSignals new_satisfied_signals) {
  MutexLocker locker(&mutex());

  // Any new signals that are set should be satisfiable.
  CHECK_EQ(new_satisfied_signals & ~state_.satisfied_signals,
           new_satisfied_signals & ~state_.satisfied_signals &
               state_.satisfiable_signals);

  if (new_satisfied_signals == state_.satisfied_signals)
    return;

  state_.satisfied_signals = new_satisfied_signals;
  HandleSignalsStateChangedNoLock();
}

void MockSimpleDispatcher::SetSatisfiableSignals(
    MojoHandleSignals new_satisfiable_signals) {
  MutexLocker locker(&mutex());

  // Satisfied implies satisfiable.
  CHECK_EQ(new_satisfiable_signals & state_.satisfied_signals,
           state_.satisfied_signals);

  if (new_satisfiable_signals == state_.satisfiable_signals)
    return;

  state_.satisfiable_signals = new_satisfiable_signals;
  HandleSignalsStateChangedNoLock();
}

Dispatcher::Type MockSimpleDispatcher::GetType() const {
  return Type::UNKNOWN;
}

bool MockSimpleDispatcher::SupportsEntrypointClass(
    EntrypointClass entrypoint_class) const {
  return (entrypoint_class == EntrypointClass::NONE);
}

MockSimpleDispatcher::MockSimpleDispatcher(
    MojoHandleSignals satisfied_signals,
    MojoHandleSignals satisfiable_signals)
    : state_(satisfied_signals, satisfiable_signals) {}

MockSimpleDispatcher::MockSimpleDispatcher(const HandleSignalsState& state)
    : state_(state) {}

MockSimpleDispatcher::~MockSimpleDispatcher() {}

MojoResult MockSimpleDispatcher::DuplicateDispatcherImplNoLock(
    util::RefPtr<Dispatcher>* new_dispatcher) {
  *new_dispatcher = MakeRefCounted<MockSimpleDispatcher>(state_);
  return MOJO_RESULT_OK;
}

RefPtr<Dispatcher>
MockSimpleDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock(
    MessagePipe* /*message_pipe*/,
    unsigned /*port*/) MOJO_NO_THREAD_SAFETY_ANALYSIS {
  CancelAllStateNoLock();
  return MakeRefCounted<MockSimpleDispatcher>(state_);
}

HandleSignalsState MockSimpleDispatcher::GetHandleSignalsStateImplNoLock()
    const {
  mutex().AssertHeld();
  return state_;
}

}  // namespace test
}  // namespace system
}  // namespace mojo
