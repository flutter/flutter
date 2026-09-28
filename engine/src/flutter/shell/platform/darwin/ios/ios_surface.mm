// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_surface.h"

#include <memory>

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_metal_impeller.h"
#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

FLUTTER_ASSERT_ARC

namespace flutter {

std::unique_ptr<IOSSurface> IOSSurface::Create(const std::shared_ptr<IOSContext>& context,
                                               CALayer* layer) {
  FML_DCHECK(layer);
  FML_DCHECK(context);

  if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
    if ([layer isKindOfClass:[CAMetalLayer class]]) {
      return std::make_unique<IOSSurfaceMetalImpeller>(
          static_cast<CAMetalLayer*>(layer),  // Metal layer
          context                             // context
      );
    }
  }
  // The layer MUST be a CAMetalLayer or FlutterMetalLayer, which overrides
  // isKindOfClass to return true for the above check. Anything else means the
  // rendering surface was misconfigured.
  FML_CHECK(false) << "Expected a Metal-backed layer for iOS rendering.";
  FML_UNREACHABLE();
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
