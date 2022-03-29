// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/display_list_image_impeller.h"

namespace impeller {

sk_sp<DlImageImpeller> DlImageImpeller::Make(std::shared_ptr<Texture> texture) {
  if (!texture) {
    return nullptr;
  }
  return sk_sp<DlImageImpeller>(new DlImageImpeller(std::move(texture)));
}

DlImageImpeller::DlImageImpeller(std::shared_ptr<Texture> texture)
    : texture_(std::move(texture)) {}

// |DlImage|
DlImageImpeller::~DlImageImpeller() = default;

// |DlImage|
sk_sp<SkImage> DlImageImpeller::skia_image() const {
  return nullptr;
};

// |DlImage|
std::shared_ptr<impeller::Texture> DlImageImpeller::impeller_texture() const {
  return texture_;
}

// |DlImage|
bool DlImageImpeller::isTextureBacked() const {
  // Impeller textures are always ... textures :/
  return true;
}

// |DlImage|
SkISize DlImageImpeller::dimensions() const {
  const auto size = texture_ ? texture_->GetSize() : ISize{};
  return SkISize::Make(size.width, size.height);
}

// |DlImage|
size_t DlImageImpeller::GetApproximateByteSize() const {
  auto size = sizeof(this);
  if (texture_) {
    size += texture_->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  }
  return size;
}

}  // namespace impeller
