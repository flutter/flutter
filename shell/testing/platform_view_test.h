// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_TESTING_PLATFORM_VIEW_TEST_H_
#define SHELL_TESTING_PLATFORM_VIEW_TEST_H_

#include "flutter/shell/common/platform_view.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"

namespace shell {

class Shell;

class PlatformViewTest : public PlatformView {
 public:
  PlatformViewTest();

  ~PlatformViewTest();

  ftl::WeakPtr<PlatformView> GetWeakViewPtr() override;

  bool ResourceContextMakeCurrent() override;

  void RunFromSource(const std::string& main,
                     const std::string& packages,
                     const std::string& assets_directory) override;

 private:
  ftl::WeakPtrFactory<PlatformViewTest> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformViewTest);
};

}  // namespace shell

#endif  // SHELL_TESTING_PLATFORM_VIEW_TEST_H_
