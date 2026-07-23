// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_COMPOSITOR_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_COMPOSITOR_VULKAN_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/compositor.h"
#include "flutter/shell/platform/windows/dcomp_presenter.h"
#include "flutter/shell/platform/windows/vulkan_imported_image.h"

namespace flutter {

class FlutterWindowsEngine;

// Enables the Flutter engine to render content on Windows using Impeller's
// Vulkan backend, presented through DirectComposition.
//
// Backing stores are shared Direct3D 11 textures (allocated by the
// presenter, since Windows drivers only support importing Direct3D textures
// into Vulkan, not exporting from it) imported as VkImages that Impeller
// renders into. Present copies the texture into a composition swapchain and
// commits, so the window chrome and content update atomically.
//
// Platform views are not yet supported, matching the other compositors.
class CompositorVulkan : public Compositor {
 public:
  explicit CompositorVulkan(FlutterWindowsEngine* engine);

  ~CompositorVulkan() override;

  // |Compositor|
  bool CreateBackingStore(const FlutterBackingStoreConfig& config,
                          FlutterBackingStore* result) override;

  // |Compositor|
  bool CollectBackingStore(const FlutterBackingStore* store) override;

  // |Compositor|
  bool Present(FlutterWindowsView* view,
               const FlutterLayer** layers,
               size_t layers_count) override;

 private:
  // One backing store: the shared texture handle plus its Vulkan import.
  // Owned through FlutterBackingStore::vulkan.user_data.
  struct BackingStoreData {
    HANDLE nt_handle = nullptr;
    std::unique_ptr<VulkanImportedImage> image;
    FlutterVulkanImage flutter_image = {};
    uint32_t width = 0;
    uint32_t height = 0;
  };

  // Lazily creates the presenter on the adapter of the engine's Vulkan
  // device. Returns false if the presenter cannot be created.
  bool EnsurePresenter();

  // The Flutter engine that manages the views to render.
  FlutterWindowsEngine* engine_;

  std::unique_ptr<DCompPresenter> presenter_;

  FML_DISALLOW_COPY_AND_ASSIGN(CompositorVulkan);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_COMPOSITOR_VULKAN_H_
