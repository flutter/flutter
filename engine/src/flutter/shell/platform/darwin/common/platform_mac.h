// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_MAC_PLATFORM_MAC_H_
#define SHELL_PLATFORM_MAC_PLATFORM_MAC_H_

#include "flutter/shell/common/engine.h"

namespace shell {

void PlatformMacMain(int argc, const char* argv[], std::string icu_data_path);

bool AttemptLaunchFromCommandLineSwitches(Engine* engine);

}  // namespace shell

#endif  // SHELL_PLATFORM_MAC_PLATFORM_MAC_H_
