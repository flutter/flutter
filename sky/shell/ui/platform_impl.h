// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_PLATFORM_IMPL_H_
#define SKY_SHELL_UI_PLATFORM_IMPL_H_

#include "lib/ftl/macros.h"
#include "sky/engine/public/platform/Platform.h"

namespace sky {
namespace shell {

class PlatformImpl : public blink::Platform {
 public:
  explicit PlatformImpl();
  ~PlatformImpl() override;

  // blink::Platform methods:
  std::string defaultLocale() override;

  ftl::TaskRunner* GetUITaskRunner() override;
  ftl::TaskRunner* GetIOTaskRunner() override;

 private:
  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_PLATFORM_IMPL_H_
