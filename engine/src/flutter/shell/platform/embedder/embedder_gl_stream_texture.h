// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_GL_STREAM_TEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_GL_STREAM_TEXTURE_H_

#include <memory>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream.h"
#include "flutter/shell/platform/embedder/embedder_impeller_device_context.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      The texture that `FlutterEngineRegisterExternalTextureWithInfo`
///             registers for a `kFlutterExternalTextureTypeOpenGLStream`
///             source. It picks the implementation for the renderer it is
///             painted with (Skia OpenGL, Impeller OpenGL ES, or Impeller
///             Vulkan on Android) at the first paint, and owns the embedder's
///             `user_data` until it is destroyed.
///
class EmbedderGLStreamTexture final : public Texture {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Validates `info`. Returns null, without taking ownership of
  ///             `info->user_data`, if it does not describe a usable OpenGL
  ///             stream source.
  ///
  /// @param[in]  info            The texture and its source.
  /// @param[in]  device_context  Returns the Impeller device context, which
  ///                             the Vulkan implementation copies frames with.
  ///                             May be null if the engine never renders with
  ///                             Impeller on Vulkan.
  ///
  static std::unique_ptr<EmbedderGLStreamTexture> Create(
      const FlutterExternalTextureInfo& info,
      EmbedderImpellerDeviceContextGetter device_context = nullptr);

  ~EmbedderGLStreamTexture() override;

 private:
  EmbedderGLStreamTexture(int64_t id,
                          EmbedderOpenGLTextureStream stream,
                          VoidCallback destruction_callback,
                          EmbedderImpellerDeviceContextGetter device_context);

  // |Texture|
  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override;

  // |ContextListener|
  void OnGrContextCreated() override;

  // |ContextListener|
  void OnGrContextDestroyed() override;

  // |Texture|
  void MarkNewFrameAvailable() override;

  // |Texture|
  void OnTextureUnregistered() override;

  std::unique_ptr<EmbedderExternalTextureGLStream> CreateImplementation(
      PaintContext& context);

  const EmbedderOpenGLTextureStream stream_;
  const VoidCallback destruction_callback_;
  const EmbedderImpellerDeviceContextGetter device_context_;
  std::unique_ptr<EmbedderExternalTextureGLStream> implementation_;
  bool logged_unsupported_renderer_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderGLStreamTexture);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_GL_STREAM_TEXTURE_H_
