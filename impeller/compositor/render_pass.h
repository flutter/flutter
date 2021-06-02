// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/compositor/formats.h"
#include "impeller/compositor/texture.h"
#include "impeller/entity/color.h"

namespace impeller {

struct RenderPassAttachment {
  std::shared_ptr<Texture> texture;
  LoadAction load_action = LoadAction::kDontCare;
  StoreAction store_action = StoreAction::kDontCare;
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
 private:
  FML_DISALLOW_COPY_AND_ASSIGN(RenderPassDescriptor);
};

class RenderPass {
 public:
  RenderPass();

  ~RenderPass();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(RenderPass);
};

}  // namespace impeller
