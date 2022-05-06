// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class CommandBufferGLES final : public CommandBuffer {
 public:
  // |CommandBuffer|
  ~CommandBufferGLES() override;

 private:
  friend class ContextGLES;

  ReactorGLES::Ref reactor_;
  bool is_valid_ = false;

  CommandBufferGLES(ReactorGLES::Ref reactor);

  // |CommandBuffer|
  void SetLabel(const std::string& label) const override;

  // |CommandBuffer|
  bool IsValid() const override;

  // |CommandBuffer|
  bool SubmitCommands(CompletionCallback callback) override;

  // |CommandBuffer|
  std::shared_ptr<RenderPass> OnCreateRenderPass(
      RenderTarget target) const override;

  FML_DISALLOW_COPY_AND_ASSIGN(CommandBufferGLES);
};

}  // namespace impeller
