// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

#include "impeller/base/config.h"

namespace impeller {

IMPELLER_PRINTF_FORMAT(1, 2)
std::string SPrintF(const char* format, ...);

}  // namespace impeller
