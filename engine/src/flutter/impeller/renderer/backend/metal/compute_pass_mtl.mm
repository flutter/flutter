// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/compute_pass_mtl.h"

#include <Metal/Metal.h>
#include <memory>
#include <variant>

#include "flutter/fml/backtrace.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/metal/compute_pipeline_mtl.h"
#include "impeller/renderer/backend/metal/device_buffer_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/sampler_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/compute_command.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/host_buffer.h"
#include "impeller/renderer/shader_types.h"

namespace impeller {

ComputePassMTL::ComputePassMTL(std::weak_ptr<const Context> context,
                               id<MTLCommandBuffer> buffer)
    : ComputePass(std::move(context)), buffer_(buffer) {
  if (!buffer_) {
    return;
  }
  is_valid_ = true;
}

ComputePassMTL::~ComputePassMTL() = default;

bool ComputePassMTL::IsValid() const {
  return is_valid_;
}

void ComputePassMTL::OnSetLabel(std::string label) {
  if (label.empty()) {
    return;
  }
  label_ = std::move(label);
}

bool ComputePassMTL::OnEncodeCommands(const Context& context,
                                      const ISize& grid_size,
                                      const ISize& thread_group_size) const {
  TRACE_EVENT0("impeller", "ComputePassMTL::EncodeCommands");
  if (!IsValid()) {
    return false;
  }

  // TODO(dnfield): Support non-serial dispatch type on higher iOS versions.
  auto compute_command_encoder = [buffer_ computeCommandEncoder];

  if (!compute_command_encoder) {
    return false;
  }

  if (!label_.empty()) {
    [compute_command_encoder setLabel:@(label_.c_str())];
  }

  // Success or failure, the pass must end. The buffer can only process one pass
  // at a time.
  fml::ScopedCleanupClosure auto_end(
      [compute_command_encoder]() { [compute_command_encoder endEncoding]; });

  return EncodeCommands(context.GetResourceAllocator(), compute_command_encoder,
                        grid_size, thread_group_size);
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
struct ComputePassBindingsCache {
  explicit ComputePassBindingsCache(id<MTLComputeCommandEncoder> encoder)
      : encoder_(encoder) {}

  ComputePassBindingsCache(const ComputePassBindingsCache&) = delete;

  ComputePassBindingsCache(ComputePassBindingsCache&&) = delete;

  void SetComputePipelineState(id<MTLComputePipelineState> pipeline) {
    if (pipeline == pipeline_) {
      return;
    }
    pipeline_ = pipeline;
    [encoder_ setComputePipelineState:pipeline_];
  }

  id<MTLComputePipelineState> GetPipeline() const { return pipeline_; }

  void SetBuffer(uint64_t index, uint64_t offset, id<MTLBuffer> buffer) {
    auto found = buffers_.find(index);
    if (found != buffers_.end() && found->second.buffer == buffer) {
      // The right buffer is bound. Check if its offset needs to be updated.
      if (found->second.offset == offset) {
        // Buffer and its offset is identical. Nothing to do.
        return;
      }

      // Only the offset needs to be updated.
      found->second.offset = offset;

      [encoder_ setBufferOffset:offset atIndex:index];
      return;
    }

    buffers_[index] = {buffer, static_cast<size_t>(offset)};
    [encoder_ setBuffer:buffer offset:offset atIndex:index];
  }

  void SetTexture(uint64_t index, id<MTLTexture> texture) {
    auto found = textures_.find(index);
    if (found != textures_.end() && found->second == texture) {
      // Already bound.
      return;
    }
    textures_[index] = texture;
    [encoder_ setTexture:texture atIndex:index];
    return;
  }

  void SetSampler(uint64_t index, id<MTLSamplerState> sampler) {
    auto found = samplers_.find(index);
    if (found != samplers_.end() && found->second == sampler) {
      // Already bound.
      return;
    }
    samplers_[index] = sampler;
    [encoder_ setSamplerState:sampler atIndex:index];
    return;
  }

 private:
  struct BufferOffsetPair {
    id<MTLBuffer> buffer = nullptr;
    size_t offset = 0u;
  };
  using BufferMap = std::map<uint64_t, BufferOffsetPair>;
  using TextureMap = std::map<uint64_t, id<MTLTexture>>;
  using SamplerMap = std::map<uint64_t, id<MTLSamplerState>>;

  const id<MTLComputeCommandEncoder> encoder_;
  id<MTLComputePipelineState> pipeline_ = nullptr;
  BufferMap buffers_;
  TextureMap textures_;
  SamplerMap samplers_;
};

static bool Bind(ComputePassBindingsCache& pass,
                 Allocator& allocator,
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

  pass.SetBuffer(bind_index, view.range.offset, buffer);
  return true;
}

static bool Bind(ComputePassBindingsCache& pass,
                 size_t bind_index,
                 const Texture& texture) {
  if (!texture.IsValid()) {
    return false;
  }

  pass.SetTexture(bind_index, TextureMTL::Cast(texture).GetMTLTexture());
  return true;
}

static bool Bind(ComputePassBindingsCache& pass,
                 size_t bind_index,
                 const Sampler& sampler) {
  if (!sampler.IsValid()) {
    return false;
  }

  pass.SetSampler(bind_index, SamplerMTL::Cast(sampler).GetMTLSamplerState());
  return true;
}

bool ComputePassMTL::EncodeCommands(const std::shared_ptr<Allocator>& allocator,
                                    id<MTLComputeCommandEncoder> encoder,
                                    const ISize& grid_size,
                                    const ISize& thread_group_size) const {
  ComputePassBindingsCache pass_bindings(encoder);

  fml::closure pop_debug_marker = [encoder]() { [encoder popDebugGroup]; };
  for (const auto& command : commands_) {
    fml::ScopedCleanupClosure auto_pop_debug_marker(pop_debug_marker);
    if (!command.label.empty()) {
      [encoder pushDebugGroup:@(command.label.c_str())];
    } else {
      auto_pop_debug_marker.Release();
    }

    pass_bindings.SetComputePipelineState(
        ComputePipelineMTL::Cast(*command.pipeline)
            .GetMTLComputePipelineState());

    for (const auto& buffer : command.bindings.buffers) {
      if (!Bind(pass_bindings, *allocator, buffer.first,
                buffer.second.resource)) {
        return false;
      }
    }

    for (const auto& texture : command.bindings.textures) {
      if (!Bind(pass_bindings, texture.first, *texture.second.resource)) {
        return false;
      }
    }
    for (const auto& sampler : command.bindings.samplers) {
      if (!Bind(pass_bindings, sampler.first, *sampler.second.resource)) {
        return false;
      }
    }
    // TODO(dnfield): use feature detection to support non-uniform threadgroup
    // sizes.
    // https://github.com/flutter/flutter/issues/110619

    // For now, check that the sizes are uniform.
    FML_DCHECK(grid_size == thread_group_size);
    auto width = grid_size.width;
    auto height = grid_size.height;
    while (width * height >
           static_cast<int64_t>(
               pass_bindings.GetPipeline().maxTotalThreadsPerThreadgroup)) {
      width /= 2;
      height /= 2;
    }
    auto size = MTLSizeMake(width, height, 1);
    [encoder dispatchThreadgroups:size threadsPerThreadgroup:size];
  }

  return true;
}

}  // namespace impeller
