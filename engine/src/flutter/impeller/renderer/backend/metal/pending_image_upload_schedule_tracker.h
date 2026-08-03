// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PENDING_IMAGE_UPLOAD_SCHEDULE_TRACKER_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PENDING_IMAGE_UPLOAD_SCHEDULE_TRACKER_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <unordered_map>

#include "impeller/base/thread.h"
#include "impeller/renderer/command_buffer_scheduling_receipt.h"

namespace impeller {

/// Tracks image-upload command buffers until they are scheduled or terminal.
///
/// The tracker is thread-safe. Waiting snapshots the pending receipts and does
/// not hold the tracker mutex while blocking.
class PendingImageUploadScheduleTracker {
 public:
  PendingImageUploadScheduleTracker();

  ~PendingImageUploadScheduleTracker();

  void Track(std::shared_ptr<CommandBufferSchedulingReceipt> receipt);

  void WaitUntilScheduled() const;

  size_t GetPendingCount() const;

 private:
  struct State {
    Mutex mutex;
    uint64_t next_id IPLR_GUARDED_BY(mutex) = 1u;
    std::unordered_map<uint64_t,
                       std::shared_ptr<CommandBufferSchedulingReceipt>>
        pending IPLR_GUARDED_BY(mutex);
  };

  std::shared_ptr<State> state_;

  PendingImageUploadScheduleTracker(const PendingImageUploadScheduleTracker&) =
      delete;

  PendingImageUploadScheduleTracker& operator=(
      const PendingImageUploadScheduleTracker&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_PENDING_IMAGE_UPLOAD_SCHEDULE_TRACKER_H_
