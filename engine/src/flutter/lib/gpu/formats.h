// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"

// ATTENTION! ATTENTION! ATTENTION!
// All enums defined in this file must exactly match the contents and order of
// the corresponding enums defined in `gpu/lib/src/formats.dart`.

namespace flutter {
namespace gpu {

enum class FlutterGPUStorageMode {
  kHostVisible,
  kDevicePrivate,
  kDeviceTransient,
};

constexpr impeller::StorageMode ToImpellerStorageMode(
    FlutterGPUStorageMode value) {
  switch (value) {
    case FlutterGPUStorageMode::kHostVisible:
      return impeller::StorageMode::kHostVisible;
    case FlutterGPUStorageMode::kDevicePrivate:
      return impeller::StorageMode::kDevicePrivate;
    case FlutterGPUStorageMode::kDeviceTransient:
      return impeller::StorageMode::kDeviceTransient;
  }
}

enum class FlutterGPUPixelFormat {
  kUnknown,
  kA8UNormInt,
  kR8UNormInt,
  kR8G8UNormInt,
  kR8G8B8A8UNormInt,
  kR8G8B8A8UNormIntSRGB,
  kB8G8R8A8UNormInt,
  kB8G8R8A8UNormIntSRGB,
  kR32G32B32A32Float,
  kR16G16B16A16Float,
  kB10G10R10XR,
  kB10G10R10XRSRGB,
  kB10G10R10A10XR,
  kS8UInt,
  kD24UnormS8Uint,
  kD32FloatS8UInt,
};

constexpr impeller::PixelFormat ToImpellerPixelFormat(
    FlutterGPUPixelFormat value) {
  switch (value) {
    case FlutterGPUPixelFormat::kUnknown:
      return impeller::PixelFormat::kUnknown;
    case FlutterGPUPixelFormat::kA8UNormInt:
      return impeller::PixelFormat::kA8UNormInt;
    case FlutterGPUPixelFormat::kR8UNormInt:
      return impeller::PixelFormat::kR8UNormInt;
    case FlutterGPUPixelFormat::kR8G8UNormInt:
      return impeller::PixelFormat::kR8G8UNormInt;
    case FlutterGPUPixelFormat::kR8G8B8A8UNormInt:
      return impeller::PixelFormat::kR8G8B8A8UNormInt;
    case FlutterGPUPixelFormat::kR8G8B8A8UNormIntSRGB:
      return impeller::PixelFormat::kR8G8B8A8UNormIntSRGB;
    case FlutterGPUPixelFormat::kB8G8R8A8UNormInt:
      return impeller::PixelFormat::kB8G8R8A8UNormInt;
    case FlutterGPUPixelFormat::kB8G8R8A8UNormIntSRGB:
      return impeller::PixelFormat::kB8G8R8A8UNormIntSRGB;
    case FlutterGPUPixelFormat::kR32G32B32A32Float:
      return impeller::PixelFormat::kR32G32B32A32Float;
    case FlutterGPUPixelFormat::kR16G16B16A16Float:
      return impeller::PixelFormat::kR16G16B16A16Float;
    case FlutterGPUPixelFormat::kB10G10R10XR:
      return impeller::PixelFormat::kB10G10R10XR;
    case FlutterGPUPixelFormat::kB10G10R10XRSRGB:
      return impeller::PixelFormat::kB10G10R10XRSRGB;
    case FlutterGPUPixelFormat::kB10G10R10A10XR:
      return impeller::PixelFormat::kB10G10R10A10XR;
    case FlutterGPUPixelFormat::kS8UInt:
      return impeller::PixelFormat::kS8UInt;
    case FlutterGPUPixelFormat::kD24UnormS8Uint:
      return impeller::PixelFormat::kD24UnormS8Uint;
    case FlutterGPUPixelFormat::kD32FloatS8UInt:
      return impeller::PixelFormat::kD32FloatS8UInt;
  }
}

constexpr FlutterGPUPixelFormat FromImpellerPixelFormat(
    impeller::PixelFormat value) {
  switch (value) {
    case impeller::PixelFormat::kUnknown:
      return FlutterGPUPixelFormat::kUnknown;
    case impeller::PixelFormat::kA8UNormInt:
      return FlutterGPUPixelFormat::kA8UNormInt;
    case impeller::PixelFormat::kR8UNormInt:
      return FlutterGPUPixelFormat::kR8UNormInt;
    case impeller::PixelFormat::kR8G8UNormInt:
      return FlutterGPUPixelFormat::kR8G8UNormInt;
    case impeller::PixelFormat::kR8G8B8A8UNormInt:
      return FlutterGPUPixelFormat::kR8G8B8A8UNormInt;
    case impeller::PixelFormat::kR8G8B8A8UNormIntSRGB:
      return FlutterGPUPixelFormat::kR8G8B8A8UNormIntSRGB;
    case impeller::PixelFormat::kB8G8R8A8UNormInt:
      return FlutterGPUPixelFormat::kB8G8R8A8UNormInt;
    case impeller::PixelFormat::kB8G8R8A8UNormIntSRGB:
      return FlutterGPUPixelFormat::kB8G8R8A8UNormIntSRGB;
    case impeller::PixelFormat::kR32G32B32A32Float:
      return FlutterGPUPixelFormat::kR32G32B32A32Float;
    case impeller::PixelFormat::kR16G16B16A16Float:
      return FlutterGPUPixelFormat::kR16G16B16A16Float;
    case impeller::PixelFormat::kB10G10R10XR:
      return FlutterGPUPixelFormat::kB10G10R10XR;
    case impeller::PixelFormat::kB10G10R10XRSRGB:
      return FlutterGPUPixelFormat::kB10G10R10XRSRGB;
    case impeller::PixelFormat::kB10G10R10A10XR:
      return FlutterGPUPixelFormat::kB10G10R10A10XR;
    case impeller::PixelFormat::kS8UInt:
      return FlutterGPUPixelFormat::kS8UInt;
    case impeller::PixelFormat::kD24UnormS8Uint:
      return FlutterGPUPixelFormat::kD24UnormS8Uint;
    case impeller::PixelFormat::kD32FloatS8UInt:
      return FlutterGPUPixelFormat::kD32FloatS8UInt;
  }
}

enum class FlutterGPUTextureCoordinateSystem {
  kUploadFromHost,
  kRenderToTexture,
};

constexpr impeller::TextureCoordinateSystem ToImpellerTextureCoordinateSystem(
    FlutterGPUTextureCoordinateSystem value) {
  switch (value) {
    case FlutterGPUTextureCoordinateSystem::kUploadFromHost:
      return impeller::TextureCoordinateSystem::kUploadFromHost;
    case FlutterGPUTextureCoordinateSystem::kRenderToTexture:
      return impeller::TextureCoordinateSystem::kRenderToTexture;
  }
}

enum class FlutterGPUBlendFactor {
  kZero,
  kOne,
  kSourceColor,
  kOneMinusSourceColor,
  kSourceAlpha,
  kOneMinusSourceAlpha,
  kDestinationColor,
  kOneMinusDestinationColor,
  kDestinationAlpha,
  kOneMinusDestinationAlpha,
  kSourceAlphaSaturated,
  kBlendColor,
  kOneMinusBlendColor,
  kBlendAlpha,
  kOneMinusBlendAlpha,
};

constexpr impeller::BlendFactor ToImpellerBlendFactor(
    FlutterGPUBlendFactor value) {
  switch (value) {
    case FlutterGPUBlendFactor::kZero:
      return impeller::BlendFactor::kZero;
    case FlutterGPUBlendFactor::kOne:
      return impeller::BlendFactor::kOne;
    case FlutterGPUBlendFactor::kSourceColor:
      return impeller::BlendFactor::kSourceColor;
    case FlutterGPUBlendFactor::kOneMinusSourceColor:
      return impeller::BlendFactor::kOneMinusSourceColor;
    case FlutterGPUBlendFactor::kSourceAlpha:
      return impeller::BlendFactor::kSourceAlpha;
    case FlutterGPUBlendFactor::kOneMinusSourceAlpha:
      return impeller::BlendFactor::kOneMinusSourceAlpha;
    case FlutterGPUBlendFactor::kDestinationColor:
      return impeller::BlendFactor::kDestinationColor;
    case FlutterGPUBlendFactor::kOneMinusDestinationColor:
      return impeller::BlendFactor::kOneMinusDestinationColor;
    case FlutterGPUBlendFactor::kDestinationAlpha:
      return impeller::BlendFactor::kDestinationAlpha;
    case FlutterGPUBlendFactor::kOneMinusDestinationAlpha:
      return impeller::BlendFactor::kOneMinusDestinationAlpha;
    case FlutterGPUBlendFactor::kSourceAlphaSaturated:
      return impeller::BlendFactor::kSourceAlphaSaturated;
    case FlutterGPUBlendFactor::kBlendColor:
      return impeller::BlendFactor::kBlendColor;
    case FlutterGPUBlendFactor::kOneMinusBlendColor:
      return impeller::BlendFactor::kOneMinusBlendColor;
    case FlutterGPUBlendFactor::kBlendAlpha:
      return impeller::BlendFactor::kBlendAlpha;
    case FlutterGPUBlendFactor::kOneMinusBlendAlpha:
      return impeller::BlendFactor::kOneMinusBlendAlpha;
  }
}

enum class FlutterGPUBlendOperation {
  kAdd,
  kSubtract,
  kReverseSubtract,
};

constexpr impeller::BlendOperation ToImpellerBlendOperation(
    FlutterGPUBlendOperation value) {
  switch (value) {
    case FlutterGPUBlendOperation::kAdd:
      return impeller::BlendOperation::kAdd;
    case FlutterGPUBlendOperation::kSubtract:
      return impeller::BlendOperation::kSubtract;
    case FlutterGPUBlendOperation::kReverseSubtract:
      return impeller::BlendOperation::kReverseSubtract;
  }
}

enum class FlutterGPULoadAction {
  kDontCare,
  kLoad,
  kClear,
};

constexpr impeller::LoadAction ToImpellerLoadAction(
    FlutterGPULoadAction value) {
  switch (value) {
    case FlutterGPULoadAction::kDontCare:
      return impeller::LoadAction::kDontCare;
    case FlutterGPULoadAction::kLoad:
      return impeller::LoadAction::kLoad;
    case FlutterGPULoadAction::kClear:
      return impeller::LoadAction::kClear;
  }
}

enum class FlutterGPUStoreAction {
  kDontCare,
  kStore,
  kMultisampleResolve,
  kStoreAndMultisampleResolve,
};

constexpr impeller::StoreAction ToImpellerStoreAction(
    FlutterGPUStoreAction value) {
  switch (value) {
    case FlutterGPUStoreAction::kDontCare:
      return impeller::StoreAction::kDontCare;
    case FlutterGPUStoreAction::kStore:
      return impeller::StoreAction::kStore;
    case FlutterGPUStoreAction::kMultisampleResolve:
      return impeller::StoreAction::kMultisampleResolve;
    case FlutterGPUStoreAction::kStoreAndMultisampleResolve:
      return impeller::StoreAction::kStoreAndMultisampleResolve;
  }
}

enum class FlutterGPUShaderStage {
  kVertex,
  kFragment,
};

constexpr impeller::ShaderStage ToImpellerShaderStage(
    FlutterGPUShaderStage value) {
  switch (value) {
    case FlutterGPUShaderStage::kVertex:
      return impeller::ShaderStage::kVertex;
    case FlutterGPUShaderStage::kFragment:
      return impeller::ShaderStage::kFragment;
  }
}

constexpr FlutterGPUShaderStage FromImpellerShaderStage(
    impeller::ShaderStage value) {
  switch (value) {
    case impeller::ShaderStage::kVertex:
      return FlutterGPUShaderStage::kVertex;
    case impeller::ShaderStage::kFragment:
      return FlutterGPUShaderStage::kFragment;
    case impeller::ShaderStage::kUnknown:
    case impeller::ShaderStage::kTessellationControl:
    case impeller::ShaderStage::kTessellationEvaluation:
    case impeller::ShaderStage::kCompute:
      FML_LOG(ERROR) << "Invalid Flutter GPU ShaderStage "
                     << static_cast<size_t>(value);
      FML_UNREACHABLE();
  }
}

}  // namespace gpu
}  // namespace flutter
