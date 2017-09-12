// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/testing/platform_view_test.h"

#include "flutter/shell/common/null_rasterizer.h"
#include "flutter/shell/common/shell.h"

namespace shell {

PlatformViewTest::PlatformViewTest()
    : PlatformView(std::unique_ptr<Rasterizer>(new NullRasterizer())) {}

void PlatformViewTest::Attach() {
  CreateEngine();
  PostAddToShellTask();
}

PlatformViewTest::~PlatformViewTest() = default;

bool PlatformViewTest::ResourceContextMakeCurrent() {
  return false;
}

void PlatformViewTest::RunFromSource(const std::string& assets_directory,
                                     const std::string& main,
                                     const std::string& packages) {}

}  // namespace shell
