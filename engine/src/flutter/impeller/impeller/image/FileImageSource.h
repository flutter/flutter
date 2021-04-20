/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include <Core/FileMapping.h>
#include <Core/Macros.h>
#include "ImageSource.h"

namespace rl {
namespace image {

class FileImageSource : public ImageSource {
 public:
  FileImageSource();

  FileImageSource(core::FileHandle fileHandle);

  bool serialize(core::Message& message) const override;

  bool deserialize(core::Message& message, core::Namespace* ns) override;

 private:
  std::shared_ptr<core::FileHandle> _handle;
  std::unique_ptr<core::FileMapping> _mapping;

  ImageSource::Type type() const override;

  uint8_t* sourceData() const override;

  size_t sourceDataSize() const override;

  void onPrepareForUse() override;

  void onDoneUsing() override;

  RL_DISALLOW_COPY_AND_ASSIGN(FileImageSource);
};

}  // namespace image
}  // namespace rl
