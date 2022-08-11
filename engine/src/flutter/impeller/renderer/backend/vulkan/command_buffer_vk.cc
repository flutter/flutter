// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"

#include "flutter/fml/logging.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

CommandBufferVK::CommandBufferVK(std::weak_ptr<const Context> context)
    : CommandBuffer(std::move(context)) {}

CommandBufferVK::~CommandBufferVK() = default;

void CommandBufferVK::SetLabel(const std::string& label) const {
  FML_UNREACHABLE();
}

bool CommandBufferVK::IsValid() const {
  FML_UNREACHABLE();
}

bool CommandBufferVK::OnSubmitCommands(CompletionCallback callback) {
  FML_UNREACHABLE();
}

std::shared_ptr<RenderPass> CommandBufferVK::OnCreateRenderPass(
    RenderTarget target) const {
  FML_UNREACHABLE();
}

std::shared_ptr<BlitPass> CommandBufferVK::OnCreateBlitPass() const {
  FML_UNREACHABLE();
}

}  // namespace impeller
