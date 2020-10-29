// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"

#include <memory>

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"

@class CALayer;

namespace flutter {

// Returns true if the app explicitly specified to use the iOS view embedding
// mechanism which is still in a release preview.
bool IsIosEmbeddedViewsPreviewEnabled();

class IOSSurface {
 public:
  static std::unique_ptr<IOSSurface> Create(
      std::shared_ptr<IOSContext> context,
      fml::scoped_nsobject<CALayer> layer,
      const std::shared_ptr<IOSExternalViewEmbedder>& external_view_embedder);

  std::shared_ptr<IOSContext> GetContext() const;

  std::shared_ptr<IOSExternalViewEmbedder> GetSurfaceExternalViewEmbedder() const;

  virtual ~IOSSurface();

  virtual bool IsValid() const = 0;

  virtual void UpdateStorageSizeIfNecessary() = 0;

  // Creates a GPU surface. If no GrDirectContext is supplied and the rendering mode
  // supports one, a new one will be created; otherwise, the software backend
  // will be used.
  //
  // If a GrDirectContext is supplied, creates a secondary surface.
  virtual std::unique_ptr<Surface> CreateGPUSurface(GrDirectContext* gr_context = nullptr) = 0;

 protected:
  IOSSurface(std::shared_ptr<IOSContext> ios_context,
             const std::shared_ptr<IOSExternalViewEmbedder>& external_view_embedder);

 private:
  std::shared_ptr<IOSContext> ios_context_;
  std::shared_ptr<IOSExternalViewEmbedder> external_view_embedder_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurface);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
