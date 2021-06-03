// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/render_pass.h"

namespace impeller {

RenderPassDescriptor::RenderPassDescriptor() = default;

RenderPassDescriptor::~RenderPassDescriptor() = default;

RenderPassDescriptor& RenderPassDescriptor::SetColorAttachment(
    ColorRenderPassAttachment attachment,
    size_t index) {
  if (attachment) {
    color_[index] = attachment;
  }
  return *this;
}

RenderPassDescriptor& RenderPassDescriptor::SetDepthAttachment(
    DepthRenderPassAttachment attachment) {
  if (attachment) {
    depth_ = std::move(attachment);
  }
  return *this;
}

RenderPassDescriptor& RenderPassDescriptor::SetStencilAttachment(
    StencilRenderPassAttachment attachment) {
  if (attachment) {
    stencil_ = std::move(attachment);
  }
  return *this;
}

RenderPass::RenderPass(RenderPassDescriptor desc) : desc_(std::move(desc)) {}

RenderPass::~RenderPass() = default;

}  // namespace impeller
