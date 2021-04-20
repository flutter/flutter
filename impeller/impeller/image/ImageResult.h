/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include "Size.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/memory/ref_counted.h"

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
              fml::RefPtr<const fml::Mapping> allocation);

  ImageResult(ImageResult&&);

  ImageResult& operator=(ImageResult&&);

  ~ImageResult();

  const geom::Size& size() const;

  bool wasSuccessful() const;

  Components components() const;

  const fml::RefPtr<const fml::Mapping>& allocation() const;

 private:
  bool _success;
  geom::Size _size;
  Components _components;
  fml::RefPtr<const fml::Mapping> _allocation;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageResult);
};

}  // namespace image
}  // namespace rl
