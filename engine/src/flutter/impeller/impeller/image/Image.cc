/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include <Core/Message.h>
#include <Image/Image.h>
#include <stb_image.h>
#include "ImageSource.h"

namespace rl {
namespace image {

Image::Image() = default;

Image::Image(core::Allocation sourceAllocation)
    : _source(ImageSource::Create(std::move(sourceAllocation))) {}

Image::Image(core::FileHandle sourceFile)
    : _source(ImageSource::Create(std::move(sourceFile))) {}

Image::~Image() = default;

bool Image::serialize(core::Message& message) const {
  if (_source == nullptr) {
    return false;
  }

  /*
   *  Encode the type.
   */
  RL_RETURN_IF_FALSE(message.encode(_source->type()));

  /*
   *  Encode the image source.
   */
  RL_RETURN_IF_FALSE(_source->serialize(message));

  return true;
}

bool Image::deserialize(core::Message& message, core::Namespace* ns) {
  auto type = ImageSource::Type::Unknown;

  /*
   *  Decode the type.
   */
  RL_RETURN_IF_FALSE(message.decode(type, ns))

  /*
   *  Create and decode the image source of that type.
   */
  auto source = ImageSource::ImageSourceForType(type);
  if (source == nullptr) {
    return false;
  }
  RL_RETURN_IF_FALSE(source->deserialize(message, ns));
  _source = source;

  return true;
}

ImageResult Image::decode() const {
  if (_source == nullptr) {
    return {};
  }

  _source->prepareForUse();

  if (_source->sourceDataSize() == 0) {
    RL_LOG("Source data for image decoding was zero sized.");
    return {};
  }

  int width = 0;
  int height = 0;
  int comps = 0;

  stbi_uc* decoded =
      stbi_load_from_memory(_source->sourceData(),      // Source Data
                            _source->sourceDataSize(),  // Source Data Size
                            &width,                     // Out: Width
                            &height,                    // Out: Height
                            &comps,                     // Out: Components
                            STBI_default);

  auto destinationAllocation =
      core::Allocation{decoded, width * height * comps * sizeof(stbi_uc)};

  /*
   *  If either the decoded allocation is null or the size works out to be zero,
   *  the allocation will mark itself as not ready and we know that the decode
   *  job failed.
   */

  if (!destinationAllocation.isReady()) {
    RL_LOG("Destination allocation for image decoding was null.");
    return {};
  }

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
    RL_LOG("Could not detect image components when decoding.");
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
  return _source != nullptr;
}

std::size_t Image::Hash::operator()(const Image& key) const {
  return std::hash<decltype(key._source)>()(key._source);
}

bool Image::Equal::operator()(const Image& lhs, const Image& rhs) const {
  return lhs._source == rhs._source;
}

}  // namespace image
}  // namespace rl
