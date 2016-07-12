// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_
#define SKY_SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_

#include "base/memory/weak_ptr.h"
#include "sky/shell/platform_view.h"
#include "base/mac/scoped_nsobject.h"

@class NSOpenGLView;

namespace sky {
namespace shell {

class PlatformViewMac : public PlatformView {
 public:
  explicit PlatformViewMac(const Config& config, SurfaceConfig surface_config);

  ~PlatformViewMac() override;

  void SetOpenGLView(NSOpenGLView* view);

  base::WeakPtr<sky::shell::PlatformView> GetWeakViewPtr() override;

  uint64_t DefaultFramebuffer() const override;

  bool ContextMakeCurrent() override;

  bool SwapBuffers() override;

 private:
  base::scoped_nsobject<NSOpenGLView> opengl_view_;
  base::WeakPtrFactory<PlatformViewMac> weak_factory_;

  bool IsValid() const;

  DISALLOW_COPY_AND_ASSIGN(PlatformViewMac);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_
