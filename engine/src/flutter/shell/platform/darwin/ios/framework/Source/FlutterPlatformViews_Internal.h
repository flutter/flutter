// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"
#include "fml/task_runner.h"
#include "impeller/base/thread_safety.h"
#include "third_party/skia/include/core/SkRect.h"

#include <Metal/Metal.h>

#include "flutter/flow/surface.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/fml/trace_event.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewResponder.h"
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
@property(nonatomic, readonly) CGRect frame;

// Determines the blur intensity.
//
// It is set as the value of `inputRadius` of the `gaussianFilter` that is internally used.
@property(nonatomic, readonly) CGFloat blurRadius;

// This is the view to use to blur the PlatformView.
//
// It is a modified version of UIKit's `UIVisualEffectView`.
// The inputRadius can be customized and it doesn't add any color saturation to the blurred view.
@property(nonatomic, readonly) UIVisualEffectView* backdropFilterView;

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

// For testing only.
- (NSMutableArray*)backdropFilterSubviews;
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

  void UpdateViewState(UIView* flutter_view, SkRect rect, int64_t view_id, int64_t overlay_id);
};

/// @brief Storage for Overlay layers across frames.
///
/// Note: this class does not synchronize access to its layers or any layer removal. As it
/// is currently used, layers must be created on the platform thread but other methods of
/// it are called on the raster thread. This is safe as overlay layers are only ever added
/// while the raster thread is latched.
class FlutterPlatformViewLayerPool {
 public:
  FlutterPlatformViewLayerPool() = default;

  ~FlutterPlatformViewLayerPool() = default;

  /// @brief Gets a layer from the pool if available.
  ///
  /// The layer is marked as used until [RecycleLayers] is called.
  std::shared_ptr<FlutterPlatformViewLayer> GetNextLayer();

  /// @brief Create a new overlay layer.
  ///
  /// This method can only be called on the Platform thread.
  void CreateLayer(GrDirectContext* gr_context,
                   const std::shared_ptr<IOSContext>& ios_context,
                   MTLPixelFormat pixel_format);

  /// @brief Removes unused layers from the pool. Returns the unused layers.
  std::vector<std::shared_ptr<FlutterPlatformViewLayer>> RemoveUnusedLayers();

  /// @brief Marks the layers in the pool as available for reuse.
  void RecycleLayers();

  /// @brief The count of layers currently in the pool.
  size_t size() const;

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

  fml::WeakPtr<flutter::FlutterPlatformViewsController> GetWeakPtr();

  void SetTaskRunner(const fml::RefPtr<fml::TaskRunner>& platform_task_runner);

  void SetFlutterView(UIView* flutter_view) __attribute__((cf_audited_transfer));

  void SetFlutterViewController(UIViewController<FlutterViewResponder>* flutter_view_controller)
      __attribute__((cf_audited_transfer));

  UIViewController<FlutterViewResponder>* getFlutterViewController()
      __attribute__((cf_audited_transfer));

  void RegisterViewFactory(
      NSObject<FlutterPlatformViewFactory>* factory,
      NSString* factoryId,
      FlutterPlatformViewGestureRecognizersBlockingPolicy gestureRecognizerBlockingPolicy)
      __attribute__((cf_audited_transfer));

  // Called at the beginning of each frame.
  void BeginFrame(SkISize frame_size);

  // Indicates that we don't compisite any platform views or overlays during this frame.
  // Also reverts the composition_order_ to its original state at the beginning of the frame.
  void CancelFrame();

  // Runs on the raster thread.
  void PrerollCompositeEmbeddedView(int64_t view_id,
                                    std::unique_ptr<flutter::EmbeddedViewParams> params);

  size_t EmbeddedViewCount() const;

  size_t LayerPoolSize() const;

  // Returns the `FlutterPlatformView`'s `view` object associated with the view_id.
  //
  // If the `FlutterPlatformViewsController` does not contain any `FlutterPlatformView` object or
  // a `FlutterPlatformView` object associated with the view_id cannot be found, the method
  // returns nil.
  UIView* GetPlatformViewByID(int64_t view_id);

  // Returns the `FlutterTouchInterceptingView` with the view_id.
  //
  // If the `FlutterPlatformViewsController` does not contain any `FlutterPlatformView` object or
  // a `FlutterPlatformView` object associated with the view_id cannot be found, the method
  // returns nil.
  FlutterTouchInterceptingView* GetFlutterTouchInterceptingViewByID(int64_t view_id);

