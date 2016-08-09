// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SKIA_GANESH_IMAGE_FACTORY_H_
#define MOJO_SKIA_GANESH_IMAGE_FACTORY_H_

#include <GLES2/gl2.h>
#include <GLES2/gl2extmojo.h>

#include "base/callback.h"
#include "mojo/skia/ganesh_context.h"
#include "third_party/skia/include/core/SkImageGenerator.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/gpu/GrTypes.h"

class SkImage;

namespace mojo {
namespace skia {

// Creates an SkImage from a GL texture.
// The underlying texture must be kept alive for as long as the SkImage exists.
// Invokes |release_callback| when the SkImage is deleted.
sk_sp<SkImage> CreateImageFromTexture(const GaneshContext::Scope& scope,
                                      uint32_t texture_id,
                                      uint32_t width,
                                      uint32_t height,
                                      GrSurfaceOrigin origin,
                                      const base::Closure& release_callback);

// Generates backing content for SkImages from a texture mailbox.
// If |sync_point| is non-zero, inserts a sync point into the command stream
// before the image is first drawn.
// It is the responsibility of the client of this class to ensure that
// the mailbox name is valid at the time when the image is being drawn.
class MailboxTextureImageGenerator : public SkImageGenerator {
 public:
  MailboxTextureImageGenerator(
      const GLbyte mailbox_name[GL_MAILBOX_SIZE_CHROMIUM],
      GLuint sync_point,
      uint32_t width,
      uint32_t height,
      GrSurfaceOrigin origin);
  ~MailboxTextureImageGenerator() override;

  GrTexture* onGenerateTexture(GrContext* context,
                               const SkIRect* subset) override;

 private:
  GLbyte mailbox_name_[GL_MAILBOX_SIZE_CHROMIUM];
  GLuint sync_point_;
  GrSurfaceOrigin origin_;
};

}  // namespace skia
}  // namespace mojo

#endif  // MOJO_SKIA_GANESH_IMAGE_FACTORY_H_
