// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/texture_gles.h"

#include "flutter/fml/mapping.h"
#include "impeller/base/allocation.h"
#include "impeller/base/config.h"
#include "impeller/base/validation.h"

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
  if (!IsValid() || handle_.IsDead()) {
    return;
  }
  reactor_->SetDebugLabel(handle_, std::string{label.data(), label.size()});
}

struct TexImage2DData {
  GLint internal_format = 0;
  GLenum format = GL_NONE;
  GLenum type = GL_NONE;
  std::shared_ptr<fml::Mapping> data;

  TexImage2DData(PixelFormat pixel_format,
                 const uint8_t* contents,
                 size_t length) {
    switch (pixel_format) {
      case PixelFormat::kUnknown:
        return;
      case PixelFormat::kR8UNormInt:
        internal_format = GL_RGBA;
        format = GL_RGBA;
        type = GL_UNSIGNED_SHORT_4_4_4_4;
        {
          auto allocation = std::make_shared<Allocation>();
          if (!allocation->Truncate(length * 2u, false)) {
            VALIDATION_LOG << "Could not allocate buffer for texture data.";
            return;
          }
          auto buffer = reinterpret_cast<uint16_t*>(allocation->GetBuffer());
          for (size_t i = 0; i < length; i++) {
            uint8_t value = contents[i];
            buffer[i] = (value | value << 4 | value << 8 | value << 12);
          }
          data = CreateMappingFromAllocation(std::move(allocation));
          if (!data) {
            return;
          }
        }
        break;
      case PixelFormat::kR8G8B8A8UNormInt:
        internal_format = GL_RGBA;
        format = GL_RGBA;
        type = GL_UNSIGNED_BYTE;
        data = CreateMappingWithCopy(contents, length);
        if (!data) {
          VALIDATION_LOG << "Could not copy texture data.";
          return;
        }
        break;
      case PixelFormat::kR8G8B8A8UNormIntSRGB:
        return;
      case PixelFormat::kB8G8R8A8UNormInt:
        return;
      case PixelFormat::kB8G8R8A8UNormIntSRGB:
        return;
      case PixelFormat::kS8UInt:
        return;
    }
    is_valid_ = true;
  }

  bool IsValid() const { return is_valid_; }

 private:
  bool is_valid_ = false;
};

// |Texture|
bool TextureGLES::SetContents(const uint8_t* contents, size_t length) {
  if (length == 0u) {
    return true;
  }

  const auto& tex_descriptor = GetTextureDescriptor();

  if (tex_descriptor.size.IsEmpty()) {
    return true;
  }

  if (!tex_descriptor.IsValid()) {
    return false;
  }

  if (length < tex_descriptor.GetByteSizeOfBaseMipLevel()) {
    VALIDATION_LOG << "Insufficient data provided for texture.";
    return false;
  }

  auto data =
      std::make_shared<TexImage2DData>(tex_descriptor.format, contents, length);
  if (!data || !data->IsValid()) {
    VALIDATION_LOG << "Invalid texture format.";
    return false;
  }

  ReactorGLES::Operation texture_upload = [handle = handle_,           //
                                           data,                       //
                                           size = tex_descriptor.size  //
  ](const auto& reactor) {
    auto gl_handle = reactor.GetGLHandle(handle);
    if (!gl_handle.has_value()) {
      VALIDATION_LOG
          << "Texture was collected before it could be uploaded to the GPU.";
      return;
    }
    const auto& gl = reactor.GetProcTable();
    gl.BindTexture(GL_TEXTURE_2D, gl_handle.value());
    gl.TexImage2D(
        GL_TEXTURE_2D,          // target
        0u,                     // LOD level (base mip level size checked)
        data->internal_format,  // internal format
        size.width,             // width
        size.height,            // height
        0u,                     // border
        data->format,           // format
        data->type,             // type
        reinterpret_cast<const GLvoid*>(data->data->GetMapping())  // data
    );
  };

  return reactor_->AddOperation(texture_upload);
}

// |Texture|
ISize TextureGLES::GetSize() const {
  return GetTextureDescriptor().size;
}

bool TextureGLES::Bind() const {
  if (!IsValid()) {
    return false;
  }
  auto handle = reactor_->GetGLHandle(handle_);
  if (!handle.has_value()) {
    return false;
  }
  const auto& gl = reactor_->GetProcTable();
  gl.BindTexture(GL_TEXTURE_2D, handle.value());
  return true;
}

}  // namespace impeller
