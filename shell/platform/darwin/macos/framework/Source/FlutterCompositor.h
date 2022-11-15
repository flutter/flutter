// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMPOSITOR_H_
#define FLUTTER_COMPOSITOR_H_

#include <functional>
#include <list>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewProvider.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

// FlutterCompositor creates and manages the backing stores used for
// rendering Flutter content and presents Flutter content and Platform views.
// Platform views are not yet supported.
class FlutterCompositor {
 public:
  // Create a FlutterCompositor with a view provider.
  //
  // The view_provider is used to query FlutterViews from view IDs,
  // which are used for presenting and creating backing stores.
  // It must not be null, and is typically FlutterViewEngineProvider.
  explicit FlutterCompositor(id<FlutterViewProvider> view_provider);

  virtual ~FlutterCompositor() = default;

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
  virtual bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                                  FlutterBackingStore* backing_store_out) = 0;

  // Releases the memory for any state used by the backing store.
  virtual bool CollectBackingStore(
      const FlutterBackingStore* backing_store) = 0;

  // Presents the FlutterLayers by updating the FlutterView specified by
  // `view_id` using the layer content.
  // Present sets frame_started_ to false.
  virtual bool Present(uint64_t view_id,
                       const FlutterLayer** layers,
                       size_t layers_count) = 0;

  using PresentCallback = std::function<bool(bool has_flutter_content)>;

  // PresentCallback is called at the end of the Present function.
  void SetPresentCallback(const PresentCallback& present_callback);

  // Denotes the current status of the frame being composited.
  // Started: A new frame has begun and we have cleared the old layer tree
  //          and are now creating backingstore(s) for the embedder to use.
  // Presenting: the embedder has finished rendering into the provided
  //             backingstore(s) and we are creating the layer tree for the
  //             system compositor to present with.
  // Ended: The frame has been presented and we are no longer processing
  //        it.
  typedef enum { kStarted, kPresenting, kEnded } FrameStatus;

 protected:
  // Get the view associated with the view ID.
  //
  // Returns nil if the ID is invalid.
  FlutterView* GetView(uint64_t view_id);

  // Gets and sets the FrameStatus for the current frame.
  void SetFrameStatus(FrameStatus frame_status);
  FrameStatus GetFrameStatus();

  // Clears the previous CALayers and updates the frame status to frame started.
  void StartFrame();

  // Calls the present callback and ensures the frame status is updated
  // to frame ended, returning whether the present was successful or not.
  bool EndFrame(bool has_flutter_content);

  // Creates a CALayer object which is backed by the supplied IOSurface, and
  // adds it to the root CALayer for the given view.
  void InsertCALayerForIOSurface(
      FlutterView* view,
      const IOSurfaceRef& io_surface,
      CATransform3D transform = CATransform3DIdentity);

 private:
  // A list of the active CALayer objects for the frame that need to be removed.
  std::list<CALayer*> active_ca_layers_;

  // Where the compositor can query FlutterViews. Must not be null.
  id<FlutterViewProvider> const view_provider_;

  // Callback set by the embedder to be called when the layer tree has been
  // correctly set up for this frame.
  PresentCallback present_callback_;

  // Current frame status.
  FrameStatus frame_status_ = kEnded;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterCompositor);
};

}  // namespace flutter

#endif  // FLUTTER_COMPOSITOR_H_
