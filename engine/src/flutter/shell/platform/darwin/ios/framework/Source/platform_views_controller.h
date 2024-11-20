// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_PLATFORM_VIEWS_CONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_PLATFORM_VIEWS_CONTROLLER_H_

#include <Metal/Metal.h>
#include <unordered_map>
#include <unordered_set>

#include "flutter/flow/surface.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/thread_safety.h"
#include "third_party/skia/include/core/SkRect.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewResponder.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/overlay_layer_pool.h"
#import "flutter/shell/platform/darwin/ios/ios_context.h"

@class FlutterTouchInterceptingView;
@class FlutterClippingMaskViewPool;

namespace flutter {

/// @brief Composites Flutter UI and overlay layers alongside embedded UIViews.
class PlatformViewsController {
 public:
  PlatformViewsController();

  ~PlatformViewsController() = default;

  /// @brief Retrieve a weak pointer to this controller.
  fml::WeakPtr<flutter::PlatformViewsController> GetWeakPtr();

  /// @brief Set the platform task runner used to post rendering tasks.
  void SetTaskRunner(const fml::RefPtr<fml::TaskRunner>& platform_task_runner);

  /// @brief Set the flutter view.
  void SetFlutterView(UIView* flutter_view) __attribute__((cf_audited_transfer));

  /// @brief Set the flutter view controller.
  void SetFlutterViewController(UIViewController<FlutterViewResponder>* flutter_view_controller)
      __attribute__((cf_audited_transfer));

  /// @brief Retrieve the view controller.
  UIViewController<FlutterViewResponder>* GetFlutterViewController()
      __attribute__((cf_audited_transfer));

  /// @brief set the factory used to construct embedded UI Views.
  void RegisterViewFactory(
      NSObject<FlutterPlatformViewFactory>* factory,
      NSString* factoryId,
      FlutterPlatformViewGestureRecognizersBlockingPolicy gestureRecognizerBlockingPolicy)
      __attribute__((cf_audited_transfer));

  /// @brief Mark the beginning of a frame and record the size of the onscreen.
  void BeginFrame(SkISize frame_size);

  /// @brief Cancel the current frame, indicating that no platform views are composited.
  ///
  /// Additionally, reverts the composition order to its original state at the beginning of the
  /// frame.
  void CancelFrame();

  /// @brief Record a platform view in the layer tree to be rendered, along with the positioning and
  ///        mutator parameters.
  ///
  /// Called from the raster thread.
  void PrerollCompositeEmbeddedView(int64_t view_id,
                                    std::unique_ptr<flutter::EmbeddedViewParams> params);

  /// @brief Returns the`FlutterTouchInterceptingView` with the provided view_id.
  ///
  /// Returns nil if there is no platform view with the provided id. Called
  /// from the platform thread.
  FlutterTouchInterceptingView* GetFlutterTouchInterceptingViewByID(int64_t view_id);

  /// @brief Determine if thread merging is required after prerolling platform views.
  ///
  /// Called from the raster thread.
  PostPrerollResult PostPrerollAction(
      const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger,
      bool impeller_enabled);

  /// @brief Mark the end of a compositor frame.
  ///
  /// May determine changes are required to the thread merging state.
  /// Called from the raster thread.
  void EndFrame(bool should_resubmit_frame,
                const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger,
                bool impeller_enabled);

  /// @brief Returns the Canvas for the overlay slice for the given platform view.
  ///
  /// Called from the raster thread.
  DlCanvas* CompositeEmbeddedView(int64_t view_id);

  /// @brief Discards all platform views instances and auxiliary resources.
  ///
  /// Called from the raster thread.
  void Reset();

  /// @brief Encode rendering for the Flutter overlay views and queue up perform platform view
  /// mutations.
  ///
  /// Called from the raster thread.
  bool SubmitFrame(GrDirectContext* gr_context,
                   const std::shared_ptr<IOSContext>& ios_context,
                   std::unique_ptr<SurfaceFrame> frame);

  /// @brief Handler for platform view message channels.
  void OnMethodCall(FlutterMethodCall* call, FlutterResult result)
      __attribute__((cf_audited_transfer));

