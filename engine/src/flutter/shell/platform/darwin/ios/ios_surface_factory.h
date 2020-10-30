// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS__SURFACE_FACTORY_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS__SURFACE_FACTORY_H_

#include <memory>

#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"
#import "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

namespace flutter {

class IOSSurfaceFactory {
 public:
  static std::shared_ptr<IOSSurfaceFactory> Create(
      IOSRenderingAPI rendering_api);

  explicit IOSSurfaceFactory(std::shared_ptr<IOSContext> ios_context);

  ~IOSSurfaceFactory();

  void SetPlatformViewsController(
      const std::shared_ptr<FlutterPlatformViewsController>&
          platform_views_controller);

  std::unique_ptr<IOSSurface> CreateSurface(
      fml::scoped_nsobject<CALayer> ca_layer);

  std::shared_ptr<IOSExternalViewEmbedder> GetExternalViewEmbedder();

 private:
  std::shared_ptr<IOSExternalViewEmbedder> external_view_embedder_;
  std::shared_ptr<IOSContext> ios_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceFactory);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS__SURFACE_FACTORY_H_
