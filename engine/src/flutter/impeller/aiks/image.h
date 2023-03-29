// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/core/texture.h"

namespace impeller {

class Image {
 public:
  Image(std::shared_ptr<Texture> texture);

  ~Image();

  ISize GetSize() const;

  std::shared_ptr<Texture> GetTexture() const;

 private:
  const std::shared_ptr<Texture> texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(Image);
};

}  // namespace impeller
