// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/command_buffer.h"

namespace impeller {

CommandBuffer::CommandBuffer(id<MTLCommandQueue> queue)
    : buffer_([queue commandBuffer]) {}

CommandBuffer::~CommandBuffer() = default;

bool CommandBuffer::IsValid() const {
  return is_valid_;
}

static CommandBuffer::CommitResult ToCommitResult(
    MTLCommandBufferStatus status) {
  switch (status) {
    case MTLCommandBufferStatusCompleted:
      return CommandBuffer::CommitResult::kCompleted;
    case MTLCommandBufferStatusEnqueued:
      return CommandBuffer::CommitResult::kPending;
    default:
      break;
  }
  return CommandBuffer::CommitResult::kError;
}

void CommandBuffer::Commit(CommitCallback callback) {
  if (!callback) {
    callback = [](auto) {};
  }

  if (!buffer_) {
    callback(CommitResult::kError);
    return;
  }

  [buffer_ addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    callback(ToCommitResult(buffer.status));
  }];
  [buffer_ commit];
  buffer_ = nil;
}

std::shared_ptr<RenderPass> CommandBuffer::CreateRenderPass(
    const RenderPassDescriptor& desc) const {
  if (!buffer_) {
    return nullptr;
  }

  auto pass = std::shared_ptr<RenderPass>(new RenderPass(buffer_, desc));
  if (!pass->IsValid()) {
    return nullptr;
  }

  return pass;
}

}  // namespace impeller
