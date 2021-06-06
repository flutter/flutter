// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/surface.h"

#include "flutter/fml/logging.h"
#include "impeller/compositor/command_buffer.h"

namespace impeller {

constexpr size_t kMaxFramesInFlight = 3u;

Surface::Surface(std::shared_ptr<Context> context)
    : context_(std::move(context)),
      frames_in_flight_sema_(::dispatch_semaphore_create(kMaxFramesInFlight)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  is_valid_ = true;
}

Surface::~Surface() = default;

bool Surface::IsValid() const {
  return is_valid_;
}

bool Surface::Render() const {
  if (!IsValid()) {
    return false;
  }

  auto command_buffer = context_->CreateRenderCommandBuffer();

  if (!command_buffer) {
    return false;
  }

  ::dispatch_semaphore_wait(frames_in_flight_sema_, DISPATCH_TIME_FOREVER);

  command_buffer->Commit(
      [sema = frames_in_flight_sema_](CommandBuffer::CommitResult) {
        ::dispatch_semaphore_signal(sema);
      });

  return true;
}

}  // namespace impeller
