// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string_view>

#include "flutter/common/settings.h"
#include "flutter/fml/command_line.h"
#include "flutter/shell/common/switch_defs.h"

#ifndef FLUTTER_SHELL_COMMON_SWITCHES_H_
#define FLUTTER_SHELL_COMMON_SWITCHES_H_

namespace flutter {

void PrintUsage(const std::string& executable_name);

const std::string_view FlagForSwitch(Switch swtch);

Settings SettingsFromCommandLine(
    const fml::CommandLine& command_line,
    bool require_merged_platform_ui_thread = false);

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SWITCHES_H_
