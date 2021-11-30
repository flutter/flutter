// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/formats_mtl.h"

#include <memory>

#include "impeller/renderer/render_pass.h"

namespace impeller {

MTLRenderPipelineColorAttachmentDescriptor*
ToMTLRenderPipelineColorAttachmentDescriptor(
    ColorAttachmentDescriptor descriptor) {
  auto des = [[MTLRenderPipelineColorAttachmentDescriptor alloc] init];
  des.pixelFormat = ToMTLPixelFormat(descriptor.format);

  des.blendingEnabled = descriptor.blending_enabled;

  des.sourceRGBBlendFactor =
      ToMTLBlendFactor(descriptor.src_color_blend_factor);
  des.rgbBlendOperation = ToMTLBlendOperation(descriptor.color_blend_op);
  des.destinationRGBBlendFactor =
      ToMTLBlendFactor(descriptor.dst_color_blend_factor);

  des.sourceAlphaBlendFactor =
      ToMTLBlendFactor(descriptor.src_alpha_blend_factor);
  des.alphaBlendOperation = ToMTLBlendOperation(descriptor.alpha_blend_op);
  des.destinationAlphaBlendFactor =
      ToMTLBlendFactor(descriptor.dst_alpha_blend_factor);

  des.writeMask = ToMTLColorWriteMask(descriptor.write_mask);
  return des;
}

MTLStencilDescriptor* ToMTLStencilDescriptor(
    const StencilAttachmentDescriptor& descriptor) {
  auto des = [[MTLStencilDescriptor alloc] init];
  des.stencilCompareFunction = ToMTLCompareFunction(descriptor.stencil_compare);
  des.stencilFailureOperation =
      ToMTLStencilOperation(descriptor.stencil_failure);
  des.depthFailureOperation = ToMTLStencilOperation(descriptor.depth_failure);
  des.depthStencilPassOperation =
      ToMTLStencilOperation(descriptor.depth_stencil_pass);

  des.readMask = descriptor.read_mask;
  des.writeMask = descriptor.write_mask;

  return des;
}

MTLDepthStencilDescriptor* ToMTLDepthStencilDescriptor(
    std::optional<DepthAttachmentDescriptor> depth,
    std::optional<StencilAttachmentDescriptor> front,
    std::optional<StencilAttachmentDescriptor> back) {
  if (!depth) {
    depth = DepthAttachmentDescriptor{
        // Always pass the depth test.
        .depth_compare = CompareFunction::kAlways,
        .depth_write_enabled = false,
    };
  }

  auto des = [[MTLDepthStencilDescriptor alloc] init];

  des.depthCompareFunction = ToMTLCompareFunction(depth->depth_compare);
  des.depthWriteEnabled = depth->depth_write_enabled;

  if (front.has_value()) {
    des.frontFaceStencil = ToMTLStencilDescriptor(front.value());
  }
  if (back.has_value()) {
    des.backFaceStencil = ToMTLStencilDescriptor(back.value());
  }

  return des;
}

MTLTextureDescriptor* ToMTLTextureDescriptor(const TextureDescriptor& desc) {
  if (!desc.IsValid()) {
    return nil;
  }
  auto mtl_desc = [[MTLTextureDescriptor alloc] init];
  mtl_desc.textureType = ToMTLTextureType(desc.type);
  mtl_desc.pixelFormat = ToMTLPixelFormat(desc.format);
  mtl_desc.sampleCount = static_cast<NSUInteger>(desc.sample_count);
  mtl_desc.width = desc.size.width;
  mtl_desc.height = desc.size.height;
  mtl_desc.mipmapLevelCount = desc.mip_count;
  mtl_desc.usage = MTLTextureUsageUnknown;
  if (desc.usage & static_cast<TextureUsageMask>(TextureUsage::kUnknown)) {
    mtl_desc.usage |= MTLTextureUsageUnknown;
  }
  if (desc.usage & static_cast<TextureUsageMask>(TextureUsage::kShaderRead)) {
    mtl_desc.usage |= MTLTextureUsageShaderRead;
  }
  if (desc.usage & static_cast<TextureUsageMask>(TextureUsage::kShaderWrite)) {
    mtl_desc.usage |= MTLTextureUsageShaderWrite;
  }
  if (desc.usage & static_cast<TextureUsageMask>(TextureUsage::kRenderTarget)) {
    mtl_desc.usage |= MTLTextureUsageRenderTarget;
  }
  return mtl_desc;
}

}  // namespace impeller
