// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/compositor_software.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

CompositorSoftware::CompositorSoftware(FlutterWindowsEngine* engine)
    : engine_(engine) {}

bool CompositorSoftware::CreateBackingStore(
    const FlutterBackingStoreConfig& config,
    FlutterBackingStore* result) {
  size_t size = config.size.width * config.size.height * 4;
  void* allocation = std::calloc(size, sizeof(uint8_t));
  if (!allocation) {
    return false;
  }

  result->type = kFlutterBackingStoreTypeSoftware;
  result->software.allocation = allocation;
  result->software.height = config.size.height;
  result->software.row_bytes = config.size.width * 4;
  result->software.user_data = nullptr;
  result->software.destruction_callback = [](void* user_data) {
    // Backing store destroyed in `CompositorSoftware::CollectBackingStore`, set
    // on FlutterCompositor.collect_backing_store_callback during engine start.
  };
  return true;
}

bool CompositorSoftware::CollectBackingStore(const FlutterBackingStore* store) {
  std::free(const_cast<void*>(store->software.allocation));
  return true;
}

bool CompositorSoftware::Present(FlutterViewId view_id,
                                 const FlutterLayer** layers,
                                 size_t layers_count) {
  FlutterWindowsView* view = engine_->view(view_id);
  if (!view) {
    return false;
  }

  // Clear the view if there are no layers to present.
  if (layers_count == 0) {
    return view->ClearSoftwareBitmap();
  }

  // TODO: Support compositing layers and platform views.
  // See: https://github.com/flutter/flutter/issues/31713
  FML_DCHECK(layers_count == 1);
  FML_DCHECK(layers[0]->offset.x == 0 && layers[0]->offset.y == 0);
  FML_DCHECK(layers[0]->type == kFlutterLayerContentTypeBackingStore);
  FML_DCHECK(layers[0]->backing_store->type ==
             kFlutterBackingStoreTypeSoftware);

  const auto& backing_store = layers[0]->backing_store->software;

  return view->PresentSoftwareBitmap(
      backing_store.allocation, backing_store.row_bytes, backing_store.height);
}

}  // namespace flutter
