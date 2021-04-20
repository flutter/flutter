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
  Image();

  Image(fml::RefPtr<const fml::Mapping> sourceAllocation);

  ~Image();

  ImageResult decode() const;

  bool isValid() const;

  struct Hash {
    std::size_t operator()(const Image& key) const;
  };

  struct Equal {
    bool operator()(const Image& lhs, const Image& rhs) const;
  };

 private:
  std::shared_ptr<ImageSource> _source;
};

}  // namespace image
}  // namespace rl
