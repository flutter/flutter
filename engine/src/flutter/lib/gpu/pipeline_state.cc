// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/pipeline_state.h"

#include <map>
#include <type_traits>

#include "flutter/fml/hash_combine.h"

namespace flutter {
namespace gpu {

static_assert(std::is_trivially_copyable_v<PipelineState>);
static_assert(std::is_standard_layout_v<PipelineState>);

bool PipelineState::operator==(const PipelineState& other) const {
  if (cull_mode != other.cull_mode || winding_order != other.winding_order ||
      primitive_type != other.primitive_type ||
      polygon_mode != other.polygon_mode ||
      sample_count != other.sample_count ||
      depth_format != other.depth_format ||
      stencil_format != other.stencil_format ||
      color_attachment_count != other.color_attachment_count ||
      !(depth == other.depth) || !(stencil_front == other.stencil_front) ||
      !(stencil_back == other.stencil_back)) {
    return false;
  }
  for (size_t i = 0; i < color_attachment_count; i++) {
    if (!(colors[i] == other.colors[i])) {
      return false;
    }
  }
  return true;
}

size_t PipelineState::GetHash() const {
  size_t hash = fml::HashCombine(
      cull_mode, winding_order, primitive_type, polygon_mode, sample_count,
      depth_format, stencil_format, color_attachment_count, depth.GetHash(),
      stencil_front.GetHash(), stencil_back.GetHash());
  for (size_t i = 0; i < color_attachment_count; i++) {
    hash = fml::HashCombine(hash, colors[i].Hash());
  }
  return hash;
}

size_t PipelineState::GetUsedSize() const {
  return offsetof(PipelineState, colors) +
         color_attachment_count * sizeof(impeller::ColorAttachmentDescriptor);
}

impeller::PipelineDescriptor PipelineState::ToDescriptor() const {
  impeller::PipelineDescriptor desc;
  desc.SetCullMode(cull_mode);
  desc.SetWindingOrder(winding_order);
  desc.SetPrimitiveType(primitive_type);
  desc.SetPolygonMode(polygon_mode);
  desc.SetSampleCount(sample_count);

  std::map<size_t, impeller::ColorAttachmentDescriptor> color_descriptors;
  for (size_t i = 0; i < color_attachment_count; i++) {
    if (colors[i].format != impeller::PixelFormat::kUnknown) {
      color_descriptors[i] = colors[i];
    }
  }
  desc.SetColorAttachmentDescriptors(std::move(color_descriptors));

  if (stencil_format != impeller::PixelFormat::kUnknown) {
    desc.SetStencilPixelFormat(stencil_format);
    desc.SetStencilAttachmentDescriptors(stencil_front, stencil_back);
  } else {
    desc.ClearStencilAttachments();
  }

  if (depth_format != impeller::PixelFormat::kUnknown) {
    desc.SetDepthPixelFormat(depth_format);
    desc.SetDepthStencilAttachmentDescriptor(depth);
  } else {
    desc.ClearDepthAttachment();
  }
  return desc;
}

}  // namespace gpu
}  // namespace flutter
