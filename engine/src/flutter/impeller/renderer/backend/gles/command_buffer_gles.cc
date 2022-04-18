// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/command_buffer_gles.h"

#include "impeller/base/config.h"

namespace impeller {

CommandBufferGLES::CommandBufferGLES() = default;

CommandBufferGLES::~CommandBufferGLES() = default;

// |CommandBuffer|
void CommandBufferGLES::SetLabel(const std::string& label) const {}

// |CommandBuffer|
bool CommandBufferGLES::IsValid() const {
  IMPELLER_UNIMPLEMENTED;
}

// |CommandBuffer|
bool CommandBufferGLES::SubmitCommands(CompletionCallback callback) {
  IMPELLER_UNIMPLEMENTED;
}

// |CommandBuffer|
void CommandBufferGLES::ReserveSpotInQueue() {
  IMPELLER_UNIMPLEMENTED;
}

// |CommandBuffer|
std::shared_ptr<RenderPass> CommandBufferGLES::CreateRenderPass(
    RenderTarget target) const {
  IMPELLER_UNIMPLEMENTED;
}

}  // namespace impeller
