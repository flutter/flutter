// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_RENDER_CONTEXT_H_
#define FLUTTER_SKWASM_RENDER_CONTEXT_H_

#include <memory>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/skwasm/helpers.h"

namespace Skwasm {
class RenderContext {
 public:
  static std::unique_ptr<RenderContext> Make(int sample_count, int stencil);

  virtual ~RenderContext() = default;
  virtual void RenderPicture(
      const sk_sp<flutter::DisplayList> display_list) = 0;
  virtual void RenderImage(flutter::DlImage* image, ImageByteFormat format) = 0;
  virtual void Resize(int width, int height) = 0;
  virtual void SetResourceCacheLimit(int bytes) = 0;
};
}  // namespace Skwasm

#endif  // FLUTTER_SKWASM_RENDER_CONTEXT_H_
