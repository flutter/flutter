// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class RenderPassMTL final : public RenderPass {
 public:
  // |RenderPass|
  ~RenderPassMTL() override;

 private:
  friend class CommandBufferMTL;

  id<MTLCommandBuffer> buffer_ = nil;
  MTLRenderPassDescriptor* desc_ = nil;
  std::string label_;
  bool is_valid_ = false;

  RenderPassMTL(id<MTLCommandBuffer> buffer, RenderTarget target);

  // |RenderPass|
  bool IsValid() const override;

  // |RenderPass|
  void OnSetLabel(std::string label) override;

  // |RenderPass|
  bool EncodeCommands(
      const std::shared_ptr<Allocator>& transients_allocator) const override;

  bool EncodeCommands(const std::shared_ptr<Allocator>& transients_allocator,
                      id<MTLRenderCommandEncoder> pass) const;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPassMTL);
};

}  // namespace impeller
