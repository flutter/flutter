/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "ImageSource.h"
#include "DataImageSource.h"
#include "FileImageSource.h"

namespace rl {
namespace image {

std::unique_ptr<ImageSource> ImageSource::Create(core::Allocation allocation) {
  return std::make_unique<DataImageSource>(std::move(allocation));
}

std::unique_ptr<ImageSource> ImageSource::Create(core::FileHandle fileHandle) {
  return std::make_unique<FileImageSource>(std::move(fileHandle));
}

std::shared_ptr<ImageSource> ImageSource::ImageSourceForType(Type type) {
  switch (type) {
    case Type::File:
      return std::make_shared<FileImageSource>();
    case Type::Data:
      return std::make_shared<DataImageSource>();
    default:
      return nullptr;
  }

  return nullptr;
}

ImageSource::ImageSource() = default;

ImageSource::~ImageSource() = default;

void ImageSource::prepareForUse() {
  if (_prepared) {
    return;
  }

  onPrepareForUse();

  _prepared = true;
}

void ImageSource::doneUsing() {
  if (!_prepared) {
    return;
  }

  onDoneUsing();

  _prepared = false;
}

}  // namespace image
}  // namespace rl
