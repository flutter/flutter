// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

class CommandBufferMTL final : public CommandBuffer {
 public:
  // |CommandBuffer|
  ~CommandBufferMTL() override;

 private:
  friend class ContextMTL;

  id<MTLCommandBuffer> buffer_ = nullptr;

  CommandBufferMTL(const std::weak_ptr<const Context>& context,
                   id<MTLCommandQueue> queue);

  // |CommandBuffer|
  void SetLabel(const std::string& label) const override;

  // |CommandBuffer|
  bool IsValid() const override;

  // |CommandBuffer|
  bool OnSubmitCommands(CompletionCallback callback) override;

  // |CommandBuffer|
  void OnWaitUntilScheduled() override;

  // |CommandBuffer|
  bool SubmitCommandsAsync(std::shared_ptr<RenderPass> render_pass) override;

  // |CommandBuffer|
  std::shared_ptr<RenderPass> OnCreateRenderPass(RenderTarget target) override;

  // |CommandBuffer|
  std::shared_ptr<BlitPass> OnCreateBlitPass() const override;

  // |CommandBuffer|
  std::shared_ptr<ComputePass> OnCreateComputePass() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(CommandBufferMTL);
};

}  // namespace impeller
