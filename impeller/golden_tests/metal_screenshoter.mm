// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/golden_tests/metal_screenshoter.h"

#include <CoreImage/CoreImage.h>
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#define GLFW_INCLUDE_NONE
#include "third_party/glfw/include/GLFW/glfw3.h"

namespace impeller {
namespace testing {

MetalScreenshoter::MetalScreenshoter() {
  FML_CHECK(::glfwInit() == GLFW_TRUE);
  playground_ =
      PlaygroundImpl::Create(PlaygroundBackend::kMetal, PlaygroundSwitches{});
}

std::unique_ptr<MetalScreenshot> MetalScreenshoter::MakeScreenshot(
    AiksContext& aiks_context,
    const Picture& picture,
    const ISize& size) {
  Vector2 content_scale = playground_->GetContentScale();
  std::shared_ptr<Image> image = picture.ToImage(
      aiks_context,
      ISize(size.width * content_scale.x, size.height * content_scale.y));
  std::shared_ptr<Texture> texture = image->GetTexture();
  id<MTLTexture> metal_texture =
      std::static_pointer_cast<TextureMTL>(texture)->GetMTLTexture();

  if (metal_texture.pixelFormat != MTLPixelFormatBGRA8Unorm) {
    return {};
  }

  CIImage* ciImage = [[CIImage alloc] initWithMTLTexture:metal_texture
                                                 options:@{}];
  FML_CHECK(ciImage);

  std::shared_ptr<Context> context = playground_->GetContext();
  std::shared_ptr<ContextMTL> context_mtl =
      std::static_pointer_cast<ContextMTL>(context);
  CIContext* cicontext =
      [CIContext contextWithMTLDevice:context_mtl->GetMTLDevice()];
  FML_CHECK(context);

  CIImage* flipped = [ciImage
      imageByApplyingOrientation:kCGImagePropertyOrientationDownMirrored];

  CGImageRef cgImage = [cicontext createCGImage:flipped
                                       fromRect:[ciImage extent]];

  return std::unique_ptr<MetalScreenshot>(new MetalScreenshot(cgImage));
}

}  // namespace testing
}  // namespace impeller
