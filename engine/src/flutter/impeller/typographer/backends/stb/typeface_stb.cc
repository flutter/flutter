// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/stb/typeface_stb.h"

#include <cstring>

#include "flutter/fml/logging.h"

namespace impeller {

// Instantiate a typeface based on a .ttf or other font file
TypefaceSTB::TypefaceSTB(std::unique_ptr<fml::Mapping> typeface_mapping)
    : typeface_mapping_(std::move(typeface_mapping)),
      font_info_(std::make_unique<stbtt_fontinfo>()) {
  // We need an "offset" into the ttf file
  auto offset = stbtt_GetFontOffsetForIndex(typeface_mapping_->GetMapping(), 0);
  if (stbtt_InitFont(font_info_.get(), typeface_mapping_->GetMapping(),
                     offset) == 0) {
    FML_LOG(ERROR) << "Failed to initialize stb font from binary data.";
  } else {
    is_valid_ = true;
  }
}

TypefaceSTB::~TypefaceSTB() = default;

bool TypefaceSTB::IsValid() const {
  return is_valid_;
}

std::size_t TypefaceSTB::GetHash() const {
  if (!IsValid()) {
    return 0u;
  }
  return reinterpret_cast<size_t>(typeface_mapping_->GetMapping());
}

bool TypefaceSTB::IsEqual(const Typeface& other) const {
  auto stb_other = reinterpret_cast<const TypefaceSTB*>(&other);
  return stb_other->GetHash() == GetHash();
}

const uint8_t* TypefaceSTB::GetTypefaceFile() const {
  return typeface_mapping_->GetMapping();
}

const stbtt_fontinfo* TypefaceSTB::GetFontInfo() const {
  return font_info_.get();
}

}  // namespace impeller
