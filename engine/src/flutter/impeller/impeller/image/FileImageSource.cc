/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "FileImageSource.h"
#include <Core/Message.h>
#include <Core/RawAttachment.h>

namespace rl {
namespace image {

FileImageSource::FileImageSource() {}

FileImageSource::FileImageSource(core::FileHandle fileHandle)
    : _handle(std::make_shared<core::FileHandle>(std::move(fileHandle))) {}

uint8_t* FileImageSource::sourceData() const {
  return _mapping == nullptr ? nullptr : _mapping->mapping();
}

size_t FileImageSource::sourceDataSize() const {
  return _mapping == nullptr ? 0 : _mapping->size();
}

void FileImageSource::onPrepareForUse() {
  if (_handle == nullptr || !_handle->isValid()) {
    return;
  }

  _mapping = std::make_unique<core::FileMapping>(*_handle);
}

void FileImageSource::onDoneUsing() {
  _mapping = nullptr;
}

bool FileImageSource::serialize(core::Message& message) const {
  return message.encode(_handle);
}

bool FileImageSource::deserialize(core::Message& message, core::Namespace* ns) {
  core::RawAttachment attachment;

  if (!message.decode(attachment)) {
    return false;
  }

  _handle = std::make_shared<core::FileHandle>(std::move(attachment));

  /*
   *  Clear our old mapping if present so we can prepare for another use.
   */
  _mapping = nullptr;

  return true;
}

ImageSource::Type FileImageSource::type() const {
  return ImageSource::Type::File;
}

}  // namespace image
}  // namespace rl
