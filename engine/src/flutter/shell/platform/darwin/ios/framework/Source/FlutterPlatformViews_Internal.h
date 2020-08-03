// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/rtree.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlugin.h"
#include "flutter/shell/platform/darwin/ios/ios_context.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

// A UIView that acts as a clipping mask for the |ChildClippingView|.
//
// On the [UIView drawRect:] method, this view performs a series of clipping operations and sets the
// alpha channel to the final resulting area to be 1; it also sets the "clipped out" area's alpha
// channel to be 0.
//
// When a UIView sets a |FlutterClippingMaskView| as its `maskView`, the alpha channel of the UIView
// is replaced with the alpha channel of the |FlutterClippingMaskView|.
@interface FlutterClippingMaskView : UIView

// Adds a clip rect operation to the queue.
//
// The `clipSkRect` is transformed with the `matrix` before adding to the queue.
- (void)clipRect:(const SkRect&)clipSkRect matrix:(const CATransform3D&)matrix;

// Adds a clip rrect operation to the queue.
//
// The `clipSkRRect` is transformed with the `matrix` before adding to the queue.
- (void)clipRRect:(const SkRRect&)clipSkRRect matrix:(const CATransform3D&)matrix;

// Adds a clip path operation to the queue.
//
// The `path` is transformed with the `matrix` before adding to the queue.
- (void)clipPath:(const SkPath&)path matrix:(const CATransform3D&)matrix;

@end

// A UIView that is used as the parent for embedded UIViews.
//
// This view has 2 roles:
// 1. Delay or prevent touch events from arriving the embedded view.
// 2. Dispatching all events that are hittested to the embedded view to the FlutterView.
@interface FlutterTouchInterceptingView : UIView
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView
               flutterViewController:(UIViewController*)flutterViewController
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)blockingPolicy;

// Stop delaying any active touch sequence (and let it arrive the embedded view).
- (void)releaseGesture;

// Prevent the touch sequence from ever arriving to the embedded view.
- (void)blockGesture;
@end

// The parent view handles clipping to its subviews.
@interface ChildClippingView : UIView

@end

namespace flutter {
// Converts a SkMatrix to CATransform3D.
// Certain fields are ignored in CATransform3D since SkMatrix is 3x3 and CATransform3D is 4x4.
CATransform3D GetCATransform3DFromSkMatrix(const SkMatrix& matrix);

// Reset the anchor of `layer` to match the tranform operation from flow.
// The position of the `layer` should be unchanged after resetting the anchor.
void ResetAnchor(CALayer* layer);

class IOSContextGL;
class IOSSurface;

struct FlutterPlatformViewLayer {
  FlutterPlatformViewLayer(fml::scoped_nsobject<UIView> overlay_view,
                           fml::scoped_nsobject<UIView> overlay_view_wrapper,
                           std::unique_ptr<IOSSurface> ios_surface,
                           std::unique_ptr<Surface> surface);

  ~FlutterPlatformViewLayer();

  fml::scoped_nsobject<UIView> overlay_view;
  fml::scoped_nsobject<UIView> overlay_view_wrapper;
  std::unique_ptr<IOSSurface> ios_surface;
  std::unique_ptr<Surface> surface;

  // Whether a frame for this layer was submitted.
  bool did_submit_last_frame;

  // The GrContext that is currently used by the overlay surfaces.
  // We track this to know when the GrContext for the Flutter app has changed
  // so we can update the overlay with the new context.
  GrDirectContext* gr_context;
};

// This class isn't thread safe.
class FlutterPlatformViewLayerPool {
 public:
  FlutterPlatformViewLayerPool() = default;
  ~FlutterPlatformViewLayerPool() = default;

  // Gets a layer from the pool if available, or allocates a new one.
  // Finally, it marks the layer as used. That is, it increments `available_layer_index_`.
  std::shared_ptr<FlutterPlatformViewLayer> GetLayer(GrDirectContext* gr_context,
                                                     std::shared_ptr<IOSContext> ios_context);

  // Gets the layers in the pool that aren't currently used.
  // This method doesn't mark the layers as unused.
  std::vector<std::shared_ptr<FlutterPlatformViewLayer>> GetUnusedLayers();

  // Marks the layers in the pool as available for reuse.
  void RecycleLayers();

