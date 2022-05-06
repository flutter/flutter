// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command_buffer.h"

#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

CommandBuffer::CommandBuffer() = default;

CommandBuffer::~CommandBuffer() = default;

bool CommandBuffer::SubmitCommands() {
  return SubmitCommands(nullptr);
}

std::shared_ptr<RenderPass> CommandBuffer::CreateRenderPass(
    RenderTarget render_target) const {
  auto pass = OnCreateRenderPass(std::move(render_target));
  if (pass && pass->IsValid()) {
    pass->SetLabel("RenderPass");
    return pass;
  }
  return nullptr;
}

}  // namespace impeller
