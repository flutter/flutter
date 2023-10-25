// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/image/compressed_image.h"

namespace impeller {

class CompressedImageSkia final : public CompressedImage {
 public:
  static std::shared_ptr<CompressedImage> Create(
      std::shared_ptr<const fml::Mapping> allocation);

  CompressedImageSkia(std::shared_ptr<const fml::Mapping> allocation);

  ~CompressedImageSkia() override;

  // |CompressedImage|
  DecompressedImage Decode() const override;

 private:
  CompressedImageSkia(const CompressedImageSkia&) = delete;

  CompressedImageSkia& operator=(const CompressedImageSkia&) = delete;
};

}  // namespace impeller
