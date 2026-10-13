// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string_view>

#include "flutter/common/settings.h"
#include "flutter/common/switch_defs.h"
#include "flutter/fml/command_line.h"

#ifndef FLUTTER_COMMON_SWITCHES_H_
#define FLUTTER_COMMON_SWITCHES_H_

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Prints every engine flag and its help text to stderr.
///
void PrintSwitchUsage();

const std::string_view FlagForSwitch(Switch swtch);

Settings SettingsFromCommandLine(
    const fml::CommandLine& command_line,
    bool require_merged_platform_ui_thread = false);

}  // namespace flutter

#endif  // FLUTTER_COMMON_SWITCHES_H_
