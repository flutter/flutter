/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include "Size.h"

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
              core::Allocation allocation);

  ImageResult(ImageResult&&);

  ImageResult& operator=(ImageResult&&);

  ~ImageResult();

  const geom::Size& size() const;

  bool wasSuccessful() const;

  Components components() const;

  const core::Allocation& allocation() const;

 private:
  bool _success;
  geom::Size _size;
  Components _components;
  core::Allocation _allocation;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageResult);
};

}  // namespace image
}  // namespace rl
