// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/formats_metal.h"

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

}  // namespace impeller