  // Runs on the raster thread.
  PostPrerollResult PostPrerollAction(
      const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger);

  // Runs on the raster thread.
  void EndFrame(bool should_resubmit_frame,
                const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger);

  // Return the Canvas for the overlay slice for the given platform view.
  //
  // Runs on the raster thread.
  DlCanvas* CompositeEmbeddedView(int64_t view_id);

  // Discards all platform views instances and auxiliary resources.
  //
  // Runs on the raster thread.
  void Reset();

  // Encode rendering for the Flutter overlay views and queue up perform platform view mutations.
  //
  // Runs on the raster thread.
  bool SubmitFrame(GrDirectContext* gr_context,
                   const std::shared_ptr<IOSContext>& ios_context,
                   std::unique_ptr<SurfaceFrame> frame);

  void OnMethodCall(FlutterMethodCall* call, FlutterResult result)
      __attribute__((cf_audited_transfer));

  // Returns the platform view id if the platform view (or any of its descendant view) is the first
  // responder. Returns -1 if no such platform view is found.
  long FindFirstResponderPlatformViewId();

  // Pushes backdrop filter mutation to the mutator stack of each visited platform view.
  void PushFilterToVisitedPlatformViews(const std::shared_ptr<const DlImageFilter>& filter,
                                        const SkRect& filter_rect);

  // Pushes the view id of a visted platform view to the list of visied platform views.
  void PushVisitedPlatformView(int64_t view_id) { visited_platform_views_.push_back(view_id); }

  // Visible for testing.
  void CompositeWithParams(int64_t view_id, const EmbeddedViewParams& params);

  const EmbeddedViewParams& GetCompositionParams(int64_t view_id) const {
    return current_composition_params_.find(view_id)->second;
  }

 private:
  struct LayerData {
    SkRect rect;
    int64_t view_id;
    int64_t overlay_id;
    std::shared_ptr<FlutterPlatformViewLayer> layer;
  };

  using LayersMap = std::unordered_map<int64_t, LayerData>;

  // Update the buffers and mutate the platform views in CATransaction.
  //
  // Runs on the platform thread.
  void PerformSubmit(const LayersMap& platform_view_layers,
                     std::unordered_map<int64_t, EmbeddedViewParams>& current_composition_params,
                     const std::unordered_set<int64_t>& views_to_recomposite,
                     const std::vector<int64_t>& composition_order,
                     const std::vector<std::shared_ptr<FlutterPlatformViewLayer>>& unused_layers,
                     const std::vector<std::unique_ptr<SurfaceFrame>>& surface_frames);

  /// @brief Populate any missing overlay layers.
  ///
  /// This requires posting a task to the platform thread and blocking on its completion.
  void CreateMissingOverlays(GrDirectContext* gr_context,
                             const std::shared_ptr<IOSContext>& ios_context,
                             size_t required_overlay_layers);

  void OnCreate(FlutterMethodCall* call, FlutterResult result) __attribute__((cf_audited_transfer));
  void OnDispose(FlutterMethodCall* call, FlutterResult result)
      __attribute__((cf_audited_transfer));
  void OnAcceptGesture(FlutterMethodCall* call, FlutterResult result)
      __attribute__((cf_audited_transfer));
  void OnRejectGesture(FlutterMethodCall* call, FlutterResult result)
      __attribute__((cf_audited_transfer));

  /// @brief Return all views to be disposed on the platform thread.
  std::vector<UIView*> GetViewsToDispose();

