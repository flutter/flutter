// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_VIEW_IOS_H_
#define SKY_SHELL_PLATFORM_VIEW_IOS_H_

#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class PlatformViewIOS : public PlatformView {
 public:
  explicit PlatformViewIOS(const Config& config);
  ~PlatformViewIOS() override;
  void SurfaceCreated(gfx::AcceleratedWidget widget);
  void SurfaceDestroyed(void);

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformViewIOS);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_VIEW_IOS_H_
