// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/platform_impl.h"

#include "sky/shell/shell.h"

namespace sky {
namespace shell {

PlatformImpl::PlatformImpl() {
}

PlatformImpl::~PlatformImpl() {
}

std::string PlatformImpl::defaultLocale() {
  return "en-US";
}

base::SingleThreadTaskRunner* PlatformImpl::GetUITaskRunner() {
  return Shell::Shared().ui_task_runner();
}

base::SingleThreadTaskRunner* PlatformImpl::GetIOTaskRunner() {
  return Shell::Shared().io_task_runner();
}

}  // namespace shell
}  // namespace sky
