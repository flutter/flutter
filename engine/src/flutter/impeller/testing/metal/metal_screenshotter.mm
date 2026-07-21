// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/testing/metal/metal_screenshotter.h"

#include <CoreImage/CoreImage.h>
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#define GLFW_INCLUDE_NONE
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/impeller/testing/metal/metal_screenshot.h"

namespace impeller {
namespace testing {

MetalScreenshotter::MetalScreenshotter() {}

std::unique_ptr<Screenshot> MetalScreenshotter::MakeScreenshot(
    const AiksContext& aiks_context,
    const std::shared_ptr<Texture>& texture) {
  return MakeScreenshot(aiks_context.GetContext(), texture);
}

std::unique_ptr<Screenshot> Screenshotter::MakeMetalScreenshot(
    std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  return MetalScreenshotter::MakeScreenshot(context, texture);
}

std::unique_ptr<Screenshot> MetalScreenshotter::MakeScreenshot(
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  @autoreleasepool {
    fml::AutoResetWaitableEvent latch;
    if (auto cmd_buffer = context->CreateCommandBuffer()) {
      if (context->GetCommandQueue()
              ->Submit({cmd_buffer},
                       [&latch](CommandBuffer::Status status) {
                         FML_CHECK(status == CommandBuffer::Status::kCompleted);
                         latch.Signal();
                       })
              .ok()) {
        latch.Wait();
      }
    }

    id<MTLTexture> metal_texture =
        std::static_pointer_cast<TextureMTL>(texture)->GetMTLTexture();

    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    CIImage* ciImage = [[CIImage alloc]
        initWithMTLTexture:metal_texture
                   options:@{kCIImageColorSpace : (__bridge id)color_space}];
    CGColorSpaceRelease(color_space);
    FML_CHECK(ciImage);

    std::shared_ptr<ContextMTL> context_mtl =
        std::static_pointer_cast<ContextMTL>(context);
    CIContext* cicontext =
        [CIContext contextWithMTLDevice:context_mtl->GetMTLDevice()];
    FML_CHECK(context);

    CIImage* flipped = [ciImage
        imageByApplyingOrientation:kCGImagePropertyOrientationDownMirrored];

    CGImageRef cgImage = [cicontext createCGImage:flipped
                                         fromRect:[flipped extent]];

    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks)
    return std::unique_ptr<MetalScreenshot>(new MetalScreenshot(cgImage));
  }
}

}  // namespace testing
}  // namespace impeller
