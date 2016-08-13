// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_FRAMEBUFFER_SKIA_H_
#define FLUTTER_CONTENT_HANDLER_FRAMEBUFFER_SKIA_H_

#include "lib/ftl/macros.h"
#include "mojo/services/framebuffer/interfaces/framebuffer.mojom.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter_content_handler {

class FramebufferSkia {
 public:
  FramebufferSkia();
  ~FramebufferSkia();

  void Bind(mojo::InterfaceHandle<mojo::Framebuffer> framebuffer,
            mojo::FramebufferInfoPtr info);

  mojo::Framebuffer* get() const { return framebuffer_.get(); }
  const sk_sp<SkSurface>& surface() { return surface_; }

 private:
  mojo::FramebufferPtr framebuffer_;
  mojo::FramebufferInfoPtr info_;
  sk_sp<SkSurface> surface_;

  FTL_DISALLOW_COPY_AND_ASSIGN(FramebufferSkia);
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_FRAMEBUFFER_SKIA_H_
