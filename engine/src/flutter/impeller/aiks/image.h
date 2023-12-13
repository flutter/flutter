// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_IMAGE_H_
#define FLUTTER_IMPELLER_AIKS_IMAGE_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/core/texture.h"

namespace impeller {

class Image {
 public:
  explicit Image(std::shared_ptr<Texture> texture);

  ~Image();

  ISize GetSize() const;

  std::shared_ptr<Texture> GetTexture() const;

 private:
  const std::shared_ptr<Texture> texture_;

  Image(const Image&) = delete;

  Image& operator=(const Image&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_IMAGE_H_
