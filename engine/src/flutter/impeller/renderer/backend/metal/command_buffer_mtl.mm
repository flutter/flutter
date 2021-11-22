// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/command_buffer_mtl.h"

#include "impeller/renderer/backend/metal/render_pass_mtl.h"

namespace impeller {

CommandBufferMTL::CommandBufferMTL(id<MTLCommandQueue> queue)
    : buffer_([queue commandBuffer]) {
  if (!buffer_) {
    return;
  }
  is_valid_ = true;
}

CommandBufferMTL::~CommandBufferMTL() = default;

bool CommandBufferMTL::IsValid() const {
  return is_valid_;
}

static CommandBuffer::Status ToCommitResult(MTLCommandBufferStatus status) {
  switch (status) {
    case MTLCommandBufferStatusCompleted:
      return CommandBufferMTL::Status::kCompleted;
    case MTLCommandBufferStatusEnqueued:
      return CommandBufferMTL::Status::kPending;
    default:
      break;
  }
  return CommandBufferMTL::Status::kError;
}

void CommandBufferMTL::SubmitCommands(CompletionCallback callback) {
  if (!callback) {
    callback = [](auto) {};
  }

  if (!buffer_) {
    // Already committed. This is caller error.
    callback(Status::kError);
    return;
  }

  [buffer_ addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    callback(ToCommitResult(buffer.status));
  }];
  [buffer_ commit];
  buffer_ = nil;
}

std::shared_ptr<RenderPass> CommandBufferMTL::CreateRenderPass(
    RenderTarget target) const {
  if (!buffer_) {
    return nullptr;
  }

  auto pass = std::shared_ptr<RenderPassMTL>(
      new RenderPassMTL(buffer_, std::move(target)));
  if (!pass->IsValid()) {
    return nullptr;
  }

  return pass;
}

}  // namespace impeller
