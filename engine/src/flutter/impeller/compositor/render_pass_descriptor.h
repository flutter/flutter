// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <optional>

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/compositor/formats.h"
#include "impeller/geometry/size.h"

namespace impeller {

class RenderPassDescriptor {
 public:
  RenderPassDescriptor();

  ~RenderPassDescriptor();

  bool HasColorAttachment(size_t index) const;

  std::optional<ISize> GetColorAttachmentSize(size_t index) const;

  RenderPassDescriptor& SetColorAttachment(ColorRenderPassAttachment attachment,
                                           size_t index);

  RenderPassDescriptor& SetDepthAttachment(
      DepthRenderPassAttachment attachment);

  RenderPassDescriptor& SetStencilAttachment(
      StencilRenderPassAttachment attachment);

  MTLRenderPassDescriptor* ToMTLRenderPassDescriptor() const;

 private:
  std::map<size_t, ColorRenderPassAttachment> colors_;
  std::optional<DepthRenderPassAttachment> depth_;
  std::optional<StencilRenderPassAttachment> stencil_;
};

}  // namespace impeller
