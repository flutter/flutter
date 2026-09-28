// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

CommandQueue::CommandQueue() = default;

CommandQueue::~CommandQueue() = default;

fml::Status CommandQueue::Submit(
    const std::vector<std::shared_ptr<CommandBuffer>>& buffers,
    const CompletionCallback& completion_callback) {
  if (buffers.empty()) {
    if (completion_callback) {
      completion_callback(CommandBuffer::Status::kError);
    }
    return fml::Status(fml::StatusCode::kInvalidArgument,
                       "No command buffers provided.");
  }
  for (const std::shared_ptr<CommandBuffer>& buffer : buffers) {
    if (!buffer->SubmitCommands(completion_callback)) {
      return fml::Status(fml::StatusCode::kCancelled,
                         "Failed to submit command buffer.");
    }
  }
  return fml::Status();
}

CommandQueue::SubmitResult CommandQueue::SubmitWithReceipt(
    const std::shared_ptr<CommandBuffer>& buffer,
    const CompletionCallback& completion_callback) {
  CommandBuffer::SubmitResult result =
      buffer->SubmitCommandsWithReceipt(completion_callback);
  if (!result.submitted) {
    return {
        .status = fml::Status(fml::StatusCode::kCancelled,
                              "Failed to submit command buffer."),
    };
  }
  return {
      .status = fml::Status(),
      .scheduling_receipt = std::move(result.scheduling_receipt),
  };
}

}  // namespace impeller
