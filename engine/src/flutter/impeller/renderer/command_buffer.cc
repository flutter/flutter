// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command_buffer.h"

#include "flutter/fml/trace_event.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

CommandBuffer::CommandBuffer(std::weak_ptr<const Context> context)
    : context_(std::move(context)) {}

CommandBuffer::~CommandBuffer() = default;

bool CommandBuffer::SubmitCommands(CompletionCallback callback) {
  TRACE_EVENT0("impeller", "CommandBuffer::SubmitCommands");
  if (!IsValid()) {
    // Already committed or was never valid. Either way, this is caller error.
    if (callback) {
      callback(Status::kError);
    }
    return false;
  }
  return OnSubmitCommands(callback);
}

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

std::shared_ptr<BlitPass> CommandBuffer::CreateBlitPass() const {
  auto pass = OnCreateBlitPass();
  if (pass && pass->IsValid()) {
    pass->SetLabel("BlitPass");
    return pass;
  }
  return nullptr;
}

}  // namespace impeller
