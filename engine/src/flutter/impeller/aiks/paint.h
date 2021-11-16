// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents.h"
#include "impeller/geometry/color.h"

namespace impeller {

struct Paint {
  enum class Style {
    kFill,
    kStroke,
  };

  Color color;
  Scalar stroke_width = 0.0;
  Style style = Style::kFill;

  std::shared_ptr<Contents> CreateContentsForEntity() const;
};

}  // namespace impeller
