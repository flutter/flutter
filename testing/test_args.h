// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/command_line.h"

namespace flutter {
namespace testing {

const fml::CommandLine& GetArgsForProcess();

void SetArgsForProcess(int argc, char** argv);

}  // namespace testing
}  // namespace flutter
