// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/waiter_test_utils.h"

#include <utility>

using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace test {

SimpleWaiterThread::SimpleWaiterThread(MojoResult* result, uint64_t* context)
    : result_(result), context_(context) {
  waiter_.Init();
  *result_ = 5420734;            // Totally invalid result.
  *context_ = 2341532489023ULL;  // "Random".
}

SimpleWaiterThread::~SimpleWaiterThread() {
  Join();
}

void SimpleWaiterThread::Run() {
  *result_ = waiter_.Wait(MOJO_DEADLINE_INDEFINITE, context_);
}

WaiterThread::WaiterThread(RefPtr<Dispatcher>&& dispatcher,
                           MojoHandleSignals handle_signals,
                           MojoDeadline deadline,
                           uint64_t context,
                           bool* did_wait_out,
                           MojoResult* result_out,
                           uint64_t* context_out,
                           HandleSignalsState* signals_state_out)
    : dispatcher_(std::move(dispatcher)),
      handle_signals_(handle_signals),
      deadline_(deadline),
      context_(context),
      did_wait_out_(did_wait_out),
      result_out_(result_out),
      context_out_(context_out),
      signals_state_out_(signals_state_out) {
  *did_wait_out_ = false;
  // Initialize these with invalid results (so that we'll be sure to catch any
  // case where they're not set).
  *result_out_ = 8542346;
  *context_out_ = 89023444;
  *signals_state_out_ = HandleSignalsState(~0u, ~0u);
}

WaiterThread::~WaiterThread() {
  Join();
}

void WaiterThread::Run() {
  waiter_.Init();

  *result_out_ = dispatcher_->AddAwakable(&waiter_, handle_signals_, context_,
                                          signals_state_out_);
  if (*result_out_ != MOJO_RESULT_OK)
    return;

  *did_wait_out_ = true;
  *result_out_ = waiter_.Wait(deadline_, context_out_);
  dispatcher_->RemoveAwakable(&waiter_, signals_state_out_);
}

}  // namespace test
}  // namespace system
}  // namespace mojo