  void ClipViewSetMaskView(UIView* clipView) __attribute__((cf_audited_transfer));

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
                     const SkRect& bounding_rect) __attribute__((cf_audited_transfer));

  std::shared_ptr<FlutterPlatformViewLayer> GetExistingLayer();

  // Runs on the platform thread.
  void CreateLayer(GrDirectContext* gr_context,
                   const std::shared_ptr<IOSContext>& ios_context,
                   MTLPixelFormat pixel_format);

  // Removes overlay views and platform views that aren't needed in the current frame.
  // Must run on the platform thread.
  void RemoveUnusedLayers(
      const std::vector<std::shared_ptr<FlutterPlatformViewLayer>>& unused_layers,
      const std::vector<int64_t>& composition_order);

  // Appends the overlay views and platform view and sets their z index based on the composition
  // order.
  void BringLayersIntoView(const LayersMap& layer_map,
                           const std::vector<int64_t>& composition_order);

  // Resets the state of the frame.
  void ResetFrameState();

  // The pool of reusable view layers. The pool allows to recycle layer in each frame.
  std::unique_ptr<FlutterPlatformViewLayerPool> layer_pool_;

  // The platform view's |EmbedderViewSlice| keyed off the view id, which contains any subsequent
  // operation until the next platform view or the end of the last leaf node in the layer tree.
  //
  // The Slices are deleted by the FlutterPlatformViewsController.reset().
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices_;

  fml::scoped_nsobject<FlutterMethodChannel> channel_;
  fml::scoped_nsobject<UIView> flutter_view_;
  fml::scoped_nsobject<UIViewController<FlutterViewResponder>> flutter_view_controller_;
  fml::scoped_nsobject<FlutterClippingMaskViewPool> mask_view_pool_;
  std::unordered_map<std::string, fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>>
      factories_;

  // The FlutterPlatformViewGestureRecognizersBlockingPolicy for each type of platform view.
  std::unordered_map<std::string, FlutterPlatformViewGestureRecognizersBlockingPolicy>
      gesture_recognizers_blocking_policies_;

  /// The size of the current onscreen surface in physical pixels.
  SkISize frame_size_;

  /// The task runner for posting tasks to the platform thread.
  fml::RefPtr<fml::TaskRunner> platform_task_runner_;

  /// Each of the following structs stores part of the platform view hierarchy according to its
  /// ID.
  ///
  /// This data must only be accessed on the platform thread.
  struct PlatformViewData {
    fml::scoped_nsobject<NSObject<FlutterPlatformView>> view;
    fml::scoped_nsobject<FlutterTouchInterceptingView> touch_interceptor;
    fml::scoped_nsobject<UIView> root_view;
  };

  /// This data must only be accessed on the platform thread.
  std::unordered_map<int64_t, PlatformViewData> platform_views_;

  /// The composition parameters for each platform view.
  ///
  /// This state is only modified on the raster thread.
  std::unordered_map<int64_t, EmbeddedViewParams> current_composition_params_;

  /// Method channel `OnDispose` calls adds the views to be disposed to this set to be disposed on
  /// the next frame.
  ///
  /// This state is modified on both the platform and raster thread.
  std::unordered_set<int64_t> views_to_dispose_;

  /// view IDs in composition order.
  ///
  /// This state is only modified on the raster thread.
  std::vector<int64_t> composition_order_;

  /// platform view IDs visited during layer tree composition.
  ///
  /// This state is only modified on the raster thread.
  std::vector<int64_t> visited_platform_views_;

  /// Only composite platform views in this set.
  ///
  /// This state is only modified on the raster thread.
  std::unordered_set<int64_t> views_to_recomposite_;

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  /// A set to keep track of embedded views that do not have (0, 0) origin.
  /// An insertion triggers a warning message about non-zero origin logged on the debug console.
  /// See https://github.com/flutter/flutter/issues/109700 for details.
  std::unordered_set<int64_t> non_zero_origin_views_;
#endif

  /// @brief The composition order from the previous thread.
  ///
  /// Only accessed from the platform thread.
  std::vector<int64_t> previous_composition_order_;

  /// Whether the previous frame had any platform views in active composition order.
  ///
  /// This state is tracked so that the first frame after removing the last platform view
  /// runs through the platform view rendering code path, giving us a chance to remove the
  /// platform view from the UIView hierarchy.
  ///
  /// Only accessed from the raster thread.
  bool had_platform_views_ = false;

  // WeakPtrFactory must be the last member.
  std::unique_ptr<fml::WeakPtrFactory<FlutterPlatformViewsController>> weak_factory_;

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

// Sets flutterAccessibilityContainer as this view's accessibilityContainer.
@property(nonatomic, retain) id flutterAccessibilityContainer;
@end

@interface UIView (FirstResponder)
// Returns YES if a view or any of its descendant view is the first responder. Returns NO otherwise.
@property(nonatomic, readonly) BOOL flt_hasFirstResponderInViewHierarchySubtree;
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
