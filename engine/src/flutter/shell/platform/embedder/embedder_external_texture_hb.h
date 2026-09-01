// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_HB_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_HB_H_

#include <functional>
#include <memory>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class EmbedderExternalTextureHB : public flutter::Texture {
 public:
  using ExternalTextureCallback = std::function<std::unique_ptr<
      FlutterHardwareBufferExternalTexture>(int64_t, size_t, size_t)>;

  EmbedderExternalTextureHB(int64_t texture_identifier,
                            ExternalTextureCallback callback);

  ~EmbedderExternalTextureHB() override;

  // |flutter::Texture|
  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override;

  // |flutter::Texture|
  void OnGrContextCreated() override;

  // |flutter::Texture|
  void OnGrContextDestroyed() override;

  // |flutter::Texture|
  void MarkNewFrameAvailable() override;

  // |flutter::Texture|
  void OnTextureUnregistered() override;

  const FlutterHardwareBufferExternalTexture* GetCurrentFrame() const {
    return last_texture_frame_.get();
  }

 private:
  ExternalTextureCallback external_texture_callback_;
  sk_sp<DlImage> last_image_;
  std::unique_ptr<FlutterHardwareBufferExternalTexture> last_texture_frame_;
  bool has_new_frame_ = true;

  sk_sp<DlImage> ResolveTexture(int64_t texture_id,
                                GrDirectContext* context,
                                impeller::AiksContext* aiks_context,
                                const SkISize& size);

  void ReleaseLatestFrame();

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureHB);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_HB_H_
