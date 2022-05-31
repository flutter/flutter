// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/texture_mtl.h"

#include "impeller/base/validation.h"

namespace impeller {

TextureMTL::TextureMTL(TextureDescriptor p_desc, id<MTLTexture> texture)
    : Texture(std::move(p_desc)), texture_(texture) {
  const auto& desc = GetTextureDescriptor();

  if (!desc.IsValid() || !texture_) {
    return;
  }

  if (desc.size != GetSize()) {
    VALIDATION_LOG << "The texture and its descriptor disagree about its size.";
    return;
  }

  is_valid_ = true;
}

TextureMTL::~TextureMTL() = default;

void TextureMTL::SetLabel(std::string_view label) {
  [texture_ setLabel:@(label.data())];
}

// |Texture|
bool TextureMTL::OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                               size_t slice) {
  // Metal has no threading restrictions. So we can pass this data along to the
  // client rendering API immediately.
  return OnSetContents(mapping->GetMapping(), mapping->GetSize(), slice);
}

// |Texture|
bool TextureMTL::OnSetContents(const uint8_t* contents,
                               size_t length,
                               size_t slice) {
  if (!IsValid() || !contents) {
    return false;
  }

  const auto& desc = GetTextureDescriptor();

  // Out of bounds access.
  if (length != desc.GetByteSizeOfBaseMipLevel()) {
    return false;
  }

  // TODO(csg): Perhaps the storage mode should be added to the texture
  // descriptor so that invalid region replacements on potentially non-host
  // visible textures are disallowed. The annoying bit about the API below is
  // that there seems to be no error handling guidance.
  const auto region =
      MTLRegionMake2D(0u, 0u, desc.size.width, desc.size.height);
  [texture_ replaceRegion:region                            //
              mipmapLevel:0u                                //
                    slice:slice                             //
                withBytes:contents                          //
              bytesPerRow:desc.GetBytesPerRow()             //
            bytesPerImage:desc.GetByteSizeOfBaseMipLevel()  //
  ];

  return true;
}

ISize TextureMTL::GetSize() const {
  return {static_cast<ISize::Type>(texture_.width),
          static_cast<ISize::Type>(texture_.height)};
}

id<MTLTexture> TextureMTL::GetMTLTexture() const {
  return texture_;
}

bool TextureMTL::IsValid() const {
  return is_valid_;
}

}  // namespace impeller
