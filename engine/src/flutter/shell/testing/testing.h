// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_TESTING_TESTING_H_
#define SHELL_TESTING_TESTING_H_

#include "lib/ftl/command_line.h"

namespace shell {

bool InitForTesting(const ftl::CommandLine& command_line);

}  // namespace shell

#endif  // SHELL_TESTING_TESTING_H_
