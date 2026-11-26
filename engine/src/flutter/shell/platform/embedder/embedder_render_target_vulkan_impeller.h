// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_RENDER_TARGET_VULKAN_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_RENDER_TARGET_VULKAN_IMPELLER_H_

#include "flutter/shell/platform/embedder/embedder_render_target_impeller.h"

namespace flutter {

std::unique_ptr<EmbedderRenderTarget> CreateVulkanImpellerRenderTarget(
    FlutterBackingStore backing_store,
    const FlutterBackingStoreConfig& config,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    fml::ScopedCleanupClosure on_release);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_RENDER_TARGET_VULKAN_IMPELLER_H_
