// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_VK_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_VK_H_

#include <memory>

#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/impeller/toolkit/glvk/trampoline.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      An external texture implementation for Vulkan that uses OpenGL
///             to Vulkan texture interop to read SurfaceTexture based image
///             data and render it into a Vulkan texture.
///
///             Unlike other zero-copy implementations, the OpenGL to Vulkan
///             texture interop has the additional overhead of one device-device
///             copy and allocates one offscreen texture. For this reason, one
///             of the "Image" based external texture implementations are a
///             recommended replacement for this class. For example
///             `ImageExternalTextureVKImpeller`.
///
///             This implementation is used only as a fallback during the
///             migration away from the SurfaceTexture based plugin APIs. For
///             more information about the plugin API migration, see
///             https://docs.flutter.dev/release/breaking-changes/android-surface-plugins.
///
/// @see        `ImageExternalTextureVKImpeller`
///
class EmbedderExternalTextureGLStreamVK final
    : public EmbedderExternalTextureGLStream {
 public:
  EmbedderExternalTextureGLStreamVK(
      std::shared_ptr<impeller::ContextVK> context,
      int64_t id,
      EmbedderOpenGLTextureStream stream);

  ~EmbedderExternalTextureGLStreamVK() override;

  EmbedderExternalTextureGLStreamVK(const EmbedderExternalTextureGLStreamVK&) =
      delete;

  EmbedderExternalTextureGLStreamVK& operator=(
      const EmbedderExternalTextureGLStreamVK&) = delete;

 private:
  std::shared_ptr<impeller::ContextVK> context_;
  std::shared_ptr<impeller::glvk::Trampoline> trampoline_;
  std::shared_ptr<impeller::AHBTextureSourceVK> cached_texture_source_;
  bool is_valid_ = false;

  // |EmbedderExternalTextureGLStream|
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override;

  // |EmbedderExternalTextureGLStream|
  void Detach() override;

  // |EmbedderExternalTextureGLStream|
  void DrawFrame(PaintContext& context,
                 const SkRect& bounds,
                 const DlImageSampling sampling) const override;

  std::shared_ptr<impeller::AHBTextureSourceVK> GetCachedTextureSource(
      const std::shared_ptr<impeller::Context>& context,
      const impeller::ISize& size);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_VK_H_
