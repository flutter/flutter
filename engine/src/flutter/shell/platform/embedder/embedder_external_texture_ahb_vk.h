// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_VK_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_VK_H_

#include <cstdint>
#include <utility>
#include "flutter/shell/platform/embedder/embedder_external_texture_ahb.h"

#include "flutter/impeller/renderer/backend/vulkan/android/ahb_texture_source_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"

namespace flutter {

class EmbedderExternalTextureAHBVK : public EmbedderExternalTextureAHB {
 public:
  EmbedderExternalTextureAHBVK(
      const std::shared_ptr<impeller::ContextVK>& impeller_context,
      int64_t id,
      EmbedderAndroidHardwareBufferSource source);

  ~EmbedderExternalTextureAHBVK() override;

 private:
  void Attach(PaintContext& context) override;
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override;
  void Detach() override;

  const std::shared_ptr<impeller::ContextVK> impeller_context_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_VK_H_
