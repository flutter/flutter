// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/impeller/renderer/backend/gles/reactor_gles.h"
#include "flutter/impeller/renderer/render_pass.h"

namespace impeller {

class RenderPassGLES final : public RenderPass {
 public:
  // |RenderPass|
  ~RenderPassGLES() override;

 private:
  friend class CommandBufferGLES;

  ReactorGLES::Ref reactor_;
  std::string label_;
  bool is_valid_ = false;

  RenderPassGLES(RenderTarget target, ReactorGLES::Ref reactor);

  // |RenderPass|
  bool IsValid() const override;

  // |RenderPass|
  void OnSetLabel(std::string label) override;

  // |RenderPass|
  bool EncodeCommands(
      const std::shared_ptr<Allocator>& transients_allocator) const override;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPassGLES);
};

}  // namespace impeller
