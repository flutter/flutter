// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_TEXTURE_UPLOADER_H_
#define MOJO_GPU_TEXTURE_UPLOADER_H_

#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "mojo/gpu/gl_context.h"
#include "mojo/gpu/gl_texture.h"
#include "mojo/services/surfaces/public/interfaces/surfaces.mojom.h"

namespace mojo {

// Utility class for uploading textures to a surface.
class TextureUploader {
 public:
  // Gets a FramePtr for uploading to a to a SurfacePtr using |texture| as a
  // transferable resource with id |resource_id|.
  static mojo::FramePtr GetUploadFrame(
      base::WeakPtr<mojo::GLContext> context,
      uint32_t resource_id,
      const scoped_ptr<mojo::GLTexture>& texture);

 private:
  TextureUploader();
  ~TextureUploader();
  DISALLOW_COPY_AND_ASSIGN(TextureUploader);
};

}  // namespace mojo

#endif  // MOJO_GPU_TEXTURE_UPLOADER_H_
