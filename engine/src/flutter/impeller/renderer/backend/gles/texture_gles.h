// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEXTURE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEXTURE_GLES_H_

#include <bitset>

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

  TextureGLES(ReactorGLES::Ref reactor,
              TextureDescriptor desc,
              HandleGLES external_handle);

  static std::shared_ptr<TextureGLES> WrapFBO(ReactorGLES::Ref reactor,
                                              TextureDescriptor desc,
                                              GLuint fbo);

  // |Texture|
  ~TextureGLES() override;

  // |Texture|
  bool IsValid() const override;

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

  bool IsWrapped() const;

  std::optional<GLuint> GetFBO() const;

  // For non cubemap textures, 0 indicates uninitialized and 1 indicates
  // initialized. For cubemap textures, each face is initialized separately with
  // each bit tracking the initialization of the corresponding slice.
  void MarkSliceInitialized(size_t slice) const;

  bool IsSliceInitialized(size_t slice) const;

 private:
  ReactorGLES::Ref reactor_;
  const Type type_;
  HandleGLES handle_;
  mutable std::bitset<6> slices_initialized_ = 0;
  const bool is_wrapped_;
  const std::optional<GLuint> wrapped_fbo_;
  bool is_valid_ = false;

  TextureGLES(std::shared_ptr<ReactorGLES> reactor,
              TextureDescriptor desc,
              bool is_wrapped,
              std::optional<GLuint> fbo,
              std::optional<HandleGLES> external_handle);

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
  ISize GetSize() const override;

  // |Texture|
  Scalar GetYCoordScale() const override;

  void InitializeContentsIfNecessary() const;

  TextureGLES(const TextureGLES&) = delete;

  TextureGLES& operator=(const TextureGLES&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEXTURE_GLES_H_
