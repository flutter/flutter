// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command_buffer_scheduling_receipt.h"

namespace impeller {

CommandBufferSchedulingReceipt::~CommandBufferSchedulingReceipt() = default;

CommandBufferSchedulingReceiptState::CommandBufferSchedulingReceiptState() =
    default;

CommandBufferSchedulingReceiptState::~CommandBufferSchedulingReceiptState() =
    default;

void CommandBufferSchedulingReceiptState::WaitUntilScheduled() const {
  Lock lock(mutex_);
  condition_.Wait(mutex_, [this]() IPLR_REQUIRES(mutex_) {
    return state_ != State::kPending;
  });
}

bool CommandBufferSchedulingReceiptState::IsScheduledOrTerminal() const {
  Lock lock(mutex_);
  return state_ != State::kPending;
}

void CommandBufferSchedulingReceiptState::AddScheduledOrTerminalCallback(
    fml::closure callback) {
  if (!callback) {
    return;
  }
  {
    Lock lock(mutex_);
    if (state_ == State::kPending) {
      callbacks_.push_back(std::move(callback));
      return;
    }
  }
  callback();
}

void CommandBufferSchedulingReceiptState::MarkScheduled() {
  MarkSatisfied(State::kScheduled);
}

void CommandBufferSchedulingReceiptState::MarkTerminal() {
  MarkSatisfied(State::kTerminal);
}

void CommandBufferSchedulingReceiptState::MarkSatisfied(State state) {
  std::vector<fml::closure> callbacks;
  {
    Lock lock(mutex_);
    if (state_ != State::kPending) {
      return;
    }
    state_ = state;
    callbacks.swap(callbacks_);
  }
  condition_.NotifyAll();
  for (const auto& callback : callbacks) {
    callback();
  }
}

}  // namespace impeller
