// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_LINUX_PLATFORM_VIEW_LINUX_H_
#define SKY_SHELL_PLATFORM_LINUX_PLATFORM_VIEW_LINUX_H_

#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class PlatformViewLinux : public PlatformView {
 public:
  explicit PlatformViewLinux(const Config& config, SurfaceConfig surface_config);

  ~PlatformViewLinux() override;

  // sky::shell::PlatformView override
  base::WeakPtr<sky::shell::PlatformView> GetWeakViewPtr() override;

  // sky::shell::PlatformView override
  uint64_t DefaultFramebuffer() const override;

  // sky::shell::PlatformView override
  bool ContextMakeCurrent() override;

  // sky::shell::PlatformView override
  bool SwapBuffers() override;

 private:
  base::WeakPtrFactory<PlatformViewLinux> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(PlatformViewLinux);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_LINUX_PLATFORM_VIEW_LINUX_H_
