// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/compute_pass_mtl.h"

#include <Metal/Metal.h>
#include <algorithm>
#include <memory>

#include "flutter/fml/backtrace.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "fml/status.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/metal/compute_pipeline_mtl.h"
#include "impeller/renderer/backend/metal/device_buffer_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/sampler_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/command.h"

namespace impeller {

ComputePassMTL::ComputePassMTL(std::shared_ptr<const Context> context,
                               id<MTLCommandBuffer> buffer)
    : ComputePass(std::move(context)), buffer_(buffer) {
  if (!buffer_) {
    return;
  }
  encoder_ = [buffer_ computeCommandEncoderWithDispatchType:
                          MTLDispatchType::MTLDispatchTypeConcurrent];
  if (!encoder_) {
    return;
  }
  pass_bindings_cache_.SetEncoder(encoder_);
  is_valid_ = true;
}

ComputePassMTL::~ComputePassMTL() = default;

bool ComputePassMTL::IsValid() const {
  return is_valid_;
}

void ComputePassMTL::OnSetLabel(const std::string& label) {
#ifdef IMPELLER_DEBUG
  if (label.empty()) {
    return;
  }
  [encoder_ setLabel:@(label.c_str())];
#endif  // IMPELLER_DEBUG
}

void ComputePassMTL::SetCommandLabel(std::string_view label) {
  has_label_ = true;
  [encoder_ pushDebugGroup:@(label.data())];
}

// |ComputePass|
void ComputePassMTL::SetPipeline(
    const std::shared_ptr<Pipeline<ComputePipelineDescriptor>>& pipeline) {
  pass_bindings_cache_.SetComputePipelineState(
      ComputePipelineMTL::Cast(*pipeline).GetMTLComputePipelineState());
  workgroup_size_ = pipeline->GetDescriptor().GetWorkgroupSize();
}

// |ComputePass|
void ComputePassMTL::AddBufferMemoryBarrier() {
  [encoder_ memoryBarrierWithScope:MTLBarrierScopeBuffers];
}

// |ComputePass|
void ComputePassMTL::AddTextureMemoryBarrier() {
  [encoder_ memoryBarrierWithScope:MTLBarrierScopeTextures];
}

// |ComputePass|
bool ComputePassMTL::BindResource(ShaderStage stage,
                                  DescriptorType type,
                                  const ShaderUniformSlot& slot,
                                  const ShaderMetadata* metadata,
                                  BufferView view) {
  if (!view.GetBuffer()) {
    return false;
  }

  const DeviceBuffer* device_buffer = view.GetBuffer();
  if (!device_buffer) {
    return false;
  }

  id<MTLBuffer> buffer = DeviceBufferMTL::Cast(*device_buffer).GetMTLBuffer();
  // The Metal call is a void return and we don't want to make it on nil.
  if (!buffer) {
    return false;
  }

  pass_bindings_cache_.SetBuffer(slot.ext_res_0, view.GetRange().offset,
                                 buffer);
  return true;
}

// |ComputePass|
bool ComputePassMTL::BindResource(ShaderStage stage,
                                  DescriptorType type,
                                  const SampledImageSlot& slot,
                                  const ShaderMetadata* metadata,
                                  std::shared_ptr<const Texture> texture,
                                  raw_ptr<const Sampler> sampler) {
  if (!sampler || !texture->IsValid()) {
    return false;
  }

  pass_bindings_cache_.SetTexture(slot.texture_index,
                                  TextureMTL::Cast(*texture).GetMTLTexture());
  pass_bindings_cache_.SetSampler(
      slot.texture_index, SamplerMTL::Cast(*sampler).GetMTLSamplerState());
  return true;
}

fml::Status ComputePassMTL::Compute(std::array<uint32_t, 3> workgroup_count) {
  if (workgroup_count[0] == 0u || workgroup_count[1] == 0u ||
      workgroup_count[2] == 0u) {
    return fml::Status(fml::StatusCode::kCancelled,
                       "Invalid workgroup count for compute command.");
  }

  const NSUInteger max_total =
      pass_bindings_cache_.GetPipeline().maxTotalThreadsPerThreadgroup;

  // Unlike Vulkan and GLES, Metal does not bake the threadgroup size into the
  // shader; it is supplied here at dispatch. Honor the shader's declared local
  // size. A dimension of 0 means the shader sized it with a specialization
  // constant. In that case fill the remaining threadgroup capacity into x while
  // honoring any literal y and z, keeping the total within the device maximum.
  MTLSize threads_per_threadgroup;
  if (workgroup_size_[0] == 0u) {
    const NSUInteger size_y =
        workgroup_size_[1] == 0u ? 1u : workgroup_size_[1];
    const NSUInteger size_z =
        workgroup_size_[2] == 0u ? 1u : workgroup_size_[2];
    const NSUInteger size_x =
        std::max<NSUInteger>(1u, max_total / (size_y * size_z));
    threads_per_threadgroup = MTLSizeMake(size_x, size_y, size_z);
  } else {
    threads_per_threadgroup = MTLSizeMake(
        workgroup_size_[0], workgroup_size_[1] == 0u ? 1 : workgroup_size_[1],
        workgroup_size_[2] == 0u ? 1 : workgroup_size_[2]);
  }

  // Metal aborts at dispatch if the threadgroup size exceeds the device
  // maximum. Vulkan rejects an oversized local size at pipeline creation, so do
  // the equivalent here and fail gracefully instead.
  if (threads_per_threadgroup.width * threads_per_threadgroup.height *
          threads_per_threadgroup.depth >
      max_total) {
    return fml::Status(fml::StatusCode::kCancelled,
                       "Compute shader workgroup size exceeds the device's "
                       "maximum threads per threadgroup.");
  }

  [encoder_
       dispatchThreadgroups:MTLSizeMake(workgroup_count[0], workgroup_count[1],
                                        workgroup_count[2])
      threadsPerThreadgroup:threads_per_threadgroup];

#ifdef IMPELLER_DEBUG
  if (has_label_) {
    [encoder_ popDebugGroup];
  }
  has_label_ = false;
#endif  // IMPELLER_DEBUG
  return fml::Status();
}

bool ComputePassMTL::EncodeCommands() const {
  [encoder_ endEncoding];
  return true;
}

}  // namespace impeller
