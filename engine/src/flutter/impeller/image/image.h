// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "image_result.h"
#include "impeller/geometry/size.h"

namespace impeller {

class ImageSource;

class Image {
 public:
  Image(std::shared_ptr<const fml::Mapping> sourceAllocation);

  ~Image();

  [[nodiscard]] ImageResult Decode() const;

  bool IsValid() const;

 private:
  std::shared_ptr<const fml::Mapping> source_;
};

}  // namespace impeller
