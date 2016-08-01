// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_TESTING_PLATFORM_VIEW_TEST_H_
#define SKY_SHELL_TESTING_PLATFORM_VIEW_TEST_H_

#include "base/macros.h"
#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class Shell;

class PlatformViewTest : public PlatformView {
 public:
  PlatformViewTest();

  ~PlatformViewTest();

  base::WeakPtr<sky::shell::PlatformView> GetWeakViewPtr() override;

  uint64_t DefaultFramebuffer() const override;

  bool ContextMakeCurrent() override;

  bool ResourceContextMakeCurrent() override;

  bool SwapBuffers() override;

 private:
  base::WeakPtrFactory<PlatformViewTest> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(PlatformViewTest);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_TESTING_PLATFORM_VIEW_TEST_H_
