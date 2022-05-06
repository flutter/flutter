// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/command_buffer_gles.h"

#include "impeller/base/config.h"
#include "impeller/renderer/backend/gles/render_pass_gles.h"

namespace impeller {

CommandBufferGLES::CommandBufferGLES(ReactorGLES::Ref reactor)
    : reactor_(std::move(reactor)),
      is_valid_(reactor_ && reactor_->IsValid()) {}

CommandBufferGLES::~CommandBufferGLES() = default;

// |CommandBuffer|
void CommandBufferGLES::SetLabel(const std::string& label) const {
  // Cannot support.
}

// |CommandBuffer|
bool CommandBufferGLES::IsValid() const {
  return is_valid_;
}

// |CommandBuffer|
bool CommandBufferGLES::SubmitCommands(CompletionCallback callback) {
  if (!IsValid()) {
    return false;
  }

  const auto result = reactor_->React();

  if (callback) {
    callback(result ? CommandBuffer::Status::kCompleted
                    : CommandBuffer::Status::kError);
  }
  return result;
}

// |CommandBuffer|
std::shared_ptr<RenderPass> CommandBufferGLES::OnCreateRenderPass(
    RenderTarget target) const {
  if (!IsValid()) {
    return nullptr;
  }
  auto pass = std::shared_ptr<RenderPassGLES>(
      new RenderPassGLES(std::move(target), reactor_));
  if (!pass->IsValid()) {
    return nullptr;
  }
  return pass;
}

}  // namespace impeller
