// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_GL_COMPOSITOR_H_
#define FLUTTER_GL_COMPOSITOR_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

// FlutterGLCompositor creates and manages the backing stores used for
// rendering Flutter content and presents Flutter content and Platform views.
// Platform views are not yet supported.
// FlutterGLCompositor is created and destroyed by FlutterEngine.
class FlutterGLCompositor : public FlutterCompositor {
 public:
  FlutterGLCompositor(FlutterViewController* view_controller,
                      NSOpenGLContext* opengl_context);

  virtual ~FlutterGLCompositor() = default;

  // Creates a BackingStore and saves updates the backing_store_out
  // data with the new BackingStore data.
  // If the backing store is being requested for the first time
  // for a given frame, this compositor does not create a new backing
  // store but rather returns the backing store associated with the
  // FlutterView's FlutterSurfaceManager.
  //
  // Any additional state allocated for the backing store and
  // saved as user_data in the backing store must be collected
  // in the backing_store's destruction_callback field which will
  // be called when the embedder collects the backing store.
  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out) override;

  // Releases the memory for any state used by the backing store.
  bool CollectBackingStore(const FlutterBackingStore* backing_store) override;

  // Presents the FlutterLayers by updating FlutterView(s) using the
  // layer content.
  // Present sets frame_started_ to false.
  bool Present(const FlutterLayer** layers, size_t layers_count) override;

 private:
  const NSOpenGLContext* open_gl_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterGLCompositor);
};

}  // namespace flutter

#endif  // FLUTTER_GL_COMPOSITOR_H_
