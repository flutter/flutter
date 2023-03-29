// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/core/allocator.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"

namespace impeller {

class AllocatorGLES final : public Allocator {
 public:
  // |Allocator|
  ~AllocatorGLES() override;

 private:
  friend class ContextGLES;

  ReactorGLES::Ref reactor_;
  bool is_valid_ = false;

  AllocatorGLES(ReactorGLES::Ref reactor);

  // |Allocator|
  bool IsValid() const;

  // |Allocator|
  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) override;

  // |Allocator|
  std::shared_ptr<Texture> OnCreateTexture(
      const TextureDescriptor& desc) override;

  // |Allocator|
  ISize GetMaxTextureSizeSupported() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(AllocatorGLES);
};

}  // namespace impeller