  /// @brief Returns the platform view id if the platform view (or any of its descendant view) is
  /// the first responder.
  ///
  /// Returns -1 if no such platform view is found.
  long FindFirstResponderPlatformViewId();

  /// @brief Pushes backdrop filter mutation to the mutator stack of each visited platform view.
  void PushFilterToVisitedPlatformViews(const std::shared_ptr<DlImageFilter>& filter,
                                        const SkRect& filter_rect);

  /// @brief Pushes the view id of a visted platform view to the list of visied platform views.
  void PushVisitedPlatformView(int64_t view_id) { visited_platform_views_.push_back(view_id); }

  // visible for testing.
  size_t EmbeddedViewCount() const;

  // visible for testing.
  size_t LayerPoolSize() const;

  // visible for testing.
  // Returns the `FlutterPlatformView`'s `view` object associated with the view_id.
  //
  // If the `PlatformViewsController` does not contain any `FlutterPlatformView` object or
  // a `FlutterPlatformView` object associated with the view_id cannot be found, the method
  // returns nil.
  UIView* GetPlatformViewByID(int64_t view_id);

  // Visible for testing.
  void CompositeWithParams(int64_t view_id, const EmbeddedViewParams& params);

  // Visible for testing.
  const EmbeddedViewParams& GetCompositionParams(int64_t view_id) const {
    return current_composition_params_.find(view_id)->second;
  }

 private:
  PlatformViewsController(const PlatformViewsController&) = delete;
  PlatformViewsController& operator=(const PlatformViewsController&) = delete;

  struct LayerData {
    SkRect rect;
    int64_t view_id;
    int64_t overlay_id;
    std::shared_ptr<OverlayLayer> layer;
  };

  using LayersMap = std::unordered_map<int64_t, LayerData>;

  // Update the buffers and mutate the platform views in CATransaction.
  //
  // Runs on the platform thread.
  void PerformSubmit(const LayersMap& platform_view_layers,
                     std::unordered_map<int64_t, EmbeddedViewParams>& current_composition_params,
                     const std::unordered_set<int64_t>& views_to_recomposite,
                     const std::vector<int64_t>& composition_order,
                     const std::vector<std::shared_ptr<OverlayLayer>>& unused_layers,
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

  std::shared_ptr<OverlayLayer> GetExistingLayer();

  // Runs on the platform thread.
  void CreateLayer(GrDirectContext* gr_context,
                   const std::shared_ptr<IOSContext>& ios_context,
                   MTLPixelFormat pixel_format);

  // Removes overlay views and platform views that aren't needed in the current frame.
  // Must run on the platform thread.
  void RemoveUnusedLayers(const std::vector<std::shared_ptr<OverlayLayer>>& unused_layers,
                          const std::vector<int64_t>& composition_order);

  // Appends the overlay views and platform view and sets their z index based on the composition
  // order.
  void BringLayersIntoView(const LayersMap& layer_map,
                           const std::vector<int64_t>& composition_order);

  // Resets the state of the frame.
  void ResetFrameState();

  // The pool of reusable view layers. The pool allows to recycle layer in each frame.
  std::unique_ptr<OverlayLayerPool> layer_pool_;

  // The platform view's |EmbedderViewSlice| keyed off the view id, which contains any subsequent
  // operation until the next platform view or the end of the last leaf node in the layer tree.
  //
  // The Slices are deleted by the PlatformViewsController.reset().
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices_;

  UIView* flutter_view_;
  UIViewController<FlutterViewResponder>* flutter_view_controller_;
  FlutterClippingMaskViewPool* mask_view_pool_;
  std::unordered_map<std::string, NSObject<FlutterPlatformViewFactory>*> factories_;

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
    NSObject<FlutterPlatformView>* view;
    FlutterTouchInterceptingView* touch_interceptor;
    UIView* root_view;
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
  std::unique_ptr<fml::WeakPtrFactory<PlatformViewsController>> weak_factory_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_PLATFORM_VIEWS_CONTROLLER_H_
