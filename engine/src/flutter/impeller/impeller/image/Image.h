/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include <Core/File.h>
#include <Core/MessageSerializable.h>
#include <Geometry/Size.h>
#include <Image/ImageResult.h>

namespace rl {
namespace image {

class ImageSource;

class Image : public core::MessageSerializable {
 public:
  Image();

  Image(core::Allocation sourceAllocation);

  Image(core::FileHandle sourceFile);

  ~Image();

  ImageResult decode() const;

  bool serialize(core::Message& message) const override;

  bool deserialize(core::Message& message, core::Namespace* ns) override;

  bool isValid() const;

  struct Hash {
    std::size_t operator()(const Image& key) const;
  };

  struct Equal {
    bool operator()(const Image& lhs, const Image& rhs) const;
  };

 private:
  std::shared_ptr<ImageSource> _source;
};

}  // namespace image
}  // namespace rl
