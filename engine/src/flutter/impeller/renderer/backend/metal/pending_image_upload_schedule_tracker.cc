// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/pending_image_upload_schedule_tracker.h"

#include <vector>

#include "flutter/fml/trace_event.h"

namespace impeller {

PendingImageUploadScheduleTracker::PendingImageUploadScheduleTracker()
    : state_(std::make_shared<State>()) {}

PendingImageUploadScheduleTracker::~PendingImageUploadScheduleTracker() =
    default;

void PendingImageUploadScheduleTracker::Track(
    std::shared_ptr<CommandBufferSchedulingReceipt> receipt) {
  if (!receipt || receipt->IsScheduledOrTerminal()) {
    return;
  }

  const std::shared_ptr<State> state = state_;
  uint64_t receipt_id;
  {
    Lock lock(state->mutex);
    receipt_id = state->next_id++;
    state->pending.emplace(receipt_id, receipt);
  }

  receipt->AddScheduledOrTerminalCallback(
      [weak_state = std::weak_ptr<State>(state), receipt_id]() {
        const std::shared_ptr<State> state = weak_state.lock();
        if (!state) {
          return;
        }
        Lock lock(state->mutex);
        state->pending.erase(receipt_id);
      });
}

void PendingImageUploadScheduleTracker::WaitUntilScheduled() const {
  std::vector<std::shared_ptr<CommandBufferSchedulingReceipt>> receipts;
  {
    Lock lock(state_->mutex);
    receipts.reserve(state_->pending.size());
    for (const auto& entry : state_->pending) {
      receipts.push_back(entry.second);
    }
  }

  for (const auto& receipt : receipts) {
    TRACE_EVENT0("impeller", "ImpellerMetalImageUploadScheduleWait");
    receipt->WaitUntilScheduled();
  }
}

size_t PendingImageUploadScheduleTracker::GetPendingCount() const {
  Lock lock(state_->mutex);
  return state_->pending.size();
}

}  // namespace impeller
