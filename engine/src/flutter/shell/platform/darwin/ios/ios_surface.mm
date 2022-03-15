// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_surface.h"

#import "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_software.h"

#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#if SHELL_ENABLE_METAL
#import "flutter/shell/platform/darwin/ios/ios_surface_metal_impeller.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_metal_skia.h"
#endif  // SHELL_ENABLE_METAL

namespace flutter {

std::unique_ptr<IOSSurface> IOSSurface::Create(std::shared_ptr<IOSContext> context,
                                               fml::scoped_nsobject<CALayer> layer) {
  FML_DCHECK(layer);
  FML_DCHECK(context);

  if ([layer.get() isKindOfClass:[CAEAGLLayer class]]) {
    return std::make_unique<IOSSurfaceGL>(
        fml::scoped_nsobject<CAEAGLLayer>(
            reinterpret_cast<CAEAGLLayer*>([layer.get() retain])),  // EAGL layer
        std::move(context)                                          // context
    );
  }

#if SHELL_ENABLE_METAL
  if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
    if ([layer.get() isKindOfClass:[CAMetalLayer class]]) {
      switch (context->GetBackend()) {
        case IOSRenderingBackend::kSkia:
          return std::make_unique<IOSSurfaceMetalSkia>(
              fml::scoped_nsobject<CAMetalLayer>(
                  reinterpret_cast<CAMetalLayer*>([layer.get() retain])),  // Metal layer
              std::move(context)                                           // context
          );
          break;
        case IOSRenderingBackend::kImpeller:
          return std::make_unique<IOSSurfaceMetalImpeller>(
              fml::scoped_nsobject<CAMetalLayer>(
                  reinterpret_cast<CAMetalLayer*>([layer.get() retain])),  // Metal layer
              std::move(context)                                           // context
          );
      }
    }
  }
#endif  // SHELL_ENABLE_METAL

  return std::make_unique<IOSSurfaceSoftware>(std::move(layer),   // layer
                                              std::move(context)  // context
  );
}

IOSSurface::IOSSurface(std::shared_ptr<IOSContext> ios_context)
    : ios_context_(std::move(ios_context)) {
  FML_DCHECK(ios_context_);
}

IOSSurface::~IOSSurface() = default;

std::shared_ptr<IOSContext> IOSSurface::GetContext() const {
  return ios_context_;
}

}  // namespace flutter
