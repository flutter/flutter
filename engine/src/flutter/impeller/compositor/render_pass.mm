// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/render_pass.h"

#include "flutter/fml/logging.h"
#include "impeller/compositor/formats_metal.h"

namespace impeller {

RenderPassDescriptor::RenderPassDescriptor() = default;

RenderPassDescriptor::~RenderPassDescriptor() = default;

bool RenderPassDescriptor::HasColorAttachment(size_t index) const {
  if (auto found = colors_.find(index); found != colors_.end()) {
    return true;
  }
  return false;
}

RenderPassDescriptor& RenderPassDescriptor::SetColorAttachment(
    ColorRenderPassAttachment attachment,
    size_t index) {
  if (attachment) {
    colors_[index] = attachment;
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

static bool ConfigureAttachment(const RenderPassAttachment& desc,
                                MTLRenderPassAttachmentDescriptor* attachment) {
  if (!desc.texture) {
    return false;
  }

  attachment.texture = desc.texture->GetMTLTexture();
  attachment.loadAction = ToMTLLoadAction(desc.load_action);
  attachment.storeAction = ToMTLStoreAction(desc.store_action);
  return true;
}

static bool ConfigureColorAttachment(
    const ColorRenderPassAttachment& desc,
    MTLRenderPassColorAttachmentDescriptor* attachment) {
  if (!ConfigureAttachment(desc, attachment)) {
    return false;
  }
  attachment.clearColor = ToMTLClearColor(desc.clear_color);
  return true;
}

static bool ConfigureDepthAttachment(
    const DepthRenderPassAttachment& desc,
    MTLRenderPassDepthAttachmentDescriptor* attachment) {
  if (!ConfigureAttachment(desc, attachment)) {
    return false;
  }
  attachment.clearDepth = desc.clear_depth;
  return true;
}

static bool ConfigureStencilAttachment(
    const StencilRenderPassAttachment& desc,
    MTLRenderPassStencilAttachmentDescriptor* attachment) {
  if (!ConfigureAttachment(desc, attachment)) {
    return false;
  }
  attachment.clearStencil = desc.clear_stencil;
  return true;
}

MTLRenderPassDescriptor* RenderPassDescriptor::ToMTLRenderPassDescriptor()
    const {
  auto result = [MTLRenderPassDescriptor renderPassDescriptor];

  for (const auto& color : colors_) {
    if (!ConfigureColorAttachment(color.second,
                                  result.colorAttachments[color.first])) {
      FML_LOG(ERROR) << "Could not configure color attachment at index "
                     << color.first;
      return nil;
    }
  }

  if (depth_.has_value() &&
      !ConfigureDepthAttachment(depth_.value(), result.depthAttachment)) {
    return nil;
  }

  if (stencil_.has_value() &&
      !ConfigureStencilAttachment(stencil_.value(), result.stencilAttachment)) {
    return nil;
  }

  return result;
}

RenderPass::RenderPass(id<MTLCommandBuffer> buffer,
                       const RenderPassDescriptor& desc)
    : buffer_(buffer), desc_(desc.ToMTLRenderPassDescriptor()) {
  if (!buffer_ || !desc_) {
    return;
  }
  is_valid_ = true;
}

RenderPass::~RenderPass() = default;

bool RenderPass::IsValid() const {
  return is_valid_;
}

bool RenderPass::Encode() const {
  if (!IsValid()) {
    return false;
  }
  auto pass = [buffer_ renderCommandEncoderWithDescriptor:desc_];
  if (!pass) {
    return false;
  }
  [pass endEncoding];
  return true;
}

}  // namespace impeller
