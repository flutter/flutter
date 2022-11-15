// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_METAL_COMPOSITOR_H_
#define FLUTTER_METAL_COMPOSITOR_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViewController.h"

namespace flutter {

class FlutterMetalCompositor : public FlutterCompositor {
 public:
  explicit FlutterMetalCompositor(
      id<FlutterViewProvider> view_provider,
      FlutterPlatformViewController* platform_views_controller,
      id<MTLDevice> mtl_device);

  virtual ~FlutterMetalCompositor() = default;

  // Creates a BackingStore and sets backing_store_out to a
  // FlutterBackingStore struct containing details of the new
  // backing store.
  //
  // If the backing store is being requested for the first time
  // for a given frame, this compositor does not create a new backing
  // store but rather returns the backing store associated with the
  // FlutterView's FlutterSurfaceManager.
  //
  // Any additional state allocated for the backing store and
  // saved as user_data in the backing store must be collected
  // in backing_store_out's destruction_callback field which will
  // be called when the embedder collects the backing store.
  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out) override;

  // Releases and deallocates any and all resources that were allocated
  // for this FlutterBackingStore object in CreateBackingStore.
  bool CollectBackingStore(const FlutterBackingStore* backing_store) override;

  // Presents the FlutterLayers by updating the FlutterView specified by
  // `view_id` using the layer content.
  // Present sets frame_started_ to false.
  bool Present(uint64_t view_id,
               const FlutterLayer** layers,
               size_t layers_count) override;

 private:
  // Presents the platform view layer represented by `layer`. `layer_index` is
  // used to position the layer in the z-axis. If the layer does not have a
  // superview, it will become subview of `default_base_view`.
  void PresentPlatformView(FlutterView* default_base_view,
                           const FlutterLayer* layer,
                           size_t layer_position);

  const id<MTLDevice> mtl_device_;
  const FlutterPlatformViewController* platform_views_controller_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterMetalCompositor);
};

}  // namespace flutter

#endif  // FLUTTER_METAL_COMPOSITOR_H_
