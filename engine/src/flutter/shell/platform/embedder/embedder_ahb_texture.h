// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_AHB_TEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_AHB_TEXTURE_H_

#include <memory>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_ahb.h"
#include "flutter/shell/platform/embedder/embedder_impeller_device_context.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      The texture that `FlutterEngineRegisterExternalTextureWithInfo`
///             registers for a
///             `kFlutterExternalTextureTypeAndroidHardwareBuffer` source. It
///             picks the implementation for the renderer it is painted with
///             (Skia OpenGL ES, Impeller OpenGL ES or Impeller Vulkan) at the
///             first paint, and owns the embedder's `user_data` until it is
///             destroyed.
///
class EmbedderAHBTexture final : public Texture {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Validates `info`. Returns null, without taking ownership of
  ///             `info.user_data`, if it does not describe a usable Android
  ///             hardware buffer source. Off Android, the texture never draws
  ///             anything.
  ///
  /// @param[in]  info            The texture and its source.
  /// @param[in]  device_context  Returns the Impeller device context, which
  ///                             the Vulkan implementation imports buffers
  ///                             with.
  ///
  static std::unique_ptr<EmbedderAHBTexture> Create(
      const FlutterExternalTextureInfo& info,
      EmbedderImpellerDeviceContextGetter device_context);

  ~EmbedderAHBTexture() override;

 private:
  EmbedderAHBTexture(int64_t id,
                     EmbedderAndroidHardwareBufferSource source,
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

  std::unique_ptr<EmbedderExternalTextureAHB> CreateImplementation(
      PaintContext& context);

  const EmbedderAndroidHardwareBufferSource source_;
  const VoidCallback destruction_callback_;
  const EmbedderImpellerDeviceContextGetter device_context_;
  std::unique_ptr<EmbedderExternalTextureAHB> implementation_;
  bool logged_unsupported_renderer_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderAHBTexture);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_AHB_TEXTURE_H_
