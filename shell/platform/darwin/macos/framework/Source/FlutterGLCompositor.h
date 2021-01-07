// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <map>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

// FlutterGLCompositor creates and manages the backing stores used for
// rendering Flutter content and presents Flutter content and Platform views.
// Platform views are not yet supported.
// FlutterGLCompositor is created and destroyed by FlutterEngine.
class FlutterGLCompositor {
 public:
  FlutterGLCompositor(FlutterViewController* view_controller,
                      NSOpenGLContext* opengl_context);

  // Creates a BackingStore and saves updates the backing_store_out
  // data with the new BackingStore data.
  // If the backing store is being requested for the first time
  // for a given frame, we do not create a new backing store but
  // rather return the backing store associated with the
  // FlutterView's FlutterSurfaceManager.
  //
  // Any additional state allocated for the backing store and
  // saved as user_data in the backing store must be collected
  // in the backing_store's desctruction_callback field which will
  // be called when the embedder collects the backing store.
  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out);

  // Releases the memory for any state used by the backing store.
  bool CollectBackingStore(const FlutterBackingStore* backing_store);

  // Presents the FlutterLayers by updating FlutterView(s) using the
  // layer content.
  // Present sets frame_started_ to false.
  bool Present(const FlutterLayer** layers, size_t layers_count);

  using PresentCallback = std::function<bool()>;

  // PresentCallback is called at the end of the Present function.
  void SetPresentCallback(const PresentCallback& present_callback);

 private:
  const FlutterViewController* view_controller_;
  const NSOpenGLContext* open_gl_context_;
  PresentCallback present_callback_;

  // Count for how many CALayers have been created for a frame.
  // Resets when a frame is finished.
  // ca_layer_count_ is also used as a layerId.
  size_t ca_layer_count_ = 0;

  // Maps a layer_id (size_t) to a CALayer.
  // The layer_id starts at 0 for a given frame
  // and increments by 1 for each new CALayer.
  std::map<size_t, CALayer*> ca_layer_map_;

  // frame_started_ keeps track of if a layer has been
  // created for the frame.
  bool frame_started_ = false;

  // Set frame_started_ to true and reset all layer state.
  void StartFrame();

  // Creates a CALayer and adds it to ca_layer_map_ and increments
  // ca_layer_count_; Returns the key value (size_t) for the layer in
  // ca_layer_map_.
  size_t CreateCALayer();

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterGLCompositor);
};

}  // namespace flutter
