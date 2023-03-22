// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class TextureGLES final : public Texture,
                          public BackendCast<TextureGLES, Texture> {
 public:
  enum class Type {
    kTexture,
    kRenderBuffer,
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

  enum class AttachmentPoint {
    kColor0,
    kDepth,
    kStencil,
  };
  [[nodiscard]] bool SetAsFramebufferAttachment(GLenum target,
                                                GLuint fbo,
                                                AttachmentPoint point) const;

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

  FML_DISALLOW_COPY_AND_ASSIGN(TextureGLES);
};

}  // namespace impeller
