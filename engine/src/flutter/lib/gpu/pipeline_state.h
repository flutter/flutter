// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_PIPELINE_STATE_H_
#define FLUTTER_LIB_GPU_PIPELINE_STATE_H_

#include <cstddef>
#include <cstdint>
#include <utility>

#include "impeller/core/formats.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "third_party/abseil-cpp/absl/hash/hash.h"

namespace flutter {
namespace gpu {

/// The draw state that selects a backend pipeline, apart from the shaders.
///
/// Plain data, so that a recording can hold a copy and replay can compare and
/// hash it without allocating. Passes change this state often, and an
/// `impeller::PipelineDescriptor` is too expensive to build each time.
struct PipelineState {
  /// The most color attachments any backend supports.
  static constexpr size_t kMaxColorAttachments = 8;

  impeller::CullMode cull_mode = impeller::CullMode::kNone;
  impeller::WindingOrder winding_order = impeller::WindingOrder::kClockwise;
  impeller::PrimitiveType primitive_type = impeller::PrimitiveType::kTriangle;
  impeller::PolygonMode polygon_mode = impeller::PolygonMode::kFill;
  impeller::SampleCount sample_count = impeller::SampleCount::kCount1;
  /// `kUnknown` when the render target has no writable attachment of the
  /// kind.
  impeller::PixelFormat depth_format = impeller::PixelFormat::kUnknown;
  impeller::PixelFormat stencil_format = impeller::PixelFormat::kUnknown;
  uint8_t color_attachment_count = 0;
  impeller::DepthAttachmentDescriptor depth;
  impeller::StencilAttachmentDescriptor stencil_front;
  impeller::StencilAttachmentDescriptor stencil_back;
  /// The first `color_attachment_count` entries are meaningful. An entry with
  /// an unknown format has no attachment.
  impeller::ColorAttachmentDescriptor colors[kMaxColorAttachments];

  bool operator==(const PipelineState& other) const;

  /// The descriptor for this state, without shaders or a vertex layout.
  impeller::PipelineDescriptor ToDescriptor() const;

  /// Hashes what `operator==` compares.
  template <typename H>
  friend H AbslHashValue(H h, const PipelineState& state) {
    h = H::combine(std::move(h), state.cull_mode, state.winding_order,
                   state.primitive_type, state.polygon_mode, state.sample_count,
                   state.depth_format, state.stencil_format,
                   state.color_attachment_count, state.depth.depth_compare,
                   state.depth.depth_write_enabled);
    h = HashStencil(std::move(h), state.stencil_front);
    h = HashStencil(std::move(h), state.stencil_back);
    for (size_t i = 0; i < state.color_attachment_count; i++) {
      const impeller::ColorAttachmentDescriptor& color = state.colors[i];
      h = H::combine(std::move(h), color.format, color.blending_enabled,
                     color.src_color_blend_factor, color.color_blend_op,
                     color.dst_color_blend_factor, color.src_alpha_blend_factor,
                     color.alpha_blend_op, color.dst_alpha_blend_factor,
                     static_cast<uint64_t>(color.write_mask));
    }
    return h;
  }

 private:
  template <typename H>
  static H HashStencil(H h,
                       const impeller::StencilAttachmentDescriptor& stencil) {
    return H::combine(std::move(h), stencil.stencil_compare,
                      stencil.stencil_failure, stencil.depth_failure,
                      stencil.depth_stencil_pass, stencil.read_mask,
                      stencil.write_mask);
  }
};

}  // namespace gpu
}  // namespace flutter

#endif  // FLUTTER_LIB_GPU_PIPELINE_STATE_H_
