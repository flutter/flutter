// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SWITCHES_H_
#define FLUTTER_SHELL_COMMON_SWITCHES_H_

#include <string>

// The switches and SettingsFromCommandLine live in //flutter/common, so that
// embedders can build Settings without depending on //flutter/shell/common.
#include "flutter/common/switches.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Prints the executable name, the engine, Skia and Dart versions,
///             and every engine flag with its help text to stderr.
///
void PrintUsage(const std::string& executable_name);

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SWITCHES_H_
