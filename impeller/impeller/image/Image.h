// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "ImageResult.h"
#include "Size.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

namespace rl {
namespace image {

class ImageSource;

class Image {
 public:
  Image(std::shared_ptr<const fml::Mapping> sourceAllocation);

  ~Image();

  ImageResult Decode() const;

  bool IsValid() const;

 private:
  std::shared_ptr<const fml::Mapping> source_;
};

}  // namespace image
}  // namespace rl
