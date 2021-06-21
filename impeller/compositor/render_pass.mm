// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/render_pass.h"

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "impeller/compositor/device_buffer.h"
#include "impeller/compositor/formats_metal.h"
#include "impeller/shader_glue/shader_types.h"

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
    : buffer_(buffer),
      desc_(desc.ToMTLRenderPassDescriptor()),
      transients_buffer_(HostBuffer::Create()) {
  if (!buffer_ || !desc_) {
    return;
  }
  is_valid_ = true;
}

RenderPass::~RenderPass() = default;

HostBuffer& RenderPass::GetTransientsBuffer() {
  return *transients_buffer_;
}

bool RenderPass::IsValid() const {
  return is_valid_;
}

void RenderPass::SetLabel(std::string label) {
  label_ = std::move(label);
}

bool RenderPass::FinishEncoding(Allocator& transients_allocator) const {
  if (!IsValid()) {
    return false;
  }
  auto pass = [buffer_ renderCommandEncoderWithDescriptor:desc_];

  if (!pass) {
    return false;
  }

  if (!label_.empty()) {
    [pass setLabel:@(label_.c_str())];
  }

  // Success or failure, the pass must end. The buffer can only process one pass
  // at a time.
  fml::ScopedCleanupClosure auto_end([pass]() { [pass endEncoding]; });

  return EncodeCommands(transients_allocator, pass);
}

static bool Bind(id<MTLRenderCommandEncoder> pass,
                 Allocator& allocator,
                 ShaderStage stage,
                 size_t bind_index,
                 const BufferView& view) {
  if (!view.buffer) {
    return false;
  }

  auto device_buffer = view.buffer->GetDeviceBuffer(allocator);
  if (!device_buffer) {
    return false;
  }

  auto buffer = device_buffer->GetMTLBuffer();
  // The Metal call is a void return and we don't want to make it on nil.
  if (!buffer) {
    return false;
  }

  [pass setVertexBuffer:buffer offset:view.range.offset atIndex:bind_index];
  return true;
}

static bool Bind(Allocator& allocator,
                 ShaderStage stage,
                 size_t bind_index,
                 const Texture& view) {
  FML_CHECK(false);
  return false;
}

static bool Bind(Allocator& allocator,
                 ShaderStage stage,
                 size_t bind_index,
                 const Sampler& view) {
  FML_CHECK(false);
  return false;
}

bool RenderPass::EncodeCommands(Allocator& allocator,
                                id<MTLRenderCommandEncoder> pass) const {
  // There a numerous opportunities here to ensure bindings are not repeated.
  // Stuff like setting the vertex buffer bindings over and over when just the
  // offsets could be updated (as recommended in best practices).
  auto bind_stage_resources = [&allocator, pass](const Bindings& bindings,
                                                 ShaderStage stage) -> bool {
    for (const auto buffer : bindings.buffers) {
      if (!Bind(pass, allocator, stage, buffer.first, buffer.second)) {
        return false;
      }
    }
    for (const auto texture : bindings.textures) {
      if (!Bind(allocator, stage, texture.first, *texture.second)) {
        return false;
      }
    }
    for (const auto sampler : bindings.samplers) {
      if (!Bind(allocator, stage, sampler.first, *sampler.second)) {
        return false;
      }
    }
    return true;
  };
  fml::closure pop_debug_marker = [pass]() { [pass popDebugGroup]; };
  for (const auto& command : commands_) {
    fml::ScopedCleanupClosure auto_pop_debug_marker(pop_debug_marker);
    if (!command.label.empty()) {
      [pass pushDebugGroup:@(command.label.c_str())];
    } else {
      auto_pop_debug_marker.Release();
    }

    [pass setRenderPipelineState:command.pipeline->GetMTLRenderPipelineState()];
    [pass setDepthStencilState:command.pipeline->GetMTLDepthStencilState()];
    [pass setFrontFacingWinding:MTLWindingClockwise];
    [pass setCullMode:MTLCullModeBack];
    if (!bind_stage_resources(command.vertex_bindings, ShaderStage::kVertex)) {
      return false;
    }
    if (!bind_stage_resources(command.fragment_bindings,
                              ShaderStage::kFragment)) {
      return false;
    }
    auto index_buffer = command.index_buffer.buffer;
    if (!index_buffer) {
      return false;
    }
    auto device_buffer = index_buffer->GetDeviceBuffer(allocator);
    if (!device_buffer) {
      return false;
    }
    auto mtl_index_buffer = device_buffer->GetMTLBuffer();
    if (!mtl_index_buffer) {
      return false;
    }
    [pass drawIndexedPrimitives:MTLPrimitiveTypeTriangleStrip
                     indexCount:command.index_count
                      indexType:MTLIndexTypeUInt32
                    indexBuffer:mtl_index_buffer
              indexBufferOffset:command.index_buffer.range.offset
                  instanceCount:1u
                     baseVertex:0u
                   baseInstance:0u];
  }
  return true;
}

bool RenderPass::RecordCommand(Command command) {
  if (!command) {
    return false;
  }

  commands_.emplace_back(std::move(command));
  return true;
}

}  // namespace impeller
