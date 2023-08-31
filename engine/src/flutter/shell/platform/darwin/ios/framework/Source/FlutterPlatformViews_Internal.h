// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/shell.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlugin.h"
#import "flutter/shell/platform/darwin/ios/ios_context.h"

@class FlutterTouchInterceptingView;

// A UIView that acts as a clipping mask for the |ChildClippingView|.
//
// On the [UIView drawRect:] method, this view performs a series of clipping operations and sets the
// alpha channel to the final resulting area to be 1; it also sets the "clipped out" area's alpha
// channel to be 0.
//
// When a UIView sets a |FlutterClippingMaskView| as its `maskView`, the alpha channel of the UIView
// is replaced with the alpha channel of the |FlutterClippingMaskView|.
@interface FlutterClippingMaskView : UIView

- (instancetype)initWithFrame:(CGRect)frame screenScale:(CGFloat)screenScale;

- (void)reset;

// Adds a clip rect operation to the queue.
//
// The `clipSkRect` is transformed with the `matrix` before adding to the queue.
- (void)clipRect:(const SkRect&)clipSkRect matrix:(const SkMatrix&)matrix;

// Adds a clip rrect operation to the queue.
//
// The `clipSkRRect` is transformed with the `matrix` before adding to the queue.
- (void)clipRRect:(const SkRRect&)clipSkRRect matrix:(const SkMatrix&)matrix;

// Adds a clip path operation to the queue.
//
// The `path` is transformed with the `matrix` before adding to the queue.
- (void)clipPath:(const SkPath&)path matrix:(const SkMatrix&)matrix;

@end

// A pool that provides |FlutterClippingMaskView|s.
//
// The pool has a capacity that can be set in the initializer.
// When requesting a FlutterClippingMaskView, the pool will first try to reuse an available maskView
// in the pool. If there are none available, a new FlutterClippingMaskView is constructed. If the
// capacity is reached, the newly constructed FlutterClippingMaskView is not added to the pool.
//
// Call |insertViewToPoolIfNeeded:| to return a maskView to the pool.
@interface FlutterClippingMaskViewPool : NSObject

// Initialize the pool with `capacity`. When the `capacity` is reached, a FlutterClippingMaskView is
// constructed when requested, and it is not added to the pool.
- (instancetype)initWithCapacity:(NSInteger)capacity;

// Reuse a maskView from the pool, or allocate a new one.
- (FlutterClippingMaskView*)getMaskViewWithFrame:(CGRect)frame;

// Insert the `maskView` into the pool.
- (void)insertViewToPoolIfNeeded:(FlutterClippingMaskView*)maskView;

@end

// An object represents a blur filter.
//
// This object produces a `backdropFilterView`.
// To blur a View, add `backdropFilterView` as a subView of the View.
@interface PlatformViewFilter : NSObject

// Determines the rect of the blur effect in the coordinate system of `backdropFilterView`'s
// parentView.
@property(assign, nonatomic, readonly) CGRect frame;

// Determines the blur intensity.
//
// It is set as the value of `inputRadius` of the `gaussianFilter` that is internally used.
@property(assign, nonatomic, readonly) CGFloat blurRadius;

// This is the view to use to blur the PlatformView.
//
// It is a modified version of UIKit's `UIVisualEffectView`.
// The inputRadius can be customized and it doesn't add any color saturation to the blurred view.
@property(nonatomic, retain, readonly) UIVisualEffectView* backdropFilterView;

// For testing only.
+ (void)resetPreparation;

- (instancetype)init NS_UNAVAILABLE;

// Initialize the filter object.
//
// The `frame` determines the rect of the blur effect in the coordinate system of
// `backdropFilterView`'s parentView. The `blurRadius` determines the blur intensity. It is set as
// the value of `inputRadius` of the `gaussianFilter` that is internally used. The
// `UIVisualEffectView` is the view that is used to add the blur effects. It is modified to become
// `backdropFilterView`, which better supports the need of Flutter.
//
// Note: if the implementation of UIVisualEffectView changes in a way that affects the
// implementation in `PlatformViewFilter`, this method will return nil.
- (instancetype)initWithFrame:(CGRect)frame
                   blurRadius:(CGFloat)blurRadius
             visualEffectView:(UIVisualEffectView*)visualEffectView NS_DESIGNATED_INITIALIZER;

@end

// The parent view handles clipping to its subViews.
@interface ChildClippingView : UIView

// Applies blur backdrop filters to the ChildClippingView with blur values from
// filters.
- (void)applyBlurBackdropFilters:(NSArray<PlatformViewFilter*>*)filters;

