// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"

#include <memory>
#include <utility>

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/blit_pass_vk.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/compute_pass_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/render_pass_vk.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

CommandBufferVK::CommandBufferVK(
    std::weak_ptr<const Context> context,
    std::shared_ptr<CommandEncoderFactoryVK> encoder_factory)
    : CommandBuffer(std::move(context)),
      encoder_factory_(std::move(encoder_factory)) {}

CommandBufferVK::~CommandBufferVK() = default;

void CommandBufferVK::SetLabel(const std::string& label) const {
  if (!encoder_) {
    encoder_factory_->SetLabel(label);
  } else {
    auto context = context_.lock();
    if (!context || !encoder_) {
      return;
    }
    ContextVK::Cast(*context).SetDebugName(encoder_->GetCommandBuffer(), label);
  }
}

bool CommandBufferVK::IsValid() const {
  return true;
}

const std::shared_ptr<CommandEncoderVK>& CommandBufferVK::GetEncoder() {
  if (!encoder_) {
    encoder_ = encoder_factory_->Create();
  }
  return encoder_;
}

bool CommandBufferVK::OnSubmitCommands(CompletionCallback callback) {
  if (!encoder_) {
    encoder_ = encoder_factory_->Create();
  }
  if (!callback) {
    return encoder_->Submit();
  }
  return encoder_->Submit([callback](bool submitted) {
    callback(submitted ? CommandBuffer::Status::kCompleted
                       : CommandBuffer::Status::kError);
  });
}

void CommandBufferVK::OnWaitUntilScheduled() {}

std::shared_ptr<RenderPass> CommandBufferVK::OnCreateRenderPass(
    RenderTarget target) {
  auto context = context_.lock();
  if (!context) {
    return nullptr;
  }
  auto pass =
      std::shared_ptr<RenderPassVK>(new RenderPassVK(context,          //
                                                     target,           //
                                                     weak_from_this()  //
                                                     ));
  if (!pass->IsValid()) {
    return nullptr;
  }
  return pass;
}

std::shared_ptr<BlitPass> CommandBufferVK::OnCreateBlitPass() {
  if (!IsValid()) {
    return nullptr;
  }
  auto pass = std::shared_ptr<BlitPassVK>(new BlitPassVK(weak_from_this()));
  if (!pass->IsValid()) {
    return nullptr;
  }
  return pass;
}

std::shared_ptr<ComputePass> CommandBufferVK::OnCreateComputePass() {
  if (!IsValid()) {
    return nullptr;
  }
  auto context = context_.lock();
  if (!context) {
    return nullptr;
  }
  auto pass =
      std::shared_ptr<ComputePassVK>(new ComputePassVK(context,          //
                                                       weak_from_this()  //
                                                       ));
  if (!pass->IsValid()) {
    return nullptr;
  }
  return pass;
}

}  // namespace impeller
