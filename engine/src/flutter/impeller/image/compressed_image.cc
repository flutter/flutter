// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/image/compressed_image.h"

#include <stb_image.h>

namespace impeller {

CompressedImage::CompressedImage(
    std::shared_ptr<const fml::Mapping> sourceAllocation)
    : source_(std::move(sourceAllocation)) {}

CompressedImage::~CompressedImage() = default;

Image CompressedImage::Decode() const {
  if (!source_) {
    return {};
  }

  int width = 0;
  int height = 0;
  int comps = 0;

  stbi_uc* decoded =
      ::stbi_load_from_memory(source_->GetMapping(),  // Source Data
                              source_->GetSize(),     // Source Data Size
                              &width,                 // Out: Width
                              &height,                // Out: Height
                              &comps,                 // Out: Components
                              STBI_default);

  if (decoded == nullptr) {
    FML_LOG(ERROR) << "Could not decode image from host memory.";
    return {};
  }

  auto dest_allocation = std::make_shared<const fml::NonOwnedMapping>(
      decoded,                                   // bytes
      width * height * comps * sizeof(stbi_uc),  // byte size
      [](const uint8_t* data, size_t size) {
        ::stbi_image_free(const_cast<uint8_t*>(data));
      }  // release proc
  );

  /*
   *  Make sure we got a valid component set.
   */
  auto components = Image::Components::Invalid;

  switch (comps) {
    case STBI_grey:
      components = Image::Components::Grey;
      break;
    case STBI_grey_alpha:
      components = Image::Components::GreyAlpha;
      break;
    case STBI_rgb:
      components = Image::Components::RGB;
      break;
    case STBI_rgb_alpha:
      components = Image::Components::RGBA;
      break;
    default:
      components = Image::Components::Invalid;
      break;
  }

  if (components == Image::Components::Invalid) {
    FML_LOG(ERROR) << "Could not detect image components when decoding.";
    return {};
  }

  return Image{
      ISize{width, height},       // size
      components,                 // components
      std::move(dest_allocation)  // allocation
  };
}

bool CompressedImage::IsValid() const {
  return static_cast<bool>(source_);
}

}  // namespace impeller
