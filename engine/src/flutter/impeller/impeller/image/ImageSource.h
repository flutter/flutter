/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include <Core/Allocation.h>
#include <Core/File.h>
#include <Core/Macros.h>

namespace rl {
namespace image {

class ImageSource : public core::MessageSerializable {
 public:
  enum class Type : uint8_t {
    Unknown,
    File,
    Data,
  };

  static std::unique_ptr<ImageSource> Create(core::Allocation allocation);

  static std::unique_ptr<ImageSource> Create(core::FileHandle fileHandle);

  static std::shared_ptr<ImageSource> ImageSourceForType(Type type);

  ImageSource();

  virtual ~ImageSource();

  void prepareForUse();

  void doneUsing();

 protected:
  bool _prepared = false;

  friend class Image;

  virtual Type type() const = 0;

  virtual uint8_t* sourceData() const = 0;

  virtual size_t sourceDataSize() const = 0;

  virtual void onPrepareForUse() = 0;

  virtual void onDoneUsing() = 0;
};

}  // namespace image
}  // namespace rl
