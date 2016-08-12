// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/ui/platform_impl.h"

#include "flutter/sky/shell/shell.h"

namespace sky {
namespace shell {

PlatformImpl::PlatformImpl() {}

PlatformImpl::~PlatformImpl() {}

std::string PlatformImpl::defaultLocale() {
  return "en-US";
}

}  // namespace shell
}  // namespace sky
