// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/entity.h"

namespace impeller {

struct Picture {
  std::vector<Entity> entities;
};

}  // namespace impeller
