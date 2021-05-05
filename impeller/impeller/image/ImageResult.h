// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "Size.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

namespace rl {
namespace image {

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

  ImageResult(geom::Size size,
              Components components,
              std::shared_ptr<const fml::Mapping> allocation);

  ~ImageResult();

  const geom::Size& size() const;

  bool wasSuccessful() const;

  Components components() const;

  const std::shared_ptr<const fml::Mapping>& allocation() const;

 private:
  bool _success = false;
  geom::Size _size;
  Components _components = Components::Invalid;
  std::shared_ptr<const fml::Mapping> _allocation;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageResult);
};

}  // namespace image
}  // namespace rl