@end

namespace flutter {
// Converts a SkMatrix to CATransform3D.
// Certain fields are ignored in CATransform3D since SkMatrix is 3x3 and CATransform3D is 4x4.
CATransform3D GetCATransform3DFromSkMatrix(const SkMatrix& matrix);

// Reset the anchor of `layer` to match the transform operation from flow.
// The position of the `layer` should be unchanged after resetting the anchor.
void ResetAnchor(CALayer* layer);

CGRect GetCGRectFromSkRect(const SkRect& clipSkRect);
BOOL BlurRadiusEqualToBlurRadius(CGFloat radius1, CGFloat radius2);

class IOSContextGL;
class IOSSurface;

struct FlutterPlatformViewLayer {
  FlutterPlatformViewLayer(const fml::scoped_nsobject<UIView>& overlay_view,
                           const fml::scoped_nsobject<UIView>& overlay_view_wrapper,
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
  std::shared_ptr<FlutterPlatformViewLayer> GetLayer(
      GrDirectContext* gr_context,
      const std::shared_ptr<IOSContext>& ios_context);

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
  explicit FlutterPlatformViewsController(bool enable_impeller);

  ~FlutterPlatformViewsController();

  fml::WeakPtr<flutter::FlutterPlatformViewsController> GetWeakPtr();

  void SetFlutterView(UIView* flutter_view);

  void SetFlutterViewController(UIViewController* flutter_view_controller);

  UIViewController* getFlutterViewController();

  void RegisterViewFactory(
      NSObject<FlutterPlatformViewFactory>* factory,
      NSString* factoryId,
      FlutterPlatformViewGestureRecognizersBlockingPolicy gestureRecognizerBlockingPolicy);

  // Called at the beginning of each frame.
  void BeginFrame(SkISize frame_size);

  // Indicates that we don't compisite any platform views or overlays during this frame.
  // Also reverts the composition_order_ to its original state at the beginning of the frame.
  void CancelFrame();

  void PrerollCompositeEmbeddedView(int64_t view_id,
                                    std::unique_ptr<flutter::EmbeddedViewParams> params);

  size_t EmbeddedViewCount();

  // Returns the `FlutterPlatformView`'s `view` object associated with the view_id.
  //
  // If the `FlutterPlatformViewsController` does not contain any `FlutterPlatformView` object or
  // a `FlutterPlatformView` object asscociated with the view_id cannot be found, the method
  // returns nil.
  UIView* GetPlatformViewByID(int64_t view_id);

  PostPrerollResult PostPrerollAction(
      const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger);

  void EndFrame(bool should_resubmit_frame,
                const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger);

  DlCanvas* CompositeEmbeddedView(int64_t view_id);

  // The rect of the platform view at index view_id. This rect has been translated into the
  // host view coordinate system. Units are device screen pixels.
  SkRect GetPlatformViewRect(int64_t view_id);

  // Discards all platform views instances and auxiliary resources.
  void Reset();

  bool SubmitFrame(GrDirectContext* gr_context,
                   const std::shared_ptr<IOSContext>& ios_context,
                   std::unique_ptr<SurfaceFrame> frame);

  void OnMethodCall(FlutterMethodCall* call, FlutterResult& result);

  // Returns the platform view id if the platform view (or any of its descendant view) is the first
  // responder. Returns -1 if no such platform view is found.
  long FindFirstResponderPlatformViewId();

  // Pushes backdrop filter mutation to the mutator stack of each visited platform view.
  void PushFilterToVisitedPlatformViews(const std::shared_ptr<const DlImageFilter>& filter,
                                        const SkRect& filter_rect);

  // Pushes the view id of a visted platform view to the list of visied platform views.
  void PushVisitedPlatformView(int64_t view_id) { visited_platform_views_.push_back(view_id); }

 private:
  static const size_t kMaxLayerAllocations = 2;

  using LayersMap = std::map<int64_t, std::vector<std::shared_ptr<FlutterPlatformViewLayer>>>;

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

  void ClipViewSetMaskView(UIView* clipView);

  // Applies the mutators in the mutators_stack to the UIView chain that was constructed by
  // `ReconstructClipViewsChain`
  //
  // Clips are applied to the `embedded_view`'s super view(|ChildClippingView|) using a
  // |FlutterClippingMaskView|. Transforms are applied to `embedded_view`
  //
  // The `bounding_rect` is the final bounding rect of the PlatformView
  // (EmbeddedViewParams::finalBoundingRect). If a clip mutator's rect contains the final bounding
  // rect of the PlatformView, the clip mutator is not applied for performance optimization.
  void ApplyMutators(const MutatorsStack& mutators_stack,
                     UIView* embedded_view,
                     const SkRect& bounding_rect);

  void CompositeWithParams(int64_t view_id, const EmbeddedViewParams& params);

  // Allocates a new FlutterPlatformViewLayer if needed, draws the pixels within the rect from
  // the picture on the layer's canvas.
  std::shared_ptr<FlutterPlatformViewLayer> GetLayer(GrDirectContext* gr_context,
                                                     const std::shared_ptr<IOSContext>& ios_context,
                                                     EmbedderViewSlice* slice,
                                                     SkRect rect,
                                                     int64_t view_id,
                                                     int64_t overlay_id);
  // Removes overlay views and platform views that aren't needed in the current frame.
  // Must run on the platform thread.
  void RemoveUnusedLayers();
  // Appends the overlay views and platform view and sets their z index based on the composition
  // order.
  void BringLayersIntoView(LayersMap layer_map);

  // Begin a CATransaction.
  // This transaction needs to be balanced with |CommitCATransactionIfNeeded|.
  void BeginCATransaction();

  // Commit a CATransaction if |BeginCATransaction| has been called during the frame.
  void CommitCATransactionIfNeeded();

  // Resets the state of the frame.
  void ResetFrameState();

  bool enable_impeller_ = true;

  // The pool of reusable view layers. The pool allows to recycle layer in each frame.
  std::unique_ptr<FlutterPlatformViewLayerPool> layer_pool_;

  // The platform view's |EmbedderViewSlice| keyed off the view id, which contains any subsequent
  // operation until the next platform view or the end of the last leaf node in the layer tree.
  //
  // The Slices are deleted by the FlutterPlatformViewsController.reset().
  std::map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices_;

  fml::scoped_nsobject<FlutterMethodChannel> channel_;
  fml::scoped_nsobject<UIView> flutter_view_;
  fml::scoped_nsobject<UIViewController> flutter_view_controller_;
  fml::scoped_nsobject<FlutterClippingMaskViewPool> mask_view_pool_;
  std::map<std::string, fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>> factories_;
  std::map<int64_t, fml::scoped_nsobject<NSObject<FlutterPlatformView>>> views_;
  std::map<int64_t, fml::scoped_nsobject<FlutterTouchInterceptingView>> touch_interceptors_;
  // Mapping a platform view ID to the top most parent view (root_view) of a platform view. In
  // |SubmitFrame|, root_views_ are added to flutter_view_ as child views.
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

  // A vector of visited platform view IDs.
  std::vector<int64_t> visited_platform_views_;

  // The latest composition order that was presented in Present().
  std::vector<int64_t> active_composition_order_;

  // Only compoiste platform views in this set.
  std::unordered_set<int64_t> views_to_recomposite_;

  // The FlutterPlatformViewGestureRecognizersBlockingPolicy for each type of platform view.
  std::map<std::string, FlutterPlatformViewGestureRecognizersBlockingPolicy>
      gesture_recognizers_blocking_policies;

  bool catransaction_added_ = false;

  // WeakPtrFactory must be the last member.
  std::unique_ptr<fml::WeakPtrFactory<FlutterPlatformViewsController>> weak_factory_;

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  // A set to keep track of embedded views that does not have (0, 0) origin.
  // An insertion triggers a warning message about non-zero origin logged on the debug console.
  // See https://github.com/flutter/flutter/issues/109700 for details.
  std::unordered_set<int64_t> non_zero_origin_views_;
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterPlatformViewsController);
};

}  // namespace flutter

// A UIView that is used as the parent for embedded UIViews.
//
// This view has 2 roles:
// 1. Delay or prevent touch events from arriving the embedded view.
// 2. Dispatching all events that are hittested to the embedded view to the FlutterView.
@interface FlutterTouchInterceptingView : UIView
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView
             platformViewsController:
                 (fml::WeakPtr<flutter::FlutterPlatformViewsController>)platformViewsController
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)blockingPolicy;

// Stop delaying any active touch sequence (and let it arrive the embedded view).
- (void)releaseGesture;

// Prevent the touch sequence from ever arriving to the embedded view.
- (void)blockGesture;

// Get embedded view
- (UIView*)embeddedView;
@end

@interface UIView (FirstResponder)
// Returns YES if a view or any of its descendant view is the first responder. Returns NO otherwise.
@property(nonatomic, readonly) BOOL flt_hasFirstResponderInViewHierarchySubtree;
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
