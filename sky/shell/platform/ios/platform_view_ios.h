// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
#define SKY_SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_

#include <memory>

#include "base/mac/scoped_nsobject.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "sky/shell/platform_view.h"

@class CAEAGLLayer;

namespace sky {
namespace shell {

class IOSGLContext;

class PlatformViewIOS : public PlatformView {
 public:
  explicit PlatformViewIOS(CAEAGLLayer* layer);

  ~PlatformViewIOS() override;

  ftl::WeakPtr<sky::shell::PlatformView> GetWeakViewPtr() override;

  uint64_t DefaultFramebuffer() const override;

  bool ContextMakeCurrent() override;

  bool ResourceContextMakeCurrent() override;

  bool SwapBuffers() override;

 private:
  std::unique_ptr<IOSGLContext> context_;
  ftl::WeakPtrFactory<PlatformViewIOS> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformViewIOS);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
