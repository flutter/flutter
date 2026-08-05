// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/vertex_descriptor_vk.h"

#include <cstdint>

namespace impeller {

vk::Format ToVertexDescriptorFormat(const ShaderStageIOSlot& input) {
  switch (input.GetVertexAttributeFormat()) {
    case VertexAttributeFormat::kFloat32:
      return vk::Format::eR32Sfloat;
    case VertexAttributeFormat::kFloat32x2:
      return vk::Format::eR32G32Sfloat;
    case VertexAttributeFormat::kFloat32x3:
      return vk::Format::eR32G32B32Sfloat;
    case VertexAttributeFormat::kFloat32x4:
      return vk::Format::eR32G32B32A32Sfloat;
    case VertexAttributeFormat::kFloat16:
      return vk::Format::eR16Sfloat;
    case VertexAttributeFormat::kFloat16x2:
      return vk::Format::eR16G16Sfloat;
    case VertexAttributeFormat::kFloat16x3:
      return vk::Format::eR16G16B16Sfloat;
    case VertexAttributeFormat::kFloat16x4:
      return vk::Format::eR16G16B16A16Sfloat;
    case VertexAttributeFormat::kSInt8:
      return vk::Format::eR8Sint;
    case VertexAttributeFormat::kSInt8x2:
      return vk::Format::eR8G8Sint;
    case VertexAttributeFormat::kSInt8x3:
      return vk::Format::eR8G8B8Sint;
    case VertexAttributeFormat::kSInt8x4:
      return vk::Format::eR8G8B8A8Sint;
    case VertexAttributeFormat::kUInt8:
      return vk::Format::eR8Uint;
    case VertexAttributeFormat::kUInt8x2:
      return vk::Format::eR8G8Uint;
    case VertexAttributeFormat::kUInt8x3:
      return vk::Format::eR8G8B8Uint;
    case VertexAttributeFormat::kUInt8x4:
      return vk::Format::eR8G8B8A8Uint;
    case VertexAttributeFormat::kSInt16:
      return vk::Format::eR16Sint;
    case VertexAttributeFormat::kSInt16x2:
      return vk::Format::eR16G16Sint;
    case VertexAttributeFormat::kSInt16x3:
      return vk::Format::eR16G16B16Sint;
    case VertexAttributeFormat::kSInt16x4:
      return vk::Format::eR16G16B16A16Sint;
    case VertexAttributeFormat::kUInt16:
      return vk::Format::eR16Uint;
    case VertexAttributeFormat::kUInt16x2:
      return vk::Format::eR16G16Uint;
    case VertexAttributeFormat::kUInt16x3:
      return vk::Format::eR16G16B16Uint;
    case VertexAttributeFormat::kUInt16x4:
      return vk::Format::eR16G16B16A16Uint;
    case VertexAttributeFormat::kSInt32:
      return vk::Format::eR32Sint;
    case VertexAttributeFormat::kSInt32x2:
      return vk::Format::eR32G32Sint;
    case VertexAttributeFormat::kSInt32x3:
      return vk::Format::eR32G32B32Sint;
    case VertexAttributeFormat::kSInt32x4:
      return vk::Format::eR32G32B32A32Sint;
    case VertexAttributeFormat::kUInt32:
      return vk::Format::eR32Uint;
    case VertexAttributeFormat::kUInt32x2:
      return vk::Format::eR32G32Uint;
    case VertexAttributeFormat::kUInt32x3:
      return vk::Format::eR32G32B32Uint;
    case VertexAttributeFormat::kUInt32x4:
      return vk::Format::eR32G32B32A32Uint;
    case VertexAttributeFormat::kInvalid:
      return vk::Format::eUndefined;
  }
}

}  // namespace impeller
