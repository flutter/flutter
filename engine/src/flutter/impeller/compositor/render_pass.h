// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>

#include "flutter/fml/macros.h"
#include "impeller/compositor/formats.h"
#include "impeller/compositor/texture.h"
#include "impeller/geometry/color.h"

namespace impeller {

struct RenderPassAttachment {
  std::shared_ptr<Texture> texture;
  LoadAction load_action = LoadAction::kDontCare;
  StoreAction store_action = StoreAction::kDontCare;

  constexpr operator bool() const { return static_cast<bool>(texture); }
};

struct ColorRenderPassAttachment : public RenderPassAttachment {
  Color clear_color = Color::BlackTransparent();
};

struct DepthRenderPassAttachment : public RenderPassAttachment {
  double clear_depth = 0.0;
};

struct StencilRenderPassAttachment : public RenderPassAttachment {
  uint32_t clear_stencil = 0;
};

class RenderPassDescriptor {
 public:
  RenderPassDescriptor();

  ~RenderPassDescriptor();

  RenderPassDescriptor& SetColorAttachment(ColorRenderPassAttachment attachment,
                                           size_t index);

  RenderPassDescriptor& SetDepthAttachment(
      DepthRenderPassAttachment attachment);

  RenderPassDescriptor& SetStencilAttachment(
      StencilRenderPassAttachment attachment);

 private:
  std::map<size_t, ColorRenderPassAttachment> color_;
  std::optional<DepthRenderPassAttachment> depth_;
  std::optional<StencilRenderPassAttachment> stencil_;
};

class RenderPass {
 public:
  RenderPass(RenderPassDescriptor desc);

  ~RenderPass();

 private:
  RenderPassDescriptor desc_;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPass);
};

}  // namespace impeller
