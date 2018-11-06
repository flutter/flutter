// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/surface.h"

namespace shell {

// The name of the Info.plist flag to enable the embedded iOS views preview.
const char* const kEmbeddedViewsPreview = "io.flutter_embedded_views_preview";

class IOSSurface {
 public:
  IOSSurface(FlutterPlatformViewsController* platform_views_controller);

  virtual ~IOSSurface();

  virtual bool IsValid() const = 0;

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual void UpdateStorageSizeIfNecessary() = 0;

  virtual std::unique_ptr<Surface> CreateGPUSurface() = 0;

 protected:
  FlutterPlatformViewsController* GetPlatformViewsController();

 private:
  FlutterPlatformViewsController* platform_views_controller_;

 public:
  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurface);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
