// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/render_pass_descriptor.h"

#include "impeller/renderer/texture.h"

namespace impeller {

RenderPassDescriptor::RenderPassDescriptor() = default;

RenderPassDescriptor::~RenderPassDescriptor() = default;

bool RenderPassDescriptor::HasColorAttachment(size_t index) const {
  if (auto found = colors_.find(index); found != colors_.end()) {
    return true;
  }
  return false;
}

std::optional<ISize> RenderPassDescriptor::GetColorAttachmentSize(
    size_t index) const {
  auto found = colors_.find(index);

  if (found == colors_.end()) {
    return std::nullopt;
  }

  return found->second.texture->GetSize();
}

RenderPassDescriptor& RenderPassDescriptor::SetColorAttachment(
    RenderPassColorAttachment attachment,
    size_t index) {
  if (attachment) {
    colors_[index] = attachment;
  }
  return *this;
}

RenderPassDescriptor& RenderPassDescriptor::SetDepthAttachment(
    RenderPassDepthAttachment attachment) {
  if (attachment) {
    depth_ = std::move(attachment);
  }
  return *this;
}

RenderPassDescriptor& RenderPassDescriptor::SetStencilAttachment(
    RenderPassStencilAttachment attachment) {
  if (attachment) {
    stencil_ = std::move(attachment);
  }
  return *this;
}

}  // namespace impeller
