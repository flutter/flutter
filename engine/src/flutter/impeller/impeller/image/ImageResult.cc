/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "ImageResult.h"

namespace rl {
namespace image {

ImageResult::ImageResult(geom::Size size,
                         Components components,
                         fml::RefPtr<const fml::Mapping> allocation)
    : _success(true),
      _size(size),
      _components(components),
      _allocation(std::move(allocation)) {}

ImageResult::ImageResult() : _success(false) {}

ImageResult::ImageResult(ImageResult&&) = default;

ImageResult& ImageResult::operator=(ImageResult&& other) {
  _success = other._success;
  other._success = false;

  _size = other._size;
  other._size = geom::Size{};

  _components = other._components;
  other._components = Components::Invalid;

  _allocation = std::move(other._allocation);

  return *this;
}

bool ImageResult::wasSuccessful() const {
  return _success;
}

const geom::Size& ImageResult::size() const {
  return _size;
}

ImageResult::Components ImageResult::components() const {
  return _components;
}

const fml::RefPtr<const fml::Mapping>& ImageResult::allocation() const {
  return _allocation;
}

ImageResult::~ImageResult() = default;

}  // namespace image
}  // namespace rl
