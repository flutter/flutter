// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MAC_PLATFORM_MAC_H_
#define SKY_SHELL_PLATFORM_MAC_PLATFORM_MAC_H_

#include "sky/services/engine/sky_engine.mojom.h"

namespace sky {
namespace shell {

void PlatformMacMain(int argc, const char* argv[], std::string icu_data_path);

bool AttemptLaunchFromCommandLineSwitches(sky::SkyEnginePtr& engine);

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MAC_PLATFORM_MAC_H_
