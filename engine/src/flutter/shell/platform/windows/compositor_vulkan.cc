// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/compositor_vulkan.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/vulkan_manager.h"

namespace flutter {

CompositorVulkan::CompositorVulkan(FlutterWindowsEngine* engine)
    : engine_(engine) {}

CompositorVulkan::~CompositorVulkan() = default;

bool CompositorVulkan::EnsurePresenter() {
  if (presenter_) {
    return true;
  }
  VulkanManager* manager = engine_->vulkan_manager();
  if (!manager) {
    return false;
  }
  presenter_ = DCompPresenter::Create(manager->GetDeviceLUID());
  return presenter_ != nullptr;
}

bool CompositorVulkan::CreateBackingStore(
    const FlutterBackingStoreConfig& config,
    FlutterBackingStore* result) {
  if (!EnsurePresenter()) {
    return false;
  }

  VulkanManager* manager = engine_->vulkan_manager();
  uint32_t width = static_cast<uint32_t>(config.size.width);
  uint32_t height = static_cast<uint32_t>(config.size.height);

  HANDLE nt_handle = presenter_->CreateSharedTexture(width, height);
  if (!nt_handle) {
    return false;
  }

  std::unique_ptr<VulkanImportedImage> image =
      VulkanImportedImage::Import(manager, nt_handle, width, height);
  if (!image) {
    presenter_->EvictTexture(nt_handle);
    return false;
  }

  auto data = std::make_unique<BackingStoreData>();
  data->nt_handle = nt_handle;
  data->width = width;
  data->height = height;
  data->flutter_image.struct_size = sizeof(FlutterVulkanImage);
  data->flutter_image.image = reinterpret_cast<FlutterVulkanImageHandle>(
      reinterpret_cast<uint64_t>(image->image()));
  data->flutter_image.format = VK_FORMAT_B8G8R8A8_UNORM;
  data->image = std::move(image);

  result->type = kFlutterBackingStoreTypeVulkan;
  result->vulkan.struct_size = sizeof(FlutterVulkanBackingStore);
  result->vulkan.image = &data->flutter_image;
  result->vulkan.user_data = data.release();
  // Resources are released in CollectBackingStore; the engine-side
  // destruction callback has nothing left to do.
  result->vulkan.destruction_callback = [](void* user_data) {};

  return true;
}

bool CompositorVulkan::CollectBackingStore(const FlutterBackingStore* store) {
  FML_DCHECK(store->type == kFlutterBackingStoreTypeVulkan);

  auto* data = static_cast<BackingStoreData*>(store->vulkan.user_data);
  if (!data) {
    return false;
  }

  // Release the Vulkan import before destroying the Direct3D texture it is
  // bound to.
  data->image.reset();
  if (presenter_) {
    presenter_->EvictTexture(data->nt_handle);
  }
  delete data;
  return true;
}

bool CompositorVulkan::Present(FlutterWindowsView* view,
                               const FlutterLayer** layers,
                               size_t layers_count) {
  FML_DCHECK(view != nullptr);
  if (!presenter_) {
    return false;
  }

  // Nothing to draw; keep the previous frame. DirectComposition retains the
  // last committed content.
  if (layers_count == 0) {
    return true;
  }

  // Platform views are not yet supported, matching the other compositors.
  if (layers_count != 1 ||
      layers[0]->type != kFlutterLayerContentTypeBackingStore ||
      layers[0]->offset.x != 0 || layers[0]->offset.y != 0) {
    FML_LOG(ERROR) << "CompositorVulkan cannot present platform views or "
                      "offset layers yet.";
    return false;
  }

  const FlutterBackingStore* store = layers[0]->backing_store;
  FML_DCHECK(store->type == kFlutterBackingStoreTypeVulkan);
  auto* data = static_cast<BackingStoreData*>(store->vulkan.user_data);
  if (!data) {
    return false;
  }

  if (!presenter_->BindToWindow(view->GetWindowHandle())) {
    return false;
  }

  if (!presenter_->PresentTexture(data->nt_handle, data->width, data->height)) {
    return false;
  }

  // Fires the first-frame callback (the runner shows the window only after
  // the first presented frame) and completes any pending resize bookkeeping.
  // Without an EGL manager the view never enters resize synchronization, so
  // no OnFrameGenerated gate is required before presenting.
  view->OnFramePresented();
  return true;
}

}  // namespace flutter
