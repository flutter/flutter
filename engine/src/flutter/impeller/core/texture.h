// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string_view>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/geometry/size.h"

namespace impeller {

class Texture {
 public:
  virtual ~Texture();

  virtual void SetLabel(std::string_view label) = 0;

  [[nodiscard]] bool SetContents(const uint8_t* contents,
                                 size_t length,
                                 size_t slice = 0,
                                 bool is_opaque = false);

  [[nodiscard]] bool SetContents(std::shared_ptr<const fml::Mapping> mapping,
                                 size_t slice = 0,
                                 bool is_opaque = false);

  virtual bool IsValid() const = 0;

  virtual ISize GetSize() const = 0;

  bool IsOpaque() const;

  size_t GetMipCount() const;

  const TextureDescriptor& GetTextureDescriptor() const;

  void SetIntent(TextureIntent intent);

  TextureIntent GetIntent() const;

  virtual Scalar GetYCoordScale() const;

  bool NeedsMipmapGeneration() const;

 protected:
  explicit Texture(TextureDescriptor desc);

  [[nodiscard]] virtual bool OnSetContents(const uint8_t* contents,
                                           size_t length,
                                           size_t slice) = 0;

  [[nodiscard]] virtual bool OnSetContents(
      std::shared_ptr<const fml::Mapping> mapping,
      size_t slice) = 0;

  bool mipmap_generated_ = false;

 private:
  TextureIntent intent_ = TextureIntent::kRenderToTexture;
  const TextureDescriptor desc_;
  bool is_opaque_ = false;

  bool IsSliceValid(size_t slice) const;

  FML_DISALLOW_COPY_AND_ASSIGN(Texture);
};

}  // namespace impeller
