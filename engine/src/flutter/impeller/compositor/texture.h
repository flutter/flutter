// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string_view>

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/compositor/formats.h"
#include "impeller/compositor/texture_descriptor.h"
#include "impeller/geometry/size.h"

namespace impeller {

class Texture {
 public:
  Texture(TextureDescriptor desc, id<MTLTexture> texture);

  ~Texture();

  void SetLabel(const std::string_view& label);

  [[nodiscard]] bool SetContents(const uint8_t* contents, size_t length);

  bool IsValid() const;

  ISize GetSize() const;

  id<MTLTexture> GetMTLTexture() const;

 private:
  const TextureDescriptor desc_;
  id<MTLTexture> texture_ = nullptr;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Texture);
};

}  // namespace impeller
