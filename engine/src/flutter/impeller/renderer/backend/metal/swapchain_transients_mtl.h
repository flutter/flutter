// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_SWAPCHAIN_TRANSIENTS_MTL_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_SWAPCHAIN_TRANSIENTS_MTL_H_

#include <memory>

#include "impeller/core/formats.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class SwapchainTransientsMTL {
 public:
  explicit SwapchainTransientsMTL(const std::shared_ptr<Allocator>& allocator);

  ~SwapchainTransientsMTL();

  void SetSizeAndFormat(ISize size, PixelFormat format);

  std::shared_ptr<Texture> GetResolveTexture();

  std::shared_ptr<Texture> GetMSAATexture();

  std::shared_ptr<Texture> GetDepthStencilTexture();

 private:
  std::shared_ptr<Allocator> allocator_;
  ISize size_ = {0, 0};
  PixelFormat format_ = PixelFormat::kUnknown;
  std::shared_ptr<Texture> resolve_tex_;
  std::shared_ptr<Texture> msaa_tex_;
  std::shared_ptr<Texture> depth_stencil_tex_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_METAL_SWAPCHAIN_TRANSIENTS_MTL_H_