 private:
  // The index of the entry in the layers_ vector that determines the beginning of the unused
  // layers. For example, consider the following vector:
  //  _____
  //  | 0 |
  /// |---|
  /// | 1 | <-- available_layer_index_
  /// |---|
  /// | 2 |
  /// |---|
  ///
  /// This indicates that entries starting from 1 can be reused meanwhile the entry at position 0
  /// cannot be reused.
  size_t available_layer_index_ = 0;
  std::vector<std::shared_ptr<FlutterPlatformViewLayer>> layers_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterPlatformViewLayerPool);
};

class FlutterPlatformViewsController {
 public:
  FlutterPlatformViewsController();

  ~FlutterPlatformViewsController();

  void SetFlutterView(UIView* flutter_view);

  void SetFlutterViewController(UIViewController* flutter_view_controller);

  void RegisterViewFactory(
      NSObject<FlutterPlatformViewFactory>* factory,
      NSString* factoryId,
      FlutterPlatformViewGestureRecognizersBlockingPolicy gestureRecognizerBlockingPolicy);

  void SetFrameSize(SkISize frame_size);

  // Indicates that we don't compisite any platform views or overlays during this frame.
  // Also reverts the composition_order_ to its original state at the begining of the frame.
  void CancelFrame();

  void PrerollCompositeEmbeddedView(int view_id,
                                    std::unique_ptr<flutter::EmbeddedViewParams> params);

  // Returns the `FlutterPlatformView` object associated with the view_id.
  //
  // If the `FlutterPlatformViewsController` does not contain any `FlutterPlatformView` object or
  // a `FlutterPlatformView` object asscociated with the view_id cannot be found, the method
  // returns nil.
  NSObject<FlutterPlatformView>* GetPlatformViewByID(int view_id);

  PostPrerollResult PostPrerollAction(fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger);

  std::vector<SkCanvas*> GetCurrentCanvases();

  SkCanvas* CompositeEmbeddedView(int view_id);

  // The rect of the platform view at index view_id. This rect has been translated into the
  // host view coordinate system. Units are device screen pixels.
  SkRect GetPlatformViewRect(int view_id);

  // Discards all platform views instances and auxiliary resources.
  void Reset();

  bool SubmitFrame(GrDirectContext* gr_context,
                   std::shared_ptr<IOSContext> ios_context,
                   std::unique_ptr<SurfaceFrame> frame);

  // Invoked at the very end of a frame.
  // After invoking this method, nothing should happen on the current TaskRunner during the same
  // frame.
  void EndFrame(bool should_resubmit_frame,
                fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger);

  void OnMethodCall(FlutterMethodCall* call, FlutterResult& result);

 private:
  static const size_t kMaxLayerAllocations = 2;

  using LayersMap = std::map<int64_t, std::vector<std::shared_ptr<FlutterPlatformViewLayer>>>;

  // The pool of reusable view layers. The pool allows to recycle layer in each frame.
  std::unique_ptr<FlutterPlatformViewLayerPool> layer_pool_;

  // The platform view's R-tree keyed off the view id, which contains any subsequent
  // draw operation until the next platform view or the last leaf node in the layer tree.
  //
  // The R-trees are deleted by the FlutterPlatformViewsController.reset().
  std::map<int64_t, sk_sp<RTree>> platform_view_rtrees_;

  // The platform view's picture recorder keyed off the view id, which contains any subsequent
  // operation until the next platform view or the end of the last leaf node in the layer tree.
  std::map<int64_t, std::unique_ptr<SkPictureRecorder>> picture_recorders_;

  fml::scoped_nsobject<FlutterMethodChannel> channel_;
  fml::scoped_nsobject<UIView> flutter_view_;
  fml::scoped_nsobject<UIViewController> flutter_view_controller_;
  std::map<std::string, fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>> factories_;
  std::map<int64_t, fml::scoped_nsobject<NSObject<FlutterPlatformView>>> views_;
  std::map<int64_t, fml::scoped_nsobject<FlutterTouchInterceptingView>> touch_interceptors_;
  // Mapping a platform view ID to the top most parent view (root_view) who is a direct child to
  // the `flutter_view_`.
  //
  // The platform view with the view ID is a child of the root view; If the platform view is not
  // clipped, and no clipping view is added, the root view will be the intercepting view.
  std::map<int64_t, fml::scoped_nsobject<UIView>> root_views_;
  // Mapping a platform view ID to its latest composition params.
  std::map<int64_t, EmbeddedViewParams> current_composition_params_;
  // Mapping a platform view ID to the count of the clipping operations that were applied to the
  // platform view last time it was composited.
  std::map<int64_t, int64_t> clip_count_;
  SkISize frame_size_;

