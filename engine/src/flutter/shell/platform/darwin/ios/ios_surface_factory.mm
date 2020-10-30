// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_surface_factory.h"

#import "flutter/shell/platform/darwin/ios/ios_context.h"
#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"

namespace flutter {

IOSSurfaceFactory::IOSSurfaceFactory(std::shared_ptr<IOSContext> ios_context)
    : ios_context_(ios_context) {}

std::shared_ptr<IOSSurfaceFactory> IOSSurfaceFactory::Create(IOSRenderingAPI rendering_api) {
  std::shared_ptr<IOSContext> ios_context = IOSContext::Create(rendering_api);
  return std::make_shared<IOSSurfaceFactory>(ios_context);
}

IOSSurfaceFactory::~IOSSurfaceFactory() = default;

void IOSSurfaceFactory::SetPlatformViewsController(
    const std::shared_ptr<FlutterPlatformViewsController>& platform_views_controller) {
  external_view_embedder_.reset(
      new IOSExternalViewEmbedder(platform_views_controller, ios_context_));
}

std::shared_ptr<IOSExternalViewEmbedder> IOSSurfaceFactory::GetExternalViewEmbedder() {
  return external_view_embedder_;
}

std::unique_ptr<IOSSurface> IOSSurfaceFactory::CreateSurface(
    fml::scoped_nsobject<CALayer> ca_layer) {
  return flutter::IOSSurface::Create(ios_context_, ca_layer, external_view_embedder_);
}

}  // namespace flutter
