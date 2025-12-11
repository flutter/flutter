// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_WEB_UI_SKWASM_RENDER_CONTEXT_H_
#define FLUTTER_LIB_WEB_UI_SKWASM_RENDER_CONTEXT_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"
#include "helpers.h"

#include <memory>

namespace Skwasm {
class RenderContext {
 public:
  static std::unique_ptr<RenderContext> Make(int sampleCount, int stencil);

  virtual ~RenderContext() = default;
  virtual void renderPicture(const sk_sp<flutter::DisplayList> displayList) = 0;
  virtual void renderImage(flutter::DlImage* image, ImageByteFormat format) = 0;
  virtual void resize(int width, int height) = 0;
  virtual void setResourceCacheLimit(int bytes) = 0;
};
}  // namespace Skwasm

#endif  // FLUTTER_LIB_WEB_UI_SKWASM_RENDER_CONTEXT_H_
