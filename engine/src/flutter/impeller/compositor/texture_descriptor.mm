// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/texture_descriptor.h"

namespace impeller {

std::optional<PixelFormat> FormatForImageResultComponents(
    Image::Components comp) {
  switch (comp) {
    case Image::Components::Invalid:
      return std::nullopt;
    case Image::Components::Grey:
      return std::nullopt;
    case Image::Components::GreyAlpha:
      return std::nullopt;
    case Image::Components::RGB:
      return std::nullopt;
    case Image::Components::RGBA:
      return PixelFormat::kPixelFormat_R8G8B8A8_UNormInt;
  }
  return std::nullopt;
}

std::optional<TextureDescriptor> TextureDescriptor::MakeFromImageResult(
    const Image& result) {
  if (!result.IsValid()) {
    return std::nullopt;
  }

  const auto pixel_format =
      FormatForImageResultComponents(result.GetComponents());
  if (!pixel_format.has_value()) {
    FML_DLOG(ERROR) << "Unknown image format.";
    return std::nullopt;
  }

  TextureDescriptor desc;
  desc.format = pixel_format.value();
  desc.size = result.GetSize();
  desc.mip_count = result.GetSize().MipCount();

  if (!desc.IsValid()) {
    return std::nullopt;
  }

  return desc;
}

}  // namespace impeller
