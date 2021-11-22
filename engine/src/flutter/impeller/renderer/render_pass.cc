// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/render_pass.h"

namespace impeller {

RenderPass::RenderPass(RenderTarget target)
    : render_target_(std::move(target)) {}

RenderPass::~RenderPass() = default;

const RenderTarget& RenderPass::GetRenderTarget() const {
  return render_target_;
}

ISize RenderPass::GetRenderTargetSize() const {
  return render_target_.GetRenderTargetSize();
}

}  // namespace impeller
