// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEXTURE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEXTURE_GLES_H_

#include "impeller/base/backend_cast.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"

namespace impeller {

class TextureGLES final : public Texture,
                          public BackendCast<TextureGLES, Texture> {
 public:
  enum class Type {
    kTexture,
    kTextureMultisampled,
    kRenderBuffer,
    kRenderBufferMultisampled,
  };

  enum class IsWrapped {
    kWrapped,
  };

  TextureGLES(ReactorGLES::Ref reactor, TextureDescriptor desc);

  TextureGLES(ReactorGLES::Ref reactor,
              TextureDescriptor desc,
              IsWrapped wrapped);

  // |Texture|
  ~TextureGLES() override;

  std::optional<GLuint> GetGLHandle() const;

  [[nodiscard]] bool Bind() const;

  [[nodiscard]] bool GenerateMipmap();

  enum class AttachmentType {
    kColor0,
    kDepth,
    kStencil,
  };
  [[nodiscard]] bool SetAsFramebufferAttachment(
      GLenum target,
      AttachmentType attachment_type) const;

  Type GetType() const;

  bool IsWrapped() const { return is_wrapped_; }

 private:
  friend class AllocatorMTL;

  ReactorGLES::Ref reactor_;
  const Type type_;
  HandleGLES handle_;
  mutable bool contents_initialized_ = false;
  const bool is_wrapped_;
  bool is_valid_ = false;

  TextureGLES(std::shared_ptr<ReactorGLES> reactor,
              TextureDescriptor desc,
              bool is_wrapped);

  // |Texture|
  void SetLabel(std::string_view label) override;

  // |Texture|
  bool OnSetContents(const uint8_t* contents,
                     size_t length,
                     size_t slice) override;

  // |Texture|
  bool OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                     size_t slice) override;

  // |Texture|
  bool IsValid() const override;

  // |Texture|
  ISize GetSize() const override;

  // |Texture|
  Scalar GetYCoordScale() const override;

  void InitializeContentsIfNecessary() const;

  TextureGLES(const TextureGLES&) = delete;

  TextureGLES& operator=(const TextureGLES&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEXTURE_GLES_H_
