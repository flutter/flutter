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

static CommandBuffer::CommitResult ToCommitResult(
    MTLCommandBufferStatus status) {
  switch (status) {
    case MTLCommandBufferStatusCompleted:
      return CommandBufferMTL::CommitResult::kCompleted;
    case MTLCommandBufferStatusEnqueued:
      return CommandBufferMTL::CommitResult::kPending;
    default:
      break;
  }
  return CommandBufferMTL::CommitResult::kError;
}

void CommandBufferMTL::Commit(CommitCallback callback) {
  if (!callback) {
    callback = [](auto) {};
  }

  if (!buffer_) {
    // Already committed. This is caller error.
    callback(CommitResult::kError);
    return;
  }

  [buffer_ addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    callback(ToCommitResult(buffer.status));
  }];
  [buffer_ commit];
  buffer_ = nil;
}

std::shared_ptr<RenderPass> CommandBufferMTL::CreateRenderPass(
    const RenderPassDescriptor& desc) const {
  if (!buffer_) {
    return nullptr;
  }

  auto pass = std::shared_ptr<RenderPassMTL>(new RenderPassMTL(buffer_, desc));
  if (!pass->IsValid()) {
    return nullptr;
  }

  return pass;
}

}  // namespace impeller
