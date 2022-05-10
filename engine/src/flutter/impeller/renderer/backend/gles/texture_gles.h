// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/gles/gles_handle.h"
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

  [[nodiscard]] bool Bind() const;

  enum class AttachmentPoint {
    kColor0,
    kDepth,
    kStencil,
  };
  [[nodiscard]] bool SetAsFramebufferAttachment(GLuint fbo,
                                                AttachmentPoint point) const;

  Type GetType() const;

  bool IsWrapped() const { return is_wrapped_; }

 private:
  friend class AllocatorMTL;

  ReactorGLES::Ref reactor_;
  const Type type_;
  GLESHandle handle_;
  mutable bool contents_initialized_ = false;
  const bool is_wrapped_;
  std::string label_;
  bool is_valid_ = false;

  TextureGLES(std::shared_ptr<ReactorGLES> reactor,
              TextureDescriptor desc,
              bool is_wrapped);

  // |Texture|
  void SetLabel(const std::string_view& label) override;

  // |Texture|
  bool SetContents(const uint8_t* contents, size_t length) override;

  // |Texture|
  bool IsValid() const override;

  // |Texture|
  ISize GetSize() const override;

  void InitializeContentsIfNecessary() const;

  FML_DISALLOW_COPY_AND_ASSIGN(TextureGLES);
};

}  // namespace impeller
