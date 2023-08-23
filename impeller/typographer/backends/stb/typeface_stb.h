// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/backend_cast.h"
#include "impeller/typographer/typeface.h"
#include "third_party/stb/stb_truetype.h"

namespace impeller {

class TypefaceSTB final : public Typeface,
                          public BackendCast<TypefaceSTB, Typeface> {
 public:
  // "Typical" conversion from font Points to Pixels.
  // This assumes a constant pixels per em.
  static constexpr float kPointsToPixels = 96.0 / 72.0;

  explicit TypefaceSTB(std::unique_ptr<fml::Mapping> typeface_mapping);

  ~TypefaceSTB() override;

  // |Typeface|
  bool IsValid() const override;

  // |Comparable<Typeface>|
  std::size_t GetHash() const override;

  // |Comparable<Typeface>|
  bool IsEqual(const Typeface& other) const override;

  const uint8_t* GetTypefaceFile() const;
  const stbtt_fontinfo* GetFontInfo() const;

 private:
  std::unique_ptr<fml::Mapping> typeface_mapping_;
  std::unique_ptr<stbtt_fontinfo> font_info_;
  bool is_valid_;

  FML_DISALLOW_COPY_AND_ASSIGN(TypefaceSTB);
};

}  // namespace impeller
