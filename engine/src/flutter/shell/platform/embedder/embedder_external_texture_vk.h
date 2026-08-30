// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_VK_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_VK_H_

#include <functional>
#include <memory>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/core/SkSize.h"

namespace impeller {
class AiksContext;
}  // namespace impeller

namespace flutter {

class EmbedderExternalTextureVK : public flutter::Texture {
 public:
  using ExternalTextureCallback = std::function<
      std::unique_ptr<FlutterVulkanExternalTexture>(int64_t, size_t, size_t)>;

  EmbedderExternalTextureVK(int64_t texture_identifier,
                            const ExternalTextureCallback& callback);

  ~EmbedderExternalTextureVK() override;

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

 private:
  const ExternalTextureCallback& external_texture_callback_;
  sk_sp<DlImage> last_image_;

  sk_sp<DlImage> ResolveTexture(int64_t texture_id,
                                GrDirectContext* context,
                                impeller::AiksContext* aiks_context,
                                const SkISize& size);

  sk_sp<DlImage> ResolveTextureSkia(int64_t texture_id,
                                    GrDirectContext* context,
                                    const SkISize& size);

  sk_sp<DlImage> ResolveTextureImpeller(int64_t texture_id,
                                        impeller::AiksContext* aiks_context,
                                        const SkISize& size);

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureVK);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_VK_H_
