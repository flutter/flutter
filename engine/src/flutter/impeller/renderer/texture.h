// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string_view>

#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/texture_descriptor.h"

namespace impeller {

class Texture {
 public:
  virtual ~Texture();

  virtual void SetLabel(const std::string_view& label) = 0;

  [[nodiscard]] virtual bool SetContents(const uint8_t* contents,
                                         size_t length) = 0;

  virtual bool IsValid() const = 0;

  virtual ISize GetSize() const = 0;

  const TextureDescriptor& GetTextureDescriptor() const;

 protected:
  Texture(TextureDescriptor desc);

 private:
  const TextureDescriptor desc_;

  FML_DISALLOW_COPY_AND_ASSIGN(Texture);
};

}  // namespace impeller
