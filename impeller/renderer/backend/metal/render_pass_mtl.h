// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_RENDER_PASS_MTL_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_RENDER_PASS_MTL_H_

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

  RenderPassMTL(std::shared_ptr<const Context> context,
                const RenderTarget& target,
                id<MTLCommandBuffer> buffer);

  // |RenderPass|
  bool IsValid() const override;

  // |RenderPass|
  void OnSetLabel(std::string label) override;

  // |RenderPass|
  bool OnEncodeCommands(const Context& context) const override;

  bool EncodeCommands(const std::shared_ptr<Allocator>& transients_allocator,
                      id<MTLRenderCommandEncoder> pass) const;

  RenderPassMTL(const RenderPassMTL&) = delete;

  RenderPassMTL& operator=(const RenderPassMTL&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_RENDER_PASS_MTL_H_
