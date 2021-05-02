/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

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

  ImageResult decode() const;

  bool isValid() const;

 private:
  std::shared_ptr<const fml::Mapping> _source;
};

}  // namespace image
}  // namespace rl
