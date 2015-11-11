// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_VIEW_MAC_H_
#define SKY_SHELL_PLATFORM_VIEW_MAC_H_

#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class PlatformViewMac : public PlatformView {
 public:
  explicit PlatformViewMac(const Config& config);
  ~PlatformViewMac() override;
  void SurfaceCreated(gfx::AcceleratedWidget widget);
  void SurfaceDestroyed(void);

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformViewMac);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_VIEW_MAC_H_
