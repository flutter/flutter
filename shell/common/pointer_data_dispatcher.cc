// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/pointer_data_dispatcher.h"

namespace flutter {

PointerDataDispatcher::~PointerDataDispatcher() = default;
DefaultPointerDataDispatcher::~DefaultPointerDataDispatcher() = default;
SmoothPointerDataDispatcher::~SmoothPointerDataDispatcher() = default;

void DefaultPointerDataDispatcher::DispatchPacket(
    std::unique_ptr<PointerDataPacket> packet,
    uint64_t trace_flow_id) {
  animator_.EnqueueTraceFlowId(trace_flow_id);
  runtime_controller_.DispatchPointerDataPacket(*packet);
}

// Intentional no-op.
void DefaultPointerDataDispatcher::OnFrameLayerTreeReceived() {}

void SmoothPointerDataDispatcher::DispatchPacket(
    std::unique_ptr<PointerDataPacket> packet,
    uint64_t trace_flow_id) {
  if (is_pointer_data_in_progress_) {
    if (pending_packet_ != nullptr) {
      DispatchPendingPacket();
    }
    pending_packet_ = std::move(packet);
    pending_trace_flow_id_ = trace_flow_id;
  } else {
    FML_DCHECK(pending_packet_ == nullptr);
    DefaultPointerDataDispatcher::DispatchPacket(std::move(packet),
                                                 trace_flow_id);
  }
  is_pointer_data_in_progress_ = true;
}

void SmoothPointerDataDispatcher::OnFrameLayerTreeReceived() {
  if (is_pointer_data_in_progress_) {
    if (pending_packet_ != nullptr) {
      // This is already in the UI thread. However, method
      // `OnFrameLayerTreeReceived` is called by `Engine::Render` (a part of the
      // `VSYNC` UI thread task) which is in Flutter framework's
      // `SchedulerPhase.persistentCallbacks` phase. In that phase, no pointer
      // data packet is allowed to be fired because the framework requires such
      // phase to be executed synchronously without being interrupted. Hence
      // we'll post a new UI thread task to fire the packet after `VSYNC` task
      // is done. When a non-VSYNC UI thread task (like the following one) is
      // run, the Flutter framework is always in `SchedulerPhase.idle` phase).
      task_runners_.GetUITaskRunner()->PostTask(
          // Use and validate a `fml::WeakPtr` because this dispatcher might
          // have been destructed with engine when the task is run.
          [dispatcher = weak_factory_.GetWeakPtr()]() {
            if (dispatcher) {
              dispatcher->DispatchPendingPacket();
            }
          });
    } else {
      is_pointer_data_in_progress_ = false;
    }
  }
}

void SmoothPointerDataDispatcher::DispatchPendingPacket() {
  FML_DCHECK(pending_packet_ != nullptr);
  FML_DCHECK(is_pointer_data_in_progress_);
  DefaultPointerDataDispatcher::DispatchPacket(std::move(pending_packet_),
                                               pending_trace_flow_id_);
  pending_packet_ = nullptr;
  pending_trace_flow_id_ = -1;
}

}  // namespace flutter
