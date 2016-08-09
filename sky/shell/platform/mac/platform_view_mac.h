// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_
#define SKY_SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_

#include "base/mac/scoped_nsobject.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "flutter/sky/shell/platform_view.h"

@class NSOpenGLView;
@class NSOpenGLContext;

namespace sky {
namespace shell {

class PlatformViewMac : public PlatformView {
 public:
  PlatformViewMac(NSOpenGLView* gl_view);

  ~PlatformViewMac() override;

  ftl::WeakPtr<PlatformView> GetWeakViewPtr() override;

  uint64_t DefaultFramebuffer() const override;

  bool ContextMakeCurrent() override;

  bool ResourceContextMakeCurrent() override;

  bool SwapBuffers() override;

 private:
  base::scoped_nsobject<NSOpenGLView> opengl_view_;
  base::scoped_nsobject<NSOpenGLContext> resource_loading_context_;
  ftl::WeakPtrFactory<PlatformViewMac> weak_factory_;

  bool IsValid() const;

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformViewMac);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_
