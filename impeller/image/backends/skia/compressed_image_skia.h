// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/image/compressed_image.h"

namespace impeller {

class CompressedImageSkia final : public CompressedImage {
 public:
  CompressedImageSkia(std::shared_ptr<const fml::Mapping> allocation);

  ~CompressedImageSkia() override;

  // |CompressedImage|
  DecompressedImage Decode() const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(CompressedImageSkia);
};

}  // namespace impeller
