// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"

// A UIView that is used as the parent for embedded UIViews.
//
// This view has 2 roles:
// 1. Delay or prevent touch events from arriving the embedded view.
// 2. Dispatching all events that are hittested to the embedded view to the FlutterView.
@interface FlutterTouchInterceptingView : UIView
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView
               flutterViewController:(UIViewController*)flutterViewController;

// Stop delaying any active touch sequence (and let it arrive the embedded view).
- (void)releaseGesture;

// Prevent the touch sequence from ever arriving to the embedded view.
- (void)blockGesture;
@end

// The parent view handles clipping to its subviews.
@interface ChildClippingView : UIView

// Performs the clipping based on the type.
//
// The `type` must be one of the 3: clip_rect, clip_rrect, clip_path.
- (void)setClip:(flutter::MutatorType)type
           rect:(const SkRect&)rect
          rrect:(const SkRRect&)rrect
           path:(const SkPath&)path;

@end

namespace flutter {
// Converts a SkMatrix to CATransform3D.
// Certain fields are ignored in CATransform3D since SkMatrix is 3x3 and CATransform3D is 4x4.
CATransform3D GetCATransform3DFromSkMatrix(const SkMatrix& matrix);

// Reset the anchor of `layer` to match the tranform operation from flow.
// The position of the `layer` should be unchanged after resetting the anchor.
void ResetAnchor(CALayer* layer);

class IOSGLContext;
class IOSSurface;

struct FlutterPlatformViewLayer {
  FlutterPlatformViewLayer(fml::scoped_nsobject<UIView> overlay_view,
                           std::unique_ptr<IOSSurface> ios_surface,
                           std::unique_ptr<Surface> surface);

  ~FlutterPlatformViewLayer();

  fml::scoped_nsobject<UIView> overlay_view;
  std::unique_ptr<IOSSurface> ios_surface;
  std::unique_ptr<Surface> surface;
};

class FlutterPlatformViewsController {
 public:
  FlutterPlatformViewsController();

  ~FlutterPlatformViewsController();

  void SetFlutterView(UIView* flutter_view);

  void SetFlutterViewController(UIViewController* flutter_view_controller);

  void RegisterViewFactory(NSObject<FlutterPlatformViewFactory>* factory, NSString* factoryId);

  void SetFrameSize(SkISize frame_size);

  void CancelFrame();

  void PrerollCompositeEmbeddedView(int view_id,
                                    std::unique_ptr<flutter::EmbeddedViewParams> params);

  // Returns the `FlutterPlatformView` object associated with the view_id.
  //
  // If the `FlutterPlatformViewsController` does not contain any `FlutterPlatformView` object or
  // a `FlutterPlatformView` object asscociated with the view_id cannot be found, the method
  // returns nil.
  NSObject<FlutterPlatformView>* GetPlatformViewByID(int view_id);

  PostPrerollResult PostPrerollAction(fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger);

  std::vector<SkCanvas*> GetCurrentCanvases();

  SkCanvas* CompositeEmbeddedView(int view_id);

  // Discards all platform views instances and auxiliary resources.
  void Reset();

  bool SubmitFrame(GrContext* gr_context, std::shared_ptr<IOSGLContext> gl_context);

  void OnMethodCall(FlutterMethodCall* call, FlutterResult& result);

 private:
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
  std::map<int64_t, std::unique_ptr<FlutterPlatformViewLayer>> overlays_;
  // The GrContext that is currently used by all of the overlay surfaces.
  // We track this to know when the GrContext for the Flutter app has changed
  // so we can update the overlays with the new context.
  GrContext* overlays_gr_context_;
  SkISize frame_size_;

  // This is the number of frames the task runners will stay
  // merged after a frame where we see a mutation to the embedded views.
  // Note: This number was arbitrarily picked. The rationale being
  // merge-unmerge are not zero cost operations. To account for cases
  // like animating platform views, we picked it to be > 2, as we would
  // want to avoid merge-unmerge during each frame with a mutation.
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

  std::map<int64_t, std::unique_ptr<SkPictureRecorder>> picture_recorders_;

  void OnCreate(FlutterMethodCall* call, FlutterResult& result);
  void OnDispose(FlutterMethodCall* call, FlutterResult& result);
  void OnAcceptGesture(FlutterMethodCall* call, FlutterResult& result);
  void OnRejectGesture(FlutterMethodCall* call, FlutterResult& result);

  void DetachUnusedLayers();
  // Dispose the views in `views_to_dispose_`.
  void DisposeViews();
  void EnsureOverlayInitialized(int64_t overlay_id,
                                std::shared_ptr<IOSGLContext> gl_context,
                                GrContext* gr_context);

  // This will return true after pre-roll if any of the embedded views
  // have mutated for last layer tree.
  bool HasPendingViewOperations();

  // Traverse the `mutators_stack` and return the number of clip operations.
  int CountClips(const MutatorsStack& mutators_stack);

  // Make sure that platform_view has exactly clip_count ChildClippingView ancestors.
  //
  // Existing ChildClippingViews are re-used. If there are currently more ChildClippingView
  // ancestors than needed, the extra views are detached. If there are less ChildClippingView
  // ancestors than needed, new ChildClippingViews will be added.
  //
  // If head_clip_view was attached as a subview to FlutterView, the head of the newly constructed
  // ChildClippingViews chain is attached to FlutterView in the same position.
  //
  // Returns the new head of the clip views chain.
  UIView* ReconstructClipViewsChain(int number_of_clips,
                                    UIView* platform_view,
                                    UIView* head_clip_view);

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

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterPlatformViewsController);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
