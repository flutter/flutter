// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/texture_gles.h"

#include "flutter/fml/mapping.h"
#include "impeller/base/allocation.h"
#include "impeller/base/config.h"

namespace impeller {

TextureGLES::TextureGLES(std::shared_ptr<ReactorGLES> reactor,
                         TextureDescriptor desc)
    : Texture(std::move(desc)),
      reactor_(reactor),
      handle_(reactor_->CreateHandle(HandleType::kTexture)) {
  if (!GetTextureDescriptor().IsValid()) {
    return;
  }

  is_valid_ = true;
}

// |Texture|
TextureGLES::~TextureGLES() {
  reactor_->CollectHandle(std::move(handle_));
}

// |Texture|
bool TextureGLES::IsValid() const {
  return is_valid_;
}

// |Texture|
void TextureGLES::SetLabel(const std::string_view& label) {
  // Unsupported.
}

// |Texture|
bool TextureGLES::SetContents(const uint8_t* contents, size_t length) {
  if (length == 0u) {
    return true;
  }

  auto mapping = CreateMappingWithCopy(contents, length);

  return reactor_->AddOperation([mapping](const auto& reactor) {});
}

// |Texture|
ISize TextureGLES::GetSize() const {
  return GetTextureDescriptor().size;
}

}  // namespace impeller