  // The number of frames the rasterizer task runner will continue
  // to run on the platform thread after no platform view is rendered.
  //
  // Note: this is an arbitrary number that attempts to account for cases
  // where the platform view might be momentarily off the screen.
  static const int kDefaultMergedLeaseDuration = 10;

  // Method channel `OnDispose` calls adds the views to be disposed to this set to be disposed on
  // the next frame.
  std::unordered_set<int64_t> views_to_dispose_;

  // A vector of embedded view IDs according to their composition order.
  // The last ID in this vector belond to the that is composited on top of all others.
  std::vector<int64_t> composition_order_;

  // The latest composition order that was presented in Present().
  std::vector<int64_t> active_composition_order_;

  // Only compoiste platform views in this set.
  std::unordered_set<int64_t> views_to_recomposite_;

  // The FlutterPlatformViewGestureRecognizersBlockingPolicy for each type of platform view.
  std::map<std::string, FlutterPlatformViewGestureRecognizersBlockingPolicy>
      gesture_recognizers_blocking_policies;

  void OnCreate(FlutterMethodCall* call, FlutterResult& result);
  void OnDispose(FlutterMethodCall* call, FlutterResult& result);
  void OnAcceptGesture(FlutterMethodCall* call, FlutterResult& result);
  void OnRejectGesture(FlutterMethodCall* call, FlutterResult& result);
  // Dispose the views in `views_to_dispose_`.
  void DisposeViews();

  // Returns true if there are embedded views in the scene at current frame
  // Or there will be embedded views in the next frame.
  // TODO(cyanglaz): https://github.com/flutter/flutter/issues/56474
  // Make this method check if there are pending view operations instead.
  // Also rename it to `HasPendingViewOperations`.
  bool HasPlatformViewThisOrNextFrame();

  // Traverse the `mutators_stack` and return the number of clip operations.
  int CountClips(const MutatorsStack& mutators_stack);

  // Applies the mutators in the mutators_stack to the UIView chain that was constructed by
  // `ReconstructClipViewsChain`
  //
  // Clips are applied to the super view with a CALayer mask. Transforms are applied to the
  // current view that's at the head of the chain. For example the following mutators stack [T_1,
  // C_2, T_3, T_4, C_5, T_6] where T denotes a transform and C denotes a clip, will result in the
  // following UIView tree:
  //
  // C_2 -> C_5 -> PLATFORM_VIEW
  // (PLATFORM_VIEW is a subview of C_5 which is a subview of C_2)
  //
  // T_1 is applied to C_2, T_3 and T_4 are applied to C_5, and T_6 is applied to PLATFORM_VIEW.
  //
  // After each clip operation, we update the head to the super view of the current head.
  void ApplyMutators(const MutatorsStack& mutators_stack, UIView* embedded_view);
  void CompositeWithParams(int view_id, const EmbeddedViewParams& params);

  // Default to `false`.
  // If `true`, gpu thread and platform thread should be merged during |EndFrame|.
  // Always resets to `false` right after the threads are merged.
  bool merge_threads_ = false;
  // Allocates a new FlutterPlatformViewLayer if needed, draws the pixels within the rect from
  // the picture on the layer's canvas.
  std::shared_ptr<FlutterPlatformViewLayer> GetLayer(GrDirectContext* gr_context,
                                                     std::shared_ptr<IOSContext> ios_context,
                                                     sk_sp<SkPicture> picture,
                                                     SkRect rect,
                                                     int64_t view_id,
                                                     int64_t overlay_id);
  // Removes overlay views and platform views that aren't needed in the current frame.
  // Must run on the platform thread.
  void RemoveUnusedLayers();
  // Appends the overlay views and platform view and sets their z index based on the composition
  // order.
  void BringLayersIntoView(LayersMap layer_map);

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterPlatformViewsController);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
