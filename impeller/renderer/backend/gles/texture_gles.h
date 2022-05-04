// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/gles/gles_handle.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class TextureGLES final : public Texture {
 public:
  TextureGLES(ReactorGLES::Ref reactor, TextureDescriptor desc);

  // |Texture|
  ~TextureGLES() override;

 private:
  friend class AllocatorMTL;

  ReactorGLES::Ref reactor_;
  GLESHandle handle_;
  bool is_valid_ = false;

  // |Texture|
  void SetLabel(const std::string_view& label) override;

  // |Texture|
  bool SetContents(const uint8_t* contents, size_t length) override;

  // |Texture|
  bool IsValid() const override;

  // |Texture|
  ISize GetSize() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(TextureGLES);
};

}  // namespace impeller
