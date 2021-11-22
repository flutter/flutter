// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/render_pass_mtl.h"

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "impeller/base/base.h"
#include "impeller/renderer/backend/metal/device_buffer_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_mtl.h"
#include "impeller/renderer/backend/metal/sampler_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/host_buffer.h"
#include "impeller/renderer/shader_types.h"

namespace impeller {

static bool ConfigureAttachment(const Attachment& desc,
                                MTLRenderPassAttachmentDescriptor* attachment) {
  if (!desc.texture) {
    return false;
  }

  attachment.texture = TextureMTL::Cast(*desc.texture).GetMTLTexture();
  attachment.loadAction = ToMTLLoadAction(desc.load_action);
  attachment.storeAction = ToMTLStoreAction(desc.store_action);
  return true;
}

static bool ConfigureColorAttachment(
    const ColorAttachment& desc,
    MTLRenderPassColorAttachmentDescriptor* attachment) {
  if (!ConfigureAttachment(desc, attachment)) {
    return false;
  }
  attachment.clearColor = ToMTLClearColor(desc.clear_color);
  return true;
}

static bool ConfigureDepthAttachment(
    const DepthAttachment& desc,
    MTLRenderPassDepthAttachmentDescriptor* attachment) {
  if (!ConfigureAttachment(desc, attachment)) {
    return false;
  }
  attachment.clearDepth = desc.clear_depth;
  return true;
}

static bool ConfigureStencilAttachment(
    const StencilAttachment& desc,
    MTLRenderPassStencilAttachmentDescriptor* attachment) {
  if (!ConfigureAttachment(desc, attachment)) {
    return false;
  }
  attachment.clearStencil = desc.clear_stencil;
  return true;
}

// TODO(csg): Move this to formats_mtl.h
static MTLRenderPassDescriptor* ToMTLRenderPassDescriptor(
    const RenderTarget& desc) {
  auto result = [MTLRenderPassDescriptor renderPassDescriptor];

  const auto& colors = desc.GetColorAttachments();

  for (const auto& color : colors) {
    if (!ConfigureColorAttachment(color.second,
                                  result.colorAttachments[color.first])) {
      FML_LOG(ERROR) << "Could not configure color attachment at index "
                     << color.first;
      return nil;
    }
  }

  const auto& depth = desc.GetDepthAttachment();

  if (depth.has_value() &&
      !ConfigureDepthAttachment(depth.value(), result.depthAttachment)) {
    return nil;
  }

  const auto& stencil = desc.GetStencilAttachment();

  if (stencil.has_value() &&
      !ConfigureStencilAttachment(stencil.value(), result.stencilAttachment)) {
    return nil;
  }

  return result;
}

RenderPassMTL::RenderPassMTL(id<MTLCommandBuffer> buffer, RenderTarget target)
    : RenderPass(std::move(target)),
      buffer_(buffer),
      desc_(ToMTLRenderPassDescriptor(GetRenderTarget())),
      transients_buffer_(HostBuffer::Create()) {
  if (!buffer_ || !desc_) {
    return;
  }
  is_valid_ = true;
}

RenderPassMTL::~RenderPassMTL() = default;

HostBuffer& RenderPassMTL::GetTransientsBuffer() {
  return *transients_buffer_;
}

bool RenderPassMTL::IsValid() const {
  return is_valid_;
}

void RenderPassMTL::SetLabel(std::string label) {
  if (label.empty()) {
    return;
  }
  label_ = std::move(label);
  transients_buffer_->SetLabel(SPrintF("%s Transients", label_.c_str()));
}

bool RenderPassMTL::EncodeCommands(Allocator& transients_allocator) const {
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

//-----------------------------------------------------------------------------
/// @brief      Ensures that bindings on the pass are not redundantly set or
///             updated. Avoids making the driver do additional checks and makes
///             the frame insights during profiling and instrumentation not
///             complain about the same.
///
///             There should be no change to rendering if this caching was
///             absent.
///
struct PassBindingsCache {
  PassBindingsCache(id<MTLRenderCommandEncoder> pass) : pass_(pass) {}

  PassBindingsCache(const PassBindingsCache&) = delete;

  PassBindingsCache(PassBindingsCache&&) = delete;

  void SetRenderPipelineState(id<MTLRenderPipelineState> pipeline) {
    if (pipeline == pipeline_) {
      return;
    }
    pipeline_ = pipeline;
    [pass_ setRenderPipelineState:pipeline_];
  }

  void SetDepthStencilState(id<MTLDepthStencilState> depth_stencil) {
    if (depth_stencil_ == depth_stencil) {
      return;
    }
    depth_stencil_ = depth_stencil;
    [pass_ setDepthStencilState:depth_stencil_];
  }

  bool SetBuffer(ShaderStage stage,
                 uint64_t index,
                 uint64_t offset,
                 id<MTLBuffer> buffer) {
    auto& buffers_map = buffers_[stage];
    auto found = buffers_map.find(index);
    if (found != buffers_map.end() && found->second.buffer == buffer) {
      // The right buffer is bound. Check if its offset needs to be updated.
      if (found->second.offset == offset) {
        // Buffer and its offset is identical. Nothing to do.
        return true;
      }

      // Only the offset needs to be updated.
      found->second.offset = offset;

      switch (stage) {
        case ShaderStage::kVertex:
          [pass_ setVertexBufferOffset:offset atIndex:index];
          return true;
        case ShaderStage::kFragment:
          [pass_ setFragmentBufferOffset:offset atIndex:index];
          return true;
        default:
          FML_DCHECK(false)
              << "Cannot update buffer offset of an unknown stage.";
          return false;
      }
      return true;
    }
    buffers_map[index] = {buffer, offset};
    switch (stage) {
      case ShaderStage::kVertex:
        [pass_ setVertexBuffer:buffer offset:offset atIndex:index];
        return true;
      case ShaderStage::kFragment:
        [pass_ setFragmentBuffer:buffer offset:offset atIndex:index];
        return true;
      default:
        FML_DCHECK(false) << "Cannot bind buffer to unknown shader stage.";
        return false;
    }
    return false;
  }

  bool SetTexture(ShaderStage stage, uint64_t index, id<MTLTexture> texture) {
    auto& texture_map = textures_[stage];
    auto found = texture_map.find(index);
    if (found != texture_map.end() && found->second == texture) {
      // Already bound.
      return true;
    }
    texture_map[index] = texture;
    switch (stage) {
      case ShaderStage::kVertex:
        [pass_ setVertexTexture:texture atIndex:index];
        return true;
      case ShaderStage::kFragment:
        [pass_ setFragmentTexture:texture atIndex:index];
        return true;
      default:
        FML_DCHECK(false) << "Cannot bind buffer to unknown shader stage.";
        return false;
    }
    return false;
  }

  bool SetSampler(ShaderStage stage,
                  uint64_t index,
                  id<MTLSamplerState> sampler) {
    auto& sampler_map = samplers_[stage];
    auto found = sampler_map.find(index);
    if (found != sampler_map.end() && found->second == sampler) {
      // Already bound.
      return true;
    }
    sampler_map[index] = sampler;
    switch (stage) {
      case ShaderStage::kVertex:
        [pass_ setVertexSamplerState:sampler atIndex:index];
        return true;
      case ShaderStage::kFragment:
        [pass_ setFragmentSamplerState:sampler atIndex:index];
        return true;
      default:
        FML_DCHECK(false) << "Cannot bind buffer to unknown shader stage.";
        return false;
    }
    return false;
  }

 private:
  struct BufferOffsetPair {
    id<MTLBuffer> buffer = nullptr;
    size_t offset = 0u;
  };
  using BufferMap = std::map<uint64_t, BufferOffsetPair>;
  using TextureMap = std::map<uint64_t, id<MTLTexture>>;
  using SamplerMap = std::map<uint64_t, id<MTLSamplerState>>;

  const id<MTLRenderCommandEncoder> pass_;
  id<MTLRenderPipelineState> pipeline_ = nullptr;
  id<MTLDepthStencilState> depth_stencil_ = nullptr;
  std::map<ShaderStage, BufferMap> buffers_;
  std::map<ShaderStage, TextureMap> textures_;
  std::map<ShaderStage, SamplerMap> samplers_;
};

static bool Bind(PassBindingsCache& pass,
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

  auto buffer = DeviceBufferMTL::Cast(*device_buffer).GetMTLBuffer();
  // The Metal call is a void return and we don't want to make it on nil.
  if (!buffer) {
    return false;
  }

  return pass.SetBuffer(stage, bind_index, view.range.offset, buffer);
}

static bool Bind(PassBindingsCache& pass,
                 ShaderStage stage,
                 size_t bind_index,
                 const Texture& texture) {
  if (!texture.IsValid()) {
    return false;
  }

  return pass.SetTexture(stage, bind_index,
                         TextureMTL::Cast(texture).GetMTLTexture());
}

static bool Bind(PassBindingsCache& pass,
                 ShaderStage stage,
                 size_t bind_index,
                 const Sampler& sampler) {
  if (!sampler.IsValid()) {
    return false;
  }

  return pass.SetSampler(stage, bind_index,
                         SamplerMTL::Cast(sampler).GetMTLSamplerState());
}

bool RenderPassMTL::EncodeCommands(Allocator& allocator,
                                   id<MTLRenderCommandEncoder> pass) const {
  PassBindingsCache pass_bindings(pass);
  auto bind_stage_resources = [&allocator, &pass_bindings](
                                  const Bindings& bindings,
                                  ShaderStage stage) -> bool {
    for (const auto buffer : bindings.buffers) {
      if (!Bind(pass_bindings, allocator, stage, buffer.first, buffer.second)) {
        return false;
      }
    }
    for (const auto texture : bindings.textures) {
      if (!Bind(pass_bindings, stage, texture.first, *texture.second)) {
        return false;
      }
    }
    for (const auto sampler : bindings.samplers) {
      if (!Bind(pass_bindings, stage, sampler.first, *sampler.second)) {
        return false;
      }
    }
    return true;
  };

  fml::closure pop_debug_marker = [pass]() { [pass popDebugGroup]; };
  for (const auto& command : commands_) {
    if (command.index_count == 0u) {
      FML_DLOG(ERROR) << "Zero index count in render pass command.";
      continue;
    }

    fml::ScopedCleanupClosure auto_pop_debug_marker(pop_debug_marker);
    if (!command.label.empty()) {
      [pass pushDebugGroup:@(command.label.c_str())];
    } else {
      auto_pop_debug_marker.Release();
    }
    pass_bindings.SetRenderPipelineState(
        PipelineMTL::Cast(*command.pipeline).GetMTLRenderPipelineState());
    pass_bindings.SetDepthStencilState(
        PipelineMTL::Cast(*command.pipeline).GetMTLDepthStencilState());
    [pass setFrontFacingWinding:command.winding == WindingOrder::kClockwise
                                    ? MTLWindingClockwise
                                    : MTLWindingCounterClockwise];
    [pass setCullMode:MTLCullModeNone];
    [pass setStencilReferenceValue:command.stencil_reference];
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
    auto mtl_index_buffer =
        DeviceBufferMTL::Cast(*device_buffer).GetMTLBuffer();
    if (!mtl_index_buffer) {
      return false;
    }
    FML_DCHECK(command.index_count * sizeof(uint32_t) ==
               command.index_buffer.range.length);
    // Returns void. All error checking must be done by this point.
    [pass drawIndexedPrimitives:ToMTLPrimitiveType(command.primitive_type)
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

bool RenderPassMTL::AddCommand(Command command) {
  if (!command) {
    return false;
  }

  commands_.emplace_back(std::move(command));
  return true;
}

}  // namespace impeller
