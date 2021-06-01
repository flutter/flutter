// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstddef>

#include "flutter/fml/macros.h"

namespace impeller {

struct Range {
  size_t offset = 0;
  size_t length = 0;
};

}  // namespace impeller
