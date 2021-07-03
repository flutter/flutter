// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <map>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/compositor/command.h"
#include "impeller/compositor/formats.h"
#include "impeller/compositor/host_buffer.h"
#include "impeller/compositor/texture.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/size.h"

namespace impeller {

class CommandBuffer;

struct RenderPassAttachment {
  std::shared_ptr<Texture> texture;
  LoadAction load_action = LoadAction::kDontCare;
  StoreAction store_action = StoreAction::kStore;

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

  bool HasColorAttachment(size_t index) const;

  std::optional<Size> GetColorAttachmentSize(size_t index) const;

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

class RenderPass {
 public:
  ~RenderPass();

  bool IsValid() const;

  void SetLabel(std::string label);

  HostBuffer& GetTransientsBuffer();

  [[nodiscard]] bool RecordCommand(Command command);

  [[nodiscard]] bool FinishEncoding(Allocator& transients_allocator) const;

 private:
  friend class CommandBuffer;

  id<MTLCommandBuffer> buffer_ = nil;
  MTLRenderPassDescriptor* desc_ = nil;
  std::vector<Command> commands_;
  std::shared_ptr<HostBuffer> transients_buffer_;
  std::string label_;
  bool is_valid_ = false;

  RenderPass(id<MTLCommandBuffer> buffer, const RenderPassDescriptor& desc);

  bool EncodeCommands(Allocator& transients_allocator,
                      id<MTLRenderCommandEncoder> pass) const;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPass);
};

}  // namespace impeller
