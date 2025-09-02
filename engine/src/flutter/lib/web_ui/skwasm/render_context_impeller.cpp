// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "render_context.h"

using namespace Skwasm;
namespace {
class ImpellerRenderContext : public RenderContext {
 public:
  virtual void renderPicture(
      const sk_sp<flutter::DisplayList> displayList) override {}

  virtual void renderImage(SkImage* image, ImageByteFormat format) override {}

  virtual void resize(int width, int height) override {}

 private:
};
}  // namespace

std::unique_ptr<RenderContext> Skwasm::RenderContext::Make(int sampleCount,
                                                           int stencil) {
  return std::make_unique<ImpellerRenderContext>();
}
