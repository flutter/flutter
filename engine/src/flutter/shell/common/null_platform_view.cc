// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/null_platform_view.h"

#include "flutter/shell/common/null_rasterizer.h"
#include "flutter/shell/common/shell.h"

namespace shell {

NullPlatformView::NullPlatformView()
    : PlatformView(std::make_unique<NullRasterizer>()), weak_factory_(this) {}

void NullPlatformView::Attach() {
  CreateEngine();
}

NullPlatformView::~NullPlatformView() = default;

fxl::WeakPtr<NullPlatformView> NullPlatformView::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

bool NullPlatformView::ResourceContextMakeCurrent() {
  return false;
}

// Hot-reload of the null platform view is not supported.
void NullPlatformView::RunFromSource(const std::string& assets_directory,
                                     const std::string& main,
                                     const std::string& packages) {}

}  // namespace shell
