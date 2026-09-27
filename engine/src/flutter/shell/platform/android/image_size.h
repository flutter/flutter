// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_SIZE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_SIZE_H_
#include <cstdint>
#include <optional>
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSize.h"
namespace flutter {
// A HardwareBuffer can be larger than the Image it contains. Exclude allocation
// padding, without interpreting Image crop or rotation metadata. Normalize
// because GL wrappers can describe the same allocation in different coordinate
// units.
inline SkRect NormalizeImageBounds(std::optional<SkISize> image_size,
                                   uint32_t buffer_width,
                                   uint32_t buffer_height) {
  if (!image_size || image_size->isEmpty() || buffer_width == 0 ||
      buffer_height == 0 ||
      static_cast<uint32_t>(image_size->width()) > buffer_width ||
      static_cast<uint32_t>(image_size->height()) > buffer_height) {
    return SkRect::MakeWH(1, 1);
  }
  return SkRect::MakeWH(
      static_cast<float>(image_size->width()) / buffer_width,
      static_cast<float>(image_size->height()) / buffer_height);
}
}  // namespace flutter
#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_SIZE_H_
