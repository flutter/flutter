// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/vertex_descriptor_mtl.h"

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"

namespace impeller {

VertexDescriptorMTL::VertexDescriptorMTL() = default;

VertexDescriptorMTL::~VertexDescriptorMTL() = default;

static MTLVertexFormat ReadStageInputFormat(const ShaderStageIOSlot& input) {
  switch (input.GetVertexAttributeFormat()) {
    case VertexAttributeFormat::kFloat32:
      return MTLVertexFormatFloat;
    case VertexAttributeFormat::kFloat32x2:
      return MTLVertexFormatFloat2;
    case VertexAttributeFormat::kFloat32x3:
      return MTLVertexFormatFloat3;
    case VertexAttributeFormat::kFloat32x4:
      return MTLVertexFormatFloat4;
    case VertexAttributeFormat::kFloat16:
      return MTLVertexFormatHalf;
    case VertexAttributeFormat::kFloat16x2:
      return MTLVertexFormatHalf2;
    case VertexAttributeFormat::kFloat16x3:
      return MTLVertexFormatHalf3;
    case VertexAttributeFormat::kFloat16x4:
      return MTLVertexFormatHalf4;
    case VertexAttributeFormat::kSInt8:
      return MTLVertexFormatChar;
    case VertexAttributeFormat::kSInt8x2:
      return MTLVertexFormatChar2;
    case VertexAttributeFormat::kSInt8x3:
      return MTLVertexFormatChar3;
    case VertexAttributeFormat::kSInt8x4:
      return MTLVertexFormatChar4;
    case VertexAttributeFormat::kUInt8:
      return MTLVertexFormatUChar;
    case VertexAttributeFormat::kUInt8x2:
      return MTLVertexFormatUChar2;
    case VertexAttributeFormat::kUInt8x3:
      return MTLVertexFormatUChar3;
    case VertexAttributeFormat::kUInt8x4:
      return MTLVertexFormatUChar4;
    case VertexAttributeFormat::kSInt16:
      return MTLVertexFormatShort;
    case VertexAttributeFormat::kSInt16x2:
      return MTLVertexFormatShort2;
    case VertexAttributeFormat::kSInt16x3:
      return MTLVertexFormatShort3;
    case VertexAttributeFormat::kSInt16x4:
      return MTLVertexFormatShort4;
    case VertexAttributeFormat::kUInt16:
      return MTLVertexFormatUShort;
    case VertexAttributeFormat::kUInt16x2:
      return MTLVertexFormatUShort2;
    case VertexAttributeFormat::kUInt16x3:
      return MTLVertexFormatUShort3;
    case VertexAttributeFormat::kUInt16x4:
      return MTLVertexFormatUShort4;
    case VertexAttributeFormat::kSInt32:
      return MTLVertexFormatInt;
    case VertexAttributeFormat::kSInt32x2:
      return MTLVertexFormatInt2;
    case VertexAttributeFormat::kSInt32x3:
      return MTLVertexFormatInt3;
    case VertexAttributeFormat::kSInt32x4:
      return MTLVertexFormatInt4;
    case VertexAttributeFormat::kUInt32:
      return MTLVertexFormatUInt;
    case VertexAttributeFormat::kUInt32x2:
      return MTLVertexFormatUInt2;
    case VertexAttributeFormat::kUInt32x3:
      return MTLVertexFormatUInt3;
    case VertexAttributeFormat::kUInt32x4:
      return MTLVertexFormatUInt4;
    case VertexAttributeFormat::kInvalid:
      return MTLVertexFormatInvalid;
  }
}

bool VertexDescriptorMTL::SetStageInputsAndLayout(
    const std::vector<ShaderStageIOSlot>& inputs,
    const std::vector<ShaderStageBufferLayout>& layouts) {
  auto descriptor = descriptor_ = [MTLVertexDescriptor vertexDescriptor];

  // TODO(jonahwilliams): its odd that we offset buffers from the max index on
  // metal but not on GLES or Vulkan. We should probably consistently start
  // these at zero?
  for (size_t i = 0; i < inputs.size(); i++) {
    const auto& input = inputs[i];
    auto vertex_format = ReadStageInputFormat(input);
    if (vertex_format == MTLVertexFormatInvalid) {
      VALIDATION_LOG << "Format for input " << input.name << " not supported.";
      return false;
    }
    auto attrib = descriptor.attributes[input.location];
    attrib.format = vertex_format;
    attrib.offset = input.offset;
    attrib.bufferIndex =
        VertexDescriptor::kReservedVertexBufferIndex - input.binding;
  }

  for (size_t i = 0; i < layouts.size(); i++) {
    const auto& layout = layouts[i];
    auto vertex_layout =
        descriptor.layouts[VertexDescriptor::kReservedVertexBufferIndex -
                           layout.binding];
    vertex_layout.stride = layout.stride;
    vertex_layout.stepRate = 1u;
    vertex_layout.stepFunction = layout.input_rate == VertexInputRate::kInstance
                                     ? MTLVertexStepFunctionPerInstance
                                     : MTLVertexStepFunctionPerVertex;
  }
  return true;
}

MTLVertexDescriptor* VertexDescriptorMTL::GetMTLVertexDescriptor() const {
  return descriptor_;
}

}  // namespace impeller
