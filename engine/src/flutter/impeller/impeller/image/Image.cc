/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Image.h"
#include <stb_image.h>

namespace rl {
namespace image {

Image::Image(std::shared_ptr<const fml::Mapping> sourceAllocation)
    : _source(std::move(sourceAllocation)) {}

Image::~Image() = default;

ImageResult Image::decode() const {
  if (!_source) {
    return {};
  }

  int width = 0;
  int height = 0;
  int comps = 0;

  stbi_uc* decoded =
      stbi_load_from_memory(_source->GetMapping(),  // Source Data
                            _source->GetSize(),     // Source Data Size
                            &width,                 // Out: Width
                            &height,                // Out: Height
                            &comps,                 // Out: Components
                            STBI_default);

  if (decoded == nullptr) {
    FML_LOG(ERROR) << "Could not decode image from host memory.";
    return {};
  }

  auto destinationAllocation = std::make_shared<const fml::NonOwnedMapping>(
      decoded,                                   // bytes
      width * height * comps * sizeof(stbi_uc),  // byte size
      [](const uint8_t* data, size_t size) {
        ::stbi_image_free(const_cast<uint8_t*>(data));
      }  // release proc
  );

  /*
   *  Make sure we got a valid component set.
   */
  auto components = ImageResult::Components::Invalid;

  switch (comps) {
    case STBI_grey:
      components = ImageResult::Components::Grey;
      break;
    case STBI_grey_alpha:
      components = ImageResult::Components::GreyAlpha;
      break;
    case STBI_rgb:
      components = ImageResult::Components::RGB;
      break;
    case STBI_rgb_alpha:
      components = ImageResult::Components::RGBA;
      break;
    default:
      components = ImageResult::Components::Invalid;
      break;
  }

  if (components == ImageResult::Components::Invalid) {
    FML_LOG(ERROR) << "Could not detect image components when decoding.";
    return {};
  }

  return ImageResult{
      geom::Size{static_cast<double>(width),
                 static_cast<double>(height)},  // size
      components,                               // components
      std::move(destinationAllocation)          // allocation
  };
}

bool Image::isValid() const {
  return static_cast<bool>(_source);
}

}  // namespace image
}  // namespace rl
