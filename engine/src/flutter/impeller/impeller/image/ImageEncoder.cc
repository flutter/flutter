/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include <Image/ImageEncoder.h>
#include <stb_image_write.h>

namespace rl {
namespace image {

ImageEncoder::ImageEncoder(Type type, core::FileHandle handle)
    : _isReady(false), _type(type), _adapter(std::move(handle)) {
  if (!_adapter.isValid()) {
    return;
  }

  _isReady = true;
}

ImageEncoder::~ImageEncoder() = default;

bool ImageEncoder::isReady() const {
  return _isReady;
}

bool ImageEncoder::encode(ImageResult image) {
  if (!_isReady) {
    return false;
  }

  if (!image.wasSuccessful()) {
    return false;
  }

  switch (_type) {
    case Type::PNG:
      return encodePNG(std::move(image));
  }

  return false;
}

int ComponentsToSize(ImageResult::Components components) {
  switch (components) {
    case ImageResult::Components::Invalid:
      return 0;
    case ImageResult::Components::Grey:
      return 1;
    case ImageResult::Components::GreyAlpha:
      return 2;
    case ImageResult::Components::RGB:
      return 3;
    case ImageResult::Components::RGBA:
      return 4;
  }

  return 0;
}

bool ImageEncoder::encodePNG(ImageResult image) {
  auto size = image.size();

  int componentSize = ComponentsToSize(image.components());

  auto callback = [](void* context, void* data, int size) {
    reinterpret_cast<ImageEncoder*>(context)->write(
        reinterpret_cast<const uint8_t*>(data), size);
  };

  return stbi_write_png_to_func(callback,                   //
                                this,                       //
                                size.width,                 //
                                size.height,                //
                                componentSize,              //
                                image.allocation().data(),  //
                                componentSize               //
                                ) == 1;
}

void ImageEncoder::write(const uint8_t* data, size_t size) {
  RL_UNUSED(_adapter.write(data, size));
}

}  // namespace image
}  // namespace rl
