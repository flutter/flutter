/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include <Core/Allocation.h>
#include <Core/Macros.h>
#include "ImageSource.h"

namespace rl {
namespace image {

class DataImageSource : public ImageSource {
 public:
  DataImageSource();

  DataImageSource(core::Allocation allocation);

  bool serialize(core::Message& message) const override;

  bool deserialize(core::Message& message, core::Namespace* ns) override;

 private:
  core::Allocation _allocation;

  ImageSource::Type type() const override;

  uint8_t* sourceData() const override;

  size_t sourceDataSize() const override;

  void onPrepareForUse() override;

  void onDoneUsing() override;

  RL_DISALLOW_COPY_AND_ASSIGN(DataImageSource);
};

}  // namespace image
}  // namespace rl
