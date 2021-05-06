// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "Size.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

namespace impeller {

class ImageResult {
 public:
  enum class Components {
    Invalid,
    Grey,
    GreyAlpha,
    RGB,
    RGBA,
  };

  ImageResult();

  ImageResult(Size size,
              Components components,
              std::shared_ptr<const fml::Mapping> allocation);

  ~ImageResult();

  const Size& GetSize() const;

  bool WasSuccessful() const;

  Components GetComponents() const;

  const std::shared_ptr<const fml::Mapping>& Allocation() const;

 private:
  bool success_ = false;
  Size size_;
  Components components_ = Components::Invalid;
  std::shared_ptr<const fml::Mapping> allocation_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageResult);
};

}  // namespace impeller
