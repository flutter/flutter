/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "DataImageSource.h"
#include <Core/Message.h>

namespace rl {
namespace image {

DataImageSource::DataImageSource() {}

DataImageSource::DataImageSource(core::Allocation allocation)
    : _allocation(std::move(allocation)) {}

uint8_t* DataImageSource::sourceData() const {
  return _allocation.data();
}

size_t DataImageSource::sourceDataSize() const {
  return _allocation.size();
}

void DataImageSource::onPrepareForUse() {
  /*
   *  Nothing to do since we already have an explicit allocation.
   */
}

void DataImageSource::onDoneUsing() {
  /*
   *  Nothing to do since we have an explicit allocate and we may need to be
   *  prepared again.
   */
}

bool DataImageSource::serialize(core::Message& message) const {
  return message.encode(_allocation);
}

bool DataImageSource::deserialize(core::Message& message, core::Namespace* ns) {
  return message.decode(_allocation, ns);
}

ImageSource::Type DataImageSource::type() const {
  return ImageSource::Type::Data;
}

}  // namespace image
}  // namespace rl
