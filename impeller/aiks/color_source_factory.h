// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "impeller/entity/contents/color_source_contents.h"

namespace impeller {

class ColorSourceFactory {
 public:
  enum class ColorSourceType {
    kColor,
    kImage,
    kLinearGradient,
    kRadialGradient,
    kConicalGradient,
    kSweepGradient,
    kRuntimeEffect,
  };

  virtual ~ColorSourceFactory();

  virtual std::shared_ptr<ColorSourceContents> MakeContents() = 0;

  virtual ColorSourceType GetType() = 0;
};

}  // namespace impeller
