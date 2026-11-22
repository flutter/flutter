// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_PIPELINE_STATE_H_
#define FLUTTER_LIB_GPU_PIPELINE_STATE_H_

#include <cstddef>
#include <cstdint>

#include "impeller/core/formats.h"
#include "impeller/renderer/pipeline_descriptor.h"

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

  size_t GetHash() const;

  /// The leading bytes of this struct that hold meaningful state.
  size_t GetUsedSize() const;

  /// The descriptor for this state, without shaders or a vertex layout.
  impeller::PipelineDescriptor ToDescriptor() const;

  struct Hash {
    size_t operator()(const PipelineState& state) const {
      return state.GetHash();
    }
  };
};

}  // namespace gpu
}  // namespace flutter

#endif  // FLUTTER_LIB_GPU_PIPELINE_STATE_H_
