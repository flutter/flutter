// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/image/image.h"

#include <limits>

#include "flutter/fml/mapping.h"
#include "impeller/base/allocation.h"

namespace impeller {

Image::Image() = default;

Image::Image(ISize size,
             Format format,
             std::shared_ptr<const fml::Mapping> allocation)
    : size_(size), format_(format), allocation_(std::move(allocation)) {
  if (!allocation_ || !size.IsPositive() || format_ == Format::Invalid) {
    return;
  }
  is_valid_ = true;
}

Image::~Image() = default;

bool Image::IsValid() const {
  return is_valid_;
}

const ISize& Image::GetSize() const {
  return size_;
}

Image::Format Image::GetFormat() const {
  return format_;
}

const std::shared_ptr<const fml::Mapping>& Image::GetAllocation() const {
  return allocation_;
}

static size_t GetBytesPerPixel(Image::Format format) {
  switch (format) {
    case Image::Format::Invalid:
      return 0u;
    case Image::Format::Grey:
      return 1u;
    case Image::Format::GreyAlpha:
      return 1u;
    case Image::Format::RGB:
      return 3u;
    case Image::Format::RGBA:
      return 4;
  }
  return 0u;
}

Image Image::ConvertToRGBA() const {
  if (!is_valid_) {
    return {};
  }

  if (format_ == Format::RGBA) {
    return Image{size_, format_, allocation_};
  }

  const auto bpp = GetBytesPerPixel(format_);
  const auto source_byte_size = size_.Area() * bpp;
  if (allocation_->GetSize() < source_byte_size) {
    return {};
  }

  auto rgba_allocation = std::make_shared<Allocation>();
  if (!rgba_allocation->Truncate(size_.Area() * 4u, false)) {
    return {};
  }

  const uint8_t* source = allocation_->GetMapping();
  uint8_t* dest = rgba_allocation->GetBuffer();

  for (size_t i = 0, j = 0; i < source_byte_size; i += bpp, j += 4u) {
    switch (format_) {
      case Image::Format::Grey:
        dest[j + 0] = source[i];
        dest[j + 1] = source[i];
        dest[j + 2] = source[i];
        dest[j + 3] = std::numeric_limits<uint8_t>::max();
        break;
      case Image::Format::GreyAlpha:
        dest[j + 0] = std::numeric_limits<uint8_t>::max();
        dest[j + 1] = std::numeric_limits<uint8_t>::max();
        dest[j + 2] = std::numeric_limits<uint8_t>::max();
        dest[j + 3] = source[i];
        break;
      case Image::Format::RGB:
        dest[j + 0] = source[i + 0];
        dest[j + 1] = source[i + 1];
        dest[j + 2] = source[i + 2];
        dest[j + 3] = std::numeric_limits<uint8_t>::max();
        break;
      case Image::Format::Invalid:
      case Image::Format::RGBA:
        // Should never happen. The necessary checks have already been
        // performed.
        FML_CHECK(false);
        break;
    }
  }

  return Image{
      size_, Format::RGBA,
      std::make_shared<fml::NonOwnedMapping>(
          rgba_allocation->GetBuffer(),      //
          rgba_allocation->GetLength(),      //
          [rgba_allocation](auto, auto) {})  //
  };
}

}  // namespace impeller
