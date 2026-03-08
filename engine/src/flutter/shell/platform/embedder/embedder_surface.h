// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_H_

#include <memory>
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"

namespace flutter {

class EmbedderSurface {
 public:
  EmbedderSurface();

  virtual ~EmbedderSurface();

  virtual bool IsValid() const = 0;

  virtual std::unique_ptr<Surface> CreateGPUSurface() = 0;

  virtual std::shared_ptr<impeller::Context> CreateImpellerContext() const;

  virtual sk_sp<GrDirectContext> CreateResourceContext() const;

  /// Called when the surface size changes (e.g. on window resize).
  /// Subclasses that manage their own swapchain (such as Vulkan KHR mode)
  /// should override this to update the swapchain dimensions.
  /// Only overridden by EmbedderSurfaceVulkanImpeller (KHR swapchain
  /// mode).
  virtual void UpdateSurfaceSize(int64_t width, int64_t height);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderSurface);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_H_
