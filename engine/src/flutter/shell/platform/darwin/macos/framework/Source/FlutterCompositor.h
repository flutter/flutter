// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMPOSITOR_H_
#define FLUTTER_COMPOSITOR_H_

#include <functional>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

// FlutterCompositor creates and manages the backing stores used for
// rendering Flutter content and presents Flutter content and Platform views.
// Platform views are not yet supported.
class FlutterCompositor {
 public:
  FlutterCompositor(FlutterViewController* view_controller);

  virtual ~FlutterCompositor() = default;

  // Creates a BackingStore and saves updates the backing_store_out
  // data with the new BackingStore data.
  // If the backing store is being requested for the first time
  // for a given frame, we do not create a new backing store but
  // rather return the backing store associated with the
  // FlutterView's FlutterSurfaceManager.
  //
  // Any additional state allocated for the backing store and
  // saved as user_data in the backing store must be collected
  // in the backing_store's destruction_callback field which will
  // be called when the embedder collects the backing store.
  virtual bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                                  FlutterBackingStore* backing_store_out) = 0;

  // Releases the memory for any state used by the backing store.
  virtual bool CollectBackingStore(
      const FlutterBackingStore* backing_store) = 0;

  // Presents the FlutterLayers by updating FlutterView(s) using the
  // layer content.
  // Present sets frame_started_ to false.
  virtual bool Present(const FlutterLayer** layers, size_t layers_count) = 0;

  using PresentCallback = std::function<bool()>;

  // PresentCallback is called at the end of the Present function.
  void SetPresentCallback(const PresentCallback& present_callback);

 protected:
  __weak const FlutterViewController* view_controller_;

  PresentCallback present_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterCompositor);
};

}  // namespace flutter

#endif  // FLUTTER_COMPOSITOR_H_
