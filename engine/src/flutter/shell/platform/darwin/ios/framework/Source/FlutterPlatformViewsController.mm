// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"
#include "display_list/geometry/dl_geometry_types.h"
#include "impeller/geometry/rounding_radii.h"

#include "flutter/display_list/effects/image_filters/dl_blur_image_filter.h"
#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"
#include "flutter/flow/surface_frame.h"
#include "flutter/flow/view_slicer.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterOverlayView.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/overlay_layer_pool.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"

using flutter::DlISize;
using flutter::DlMatrix;
using flutter::DlRect;
using flutter::DlRoundRect;

static constexpr NSUInteger kFlutterClippingMaskViewPoolCapacity = 5;

static NSString* const kGestureBlockingPolicyEagerValue = @"eager";
static NSString* const kGestureBlockingPolicyWaitUntilTouchesEndedValue = @"waitUntilTouchesEnded";
static NSString* const kGestureBlockingPolicyDoNotBlockGesture = @"doNotBlockGesture";
static NSString* const kGestureBlockingPolicyFallbackToPluginDefault = @"fallbackToPluginDefault";

struct LayerData {
  DlRect rect;
  int64_t view_id = 0;
  int64_t overlay_id = 0;
  std::shared_ptr<flutter::OverlayLayer> layer;
};
using LayersMap = std::unordered_map<int64_t, LayerData>;

// Converts a DlMatrix to CATransform3D.
static CATransform3D GetCATransform3DFromDlMatrix(const DlMatrix& matrix) {
  CATransform3D transform = CATransform3DIdentity;
  transform.m11 = matrix.m[0];
  transform.m12 = matrix.m[1];
  transform.m13 = matrix.m[2];
  transform.m14 = matrix.m[3];

  transform.m21 = matrix.m[4];
  transform.m22 = matrix.m[5];
  transform.m23 = matrix.m[6];
  transform.m24 = matrix.m[7];

  transform.m31 = matrix.m[8];
  transform.m32 = matrix.m[9];
  transform.m33 = matrix.m[10];
  transform.m34 = matrix.m[11];

  transform.m41 = matrix.m[12];
  transform.m42 = matrix.m[13];
  transform.m43 = matrix.m[14];
  transform.m44 = matrix.m[15];
  return transform;
}

// Reset the anchor of `layer` to match the transform operation from flow.
//
// The position of the `layer` should be unchanged after resetting the anchor.
static void ResetAnchor(CALayer* layer) {
  // Flow uses (0, 0) to apply transform matrix so we need to match that in Quartz.
  layer.anchorPoint = CGPointZero;
  layer.position = CGPointZero;
}

static CGRect GetCGRectFromDlRect(const DlRect& clipDlRect) {
  return CGRectMake(clipDlRect.GetLeft(),   //
                    clipDlRect.GetTop(),    //
                    clipDlRect.GetWidth(),  //
                    clipDlRect.GetHeight());
}

@interface FlutterPlatformViewsController ()

// The pool of reusable view layers. The pool allows to recycle layer in each frame.
@property(nonatomic, readonly) flutter::OverlayLayerPool* layerPool;

// The platform view's |EmbedderViewSlice| keyed off the view id, which contains any subsequent
// operation until the next platform view or the end of the last leaf node in the layer tree.
//
// The Slices are deleted by the PlatformViewsController.reset().
@property(nonatomic, readonly)
    std::unordered_map<int64_t, std::unique_ptr<flutter::EmbedderViewSlice>>& slices;

@property(nonatomic, readonly) FlutterClippingMaskViewPool* maskViewPool;

@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, NSObject<FlutterPlatformViewFactory>*>* factories;

// The FlutterPlatformViewGestureRecognizersBlockingPolicy for each type of platform view, boxed in
// an NSNumber.
@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, NSNumber*>* gestureRecognizersBlockingPoliciesByType;

/// The size of the current onscreen surface in physical pixels.
@property(nonatomic, assign) DlISize frameSize;

/// The task runner for posting tasks to the platform thread.
@property(nonatomic, readonly) FlutterFMLTaskRunner* platformTaskRunner;

/// The platform views keyed by view ID.
///
/// This data must only be accessed on the platform thread.
@property(nonatomic, readonly)
    NSMutableDictionary<NSNumber*, FlutterPlatformViewInfo*>* platformViews;

/// The composition parameters for each platform view in the current frame, keyed by view ID.
/// Cleared at the start of each frame in `resetFrameState`.
///
/// This state is only modified on the raster thread.
@property(nonatomic, readonly)
    std::unordered_map<int64_t, flutter::EmbeddedViewParams>& currentCompositionParams;

/// The composition parameters submitted for each platform view in the previous frame, indexed by
/// view ID. Views will be recomposited in `submitFrame:` if their current parameters differ from
/// this mapping, or if there was no entry.
///
/// When a view is recreated under a disposed ID, it will not be mapped. This is to ensure that it
/// is composited even if the view is recreated with the same parameters. `onCreate:` rejects any ID
/// that is still in `platformViews`. `computeViewsToDisposeWithCompositionOrder:` removes an ID
/// only when presenting a frame that no longer includes that view.
///
/// This state is only modified on the raster thread.
@property(nonatomic, readonly)
    std::unordered_map<int64_t, flutter::EmbeddedViewParams>& previousCompositionParams;

/// The IDs of views to be disposed, as requested via the `dispose` method channel call.
///
/// These will be removed from the view hierarchy in `performSubmit:`, in the same `CATransaction`
/// that presents the next frame, or deferred to a later frame while the view is still in the
/// composition order.
///
/// This state must only be accessed on the platform thread.
@property(nonatomic, readonly) NSMutableSet<NSNumber*>* viewsToDispose;

/// view IDs in composition order.
///
/// This state is only modified on the raster thread.
@property(nonatomic, readonly) std::vector<int64_t>& compositionOrder;

/// platform view IDs visited during layer tree composition.
///
/// This state is only modified on the raster thread.
@property(nonatomic, readonly) std::vector<int64_t>& visitedPlatformViews;

/// Whether the previous frame had any platform views in active composition order.
///
/// This state is tracked so that the first frame after removing the last platform view
/// runs through the platform view rendering code path, giving us a chance to remove the
/// platform view from the UIView hierarchy.
///
/// Only accessed from the raster thread.
@property(nonatomic, assign) BOOL hadPlatformViews;

/// Whether blurred backdrop filters can be applied.
///
/// Defaults to YES, but becomes NO if blurred backdrop filters cannot be applied.
@property(nonatomic, assign) BOOL canApplyBlurBackdrop;

/// Populate any missing overlay layers.
///
/// This requires posting a task to the platform thread and blocking on its completion.
- (void)createMissingOverlays:(size_t)requiredOverlayLayers
               withIosContext:(const std::shared_ptr<flutter::IOSContext>&)iosContext;

/// Update the buffers and mutate the platform views in CATransaction on the platform thread.
- (void)performSubmit:(const LayersMap&)platformViewLayers
    currentCompositionParams:
        (std::unordered_map<int64_t, flutter::EmbeddedViewParams>&)currentCompositionParams
          viewsToRecomposite:(const std::unordered_set<int64_t>&)viewsToRecomposite
            compositionOrder:(const std::vector<int64_t>&)compositionOrder
                unusedLayers:
                    (const std::vector<std::shared_ptr<flutter::OverlayLayer>>&)unusedLayers
               surfaceFrames:
                   (const std::vector<std::unique_ptr<flutter::SurfaceFrame>>&)surfaceFrames;

- (void)onCreate:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)onDispose:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)onAcceptGesture:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)onRejectGesture:(FlutterMethodCall*)call result:(FlutterResult)result;

- (void)clipViewSetMaskView:(UIView*)clipView;

// Applies the mutators in the mutatorsStack to the UIView chain that was constructed by
// `ReconstructClipViewsChain`
//
// Clips are applied to the `embeddedView`'s super view(|ChildClippingView|) using a
// |FlutterClippingMaskView|. Transforms are applied to `embeddedView`
//
// The `boundingRect` is the final bounding rect of the PlatformView
// (EmbeddedViewParams::finalBoundingRect). If a clip mutator's rect contains the final bounding
// rect of the PlatformView, the clip mutator is not applied for performance optimization.
//
// This method is only called when the `embeddedView` needs to be re-composited at the current
// frame. See: `compositeView:withParams:` for details.
- (void)applyMutators:(const flutter::MutatorsStack&)mutatorsStack
         embeddedView:(UIView*)embeddedView
         boundingRect:(const DlRect&)boundingRect;

// Appends the overlay views and platform view and sets their z index based on the composition
// order.
- (void)bringLayersIntoView:(const LayersMap&)layerMap
       withCompositionOrder:(const std::vector<int64_t>&)compositionOrder;

- (std::shared_ptr<flutter::OverlayLayer>)nextLayerInPool;

/// Runs on the platform thread.
- (void)createLayerWithIosContext:(const std::shared_ptr<flutter::IOSContext>&)iosContext
                      pixelFormat:(MTLPixelFormat)pixelFormat;

/// Removes overlay views and platform views that aren't needed in the current frame.
/// Must run on the platform thread.
- (void)removeUnusedLayers:(const std::vector<std::shared_ptr<flutter::OverlayLayer>>&)unusedLayers
      withCompositionOrder:(const std::vector<int64_t>&)compositionOrder;

/// Returns the views to be disposed (as requested via the `dispose` method channel call) and
/// removes them from `self.platformViews`. Any views still in `compositionOrder` are not returned,
/// but are instead kept in `viewsToDispose` for disposal on a later call.
///
/// Must run on the platform thread.
- (NSArray<UIView*>*)computeViewsToDisposeWithCompositionOrder:
    (const std::vector<int64_t>&)compositionOrder;

/// Resets the state of the frame.
- (void)resetFrameState;
@end

@implementation FlutterPlatformViewsController {
  // TODO(cbracken): Replace with Obj-C types and use @property declarations to automatically
  // synthesize the ivars.
  //
  // These ivars are required because we're transitioning the previous C++ implementation to Obj-C.
  // We require ivars to declare the concrete types and then wrap with @property declarations that
  // return a reference to the ivar, allowing for use like `self.layerPool` and
  // `self.slices[viewId] = x`.
  std::unique_ptr<flutter::OverlayLayerPool> _layerPool;
  std::unordered_map<int64_t, std::unique_ptr<flutter::EmbedderViewSlice>> _slices;
  NSMutableDictionary<NSString*, NSObject<FlutterPlatformViewFactory>*>* _factories;
  NSMutableDictionary<NSString*, NSNumber*>* _gestureRecognizersBlockingPoliciesByType;
  FlutterFMLTaskRunner* _platformTaskRunner;
  NSMutableDictionary<NSNumber*, FlutterPlatformViewInfo*>* _platformViews;
  std::unordered_map<int64_t, flutter::EmbeddedViewParams> _currentCompositionParams;
  std::unordered_map<int64_t, flutter::EmbeddedViewParams> _previousCompositionParams;
  NSMutableSet<NSNumber*>* _viewsToDispose;
  std::vector<int64_t> _compositionOrder;
  std::vector<int64_t> _visitedPlatformViews;
  NSMutableArray<NSNumber*>* _previousCompositionOrder;
}

- (id)init {
  if (self = [super init]) {
    _layerPool = std::make_unique<flutter::OverlayLayerPool>();
    _factories = [[NSMutableDictionary alloc] init];
    _gestureRecognizersBlockingPoliciesByType = [[NSMutableDictionary alloc] init];
    _platformViews = [[NSMutableDictionary alloc] init];
    _viewsToDispose = [[NSMutableSet alloc] init];
    _previousCompositionOrder = [[NSMutableArray alloc] init];
    _maskViewPool =
        [[FlutterClippingMaskViewPool alloc] initWithCapacity:kFlutterClippingMaskViewPoolCapacity];
    _hadPlatformViews = NO;
    _canApplyBlurBackdrop = YES;
  }
  return self;
}

- (FlutterFMLTaskRunner*)taskRunner {
  return _platformTaskRunner;
}

- (void)setTaskRunner:(FlutterFMLTaskRunner*)platformTaskRunner {
  _platformTaskRunner = platformTaskRunner;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"create"]) {
    [self onCreate:call result:result];
  } else if ([[call method] isEqualToString:@"dispose"]) {
    [self onDispose:call result:result];
  } else if ([[call method] isEqualToString:@"acceptGesture"]) {
    [self onAcceptGesture:call result:result];
  } else if ([[call method] isEqualToString:@"rejectGesture"]) {
    [self onRejectGesture:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)onCreate:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSDictionary<NSString*, id>* args = [call arguments];

  int64_t viewId = [args[@"id"] longLongValue];
  // A missing argument arrives as nil and an explicit Dart null as NSNull, neither of which can be
  // converted to a view type.
  NSString* viewTypeString = args[@"viewType"];
  if (![viewTypeString isKindOfClass:[NSString class]]) {
    result([FlutterError
        errorWithCode:@"unknown_view"
              message:@"'viewType' argument must be a string to create a platform view."
              details:nil]);
    return;
  }
  if (self.platformViews[@(viewId)] != nil) {
    result([FlutterError errorWithCode:@"recreating_view"
                               message:@"trying to create an already created view"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  NSObject<FlutterPlatformViewFactory>* factory = self.factories[viewTypeString];
  if (factory == nil) {
    result([FlutterError
        errorWithCode:@"unregistered_view_type"
              message:[NSString stringWithFormat:@"A UIKitView widget is trying to create a "
                                                 @"PlatformView with an unregistered type: < %@ >",
                                                 viewTypeString]
              details:@"If you are the author of the PlatformView, make sure `registerViewFactory` "
                      @"is invoked.\n"
                      @"See: "
                      @"https://docs.flutter.dev/development/platform-integration/"
                      @"platform-views#on-the-platform-side-1 for more details.\n"
                      @"If you are not the author of the PlatformView, make sure to call "
                      @"`GeneratedPluginRegistrant.register`."]);
    return;
  }

  id params = nil;
  if ([factory respondsToSelector:@selector(createArgsCodec)]) {
    NSObject<FlutterMessageCodec>* codec = [factory createArgsCodec];
    if (codec != nil && args[@"params"] != nil) {
      FlutterStandardTypedData* paramsData = args[@"params"];
      params = [codec decode:paramsData.data];
    }
  }

  NSObject<FlutterPlatformView>* embeddedView = [factory createWithFrame:CGRectZero
                                                          viewIdentifier:viewId
                                                               arguments:params];
  UIView* platformView = [embeddedView view];
  // Set a unique view identifier, so the platform view can be identified in unit tests.
  platformView.accessibilityIdentifier = [NSString stringWithFormat:@"platform_view[%lld]", viewId];

  NSString* gestureBlockingPolicyValue = args[@"gestureBlockingPolicy"];
  FlutterPlatformViewGestureRecognizersBlockingPolicy gestureBlockingPolicy;
  if ([gestureBlockingPolicyValue isEqualToString:kGestureBlockingPolicyDoNotBlockGesture]) {
    gestureBlockingPolicy = FlutterPlatformViewGestureRecognizersBlockingPolicyDoNotBlockGesture;
  } else if ([gestureBlockingPolicyValue isEqualToString:kGestureBlockingPolicyEagerValue]) {
    gestureBlockingPolicy = FlutterPlatformViewGestureRecognizersBlockingPolicyEager;
  } else if ([gestureBlockingPolicyValue
                 isEqualToString:kGestureBlockingPolicyWaitUntilTouchesEndedValue]) {
    gestureBlockingPolicy =
        FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded;
  } else if ([gestureBlockingPolicyValue
                 isEqualToString:kGestureBlockingPolicyFallbackToPluginDefault]) {
    gestureBlockingPolicy = static_cast<FlutterPlatformViewGestureRecognizersBlockingPolicy>(
        self.gestureRecognizersBlockingPoliciesByType[viewTypeString].integerValue);
  } else {
    result([FlutterError
        errorWithCode:@"unknown_gesture_blocking_policy"
              message:@"Trying to create a platform view with an unknown gesture blocking policy"
              details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  FlutterTouchInterceptingView* touchInterceptor =
      [[FlutterTouchInterceptingView alloc] initWithEmbeddedView:platformView
                                         platformViewsController:self
                                gestureRecognizersBlockingPolicy:gestureBlockingPolicy];

  ChildClippingView* clippingView = [[ChildClippingView alloc] initWithFrame:CGRectZero];
  [clippingView addSubview:touchInterceptor];

  self.platformViews[@(viewId)] = [[FlutterPlatformViewInfo alloc] initWithView:embeddedView
                                                               touchInterceptor:touchInterceptor
                                                                       rootView:clippingView];

  result(nil);
}

- (void)onDispose:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSNumber* arg = [call arguments];
  int64_t viewId = [arg longLongValue];

  if (self.platformViews[@(viewId)] == nil) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to dispose an unknown"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }
  // We wait for next submitFrame to dispose views.
  [self.viewsToDispose addObject:@(viewId)];
  result(nil);
}

- (void)onAcceptGesture:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSDictionary<NSString*, id>* args = [call arguments];
  int64_t viewId = [args[@"id"] longLongValue];

  if (self.platformViews[@(viewId)] == nil) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to set gesture state for an unknown view"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  FlutterTouchInterceptingView* view = self.platformViews[@(viewId)].touchInterceptor;
  [view releaseGesture];

  result(nil);
}

- (void)onRejectGesture:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSDictionary<NSString*, id>* args = [call arguments];
  int64_t viewId = [args[@"id"] longLongValue];

  if (self.platformViews[@(viewId)] == nil) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to set gesture state for an unknown view"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  FlutterTouchInterceptingView* view = self.platformViews[@(viewId)].touchInterceptor;
  [view blockGesture];

  result(nil);
}

- (void)registerViewFactory:(NSObject<FlutterPlatformViewFactory>*)factory
                              withId:(NSString*)factoryId
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)gestureRecognizerBlockingPolicy {
  FML_CHECK(self.factories[factoryId] == nil);
  self.factories[factoryId] = factory;
  self.gestureRecognizersBlockingPoliciesByType[factoryId] = @(gestureRecognizerBlockingPolicy);
}

- (void)beginFrameWithSize:(DlISize)frameSize {
  [self resetFrameState];
  self.frameSize = frameSize;
}

- (void)cancelFrame {
  [self resetFrameState];
}

- (void)pushFilterToVisitedPlatformViews:(const std::shared_ptr<flutter::DlImageFilter>&)filter
                                withRect:(const flutter::DlRect&)filterRect {
  for (int64_t id : self.visitedPlatformViews) {
    flutter::EmbeddedViewParams params = self.currentCompositionParams[id];
    params.PushImageFilter(filter, filterRect);
    self.currentCompositionParams[id] = params;
  }
}

- (void)prerollCompositeEmbeddedView:(int64_t)viewId
                          withParams:(std::unique_ptr<flutter::EmbeddedViewParams>)params {
  DlRect viewBounds = DlRect::MakeSize(self.frameSize);
  std::unique_ptr<flutter::EmbedderViewSlice> view;
  view = std::make_unique<flutter::DisplayListEmbedderViewSlice>(viewBounds);
  self.slices.insert_or_assign(viewId, std::move(view));

  self.compositionOrder.push_back(viewId);
  self.currentCompositionParams[viewId] = flutter::EmbeddedViewParams(*params.get());
}

- (size_t)embeddedViewCount {
  return self.compositionOrder.size();
}

- (UIView*)platformViewForId:(int64_t)viewId {
  return [self flutterTouchInterceptingViewForId:viewId].embeddedView;
}

- (FlutterTouchInterceptingView*)flutterTouchInterceptingViewForId:(int64_t)viewId {
  return self.platformViews[@(viewId)].touchInterceptor;
}

- (long)firstResponderPlatformViewId {
  for (NSNumber* viewId in self.platformViews) {
    UIView* rootView = self.platformViews[viewId].rootView;
    if (rootView.flt_hasFirstResponderInViewHierarchySubtree) {
      return viewId.longValue;
    }
  }
  return -1;
}

- (void)clipViewSetMaskView:(UIView*)clipView {
  FML_DCHECK([[NSThread currentThread] isMainThread]);
  if (clipView.maskView) {
    return;
  }
  CGRect frame =
      CGRectMake(-clipView.frame.origin.x, -clipView.frame.origin.y,
                 CGRectGetWidth(self.flutterView.bounds), CGRectGetHeight(self.flutterView.bounds));
  clipView.maskView = [self.maskViewPool getMaskViewWithFrame:frame];
}

- (void)applyMutators:(const flutter::MutatorsStack&)mutatorsStack
         embeddedView:(UIView*)embeddedView
         boundingRect:(const DlRect&)boundingRect {
  if (self.flutterView == nil) {
    return;
  }

  ResetAnchor(embeddedView.layer);
  ChildClippingView* clipView = (ChildClippingView*)embeddedView.superview;

  DlMatrix transformMatrix;
  NSMutableArray* blurFilters = [[NSMutableArray alloc] init];
  NSMutableArray<PendingRRectClip*>* pendingClipRRects = [[NSMutableArray alloc] init];

  FML_DCHECK(!clipView.maskView ||
             [clipView.maskView isKindOfClass:[FlutterClippingMaskView class]]);
  if (clipView.maskView) {
    [self.maskViewPool insertViewToPoolIfNeeded:(FlutterClippingMaskView*)(clipView.maskView)];
    clipView.maskView = nil;
  }
  CGFloat screenScale = [UIScreen mainScreen].scale;
  auto iter = mutatorsStack.Begin();
  while (iter != mutatorsStack.End()) {
    switch ((*iter)->GetType()) {
      case flutter::MutatorType::kTransform: {
        transformMatrix = transformMatrix * (*iter)->GetMatrix();
        break;
      }
      case flutter::MutatorType::kClipRect: {
        if (flutter::DisplayListMatrixClipState::TransformedRectCoversBounds(
                (*iter)->GetRect(), transformMatrix, boundingRect)) {
          break;
        }
        [self clipViewSetMaskView:clipView];
        [(FlutterClippingMaskView*)clipView.maskView clipRect:(*iter)->GetRect()
                                                       matrix:transformMatrix];
        break;
      }
      case flutter::MutatorType::kClipRRect: {
        if (flutter::DisplayListMatrixClipState::TransformedRRectCoversBounds(
                (*iter)->GetRRect(), transformMatrix, boundingRect)) {
          break;
        }
        [self clipViewSetMaskView:clipView];
        [(FlutterClippingMaskView*)clipView.maskView clipRRect:(*iter)->GetRRect()
                                                        matrix:transformMatrix];
        break;
      }
      case flutter::MutatorType::kClipRSE: {
        if (flutter::DisplayListMatrixClipState::TransformedRoundSuperellipseCoversBounds(
                (*iter)->GetRSE(), transformMatrix, boundingRect)) {
          break;
        }
        [self clipViewSetMaskView:clipView];
        [(FlutterClippingMaskView*)clipView.maskView clipRRect:(*iter)->GetRSEApproximation()
                                                        matrix:transformMatrix];
        break;
      }
      case flutter::MutatorType::kClipPath: {
        // TODO(cyanglaz): Find a way to pre-determine if path contains the PlatformView boudning
        // rect. See `ClipRRectContainsPlatformViewBoundingRect`.
        // https://github.com/flutter/flutter/issues/118650
        [self clipViewSetMaskView:clipView];
        [(FlutterClippingMaskView*)clipView.maskView clipPath:(*iter)->GetPath()
                                                       matrix:transformMatrix];
        break;
      }
      case flutter::MutatorType::kOpacity:
        embeddedView.alpha = (*iter)->GetAlphaFloat() * embeddedView.alpha;
        break;
      case flutter::MutatorType::kBackdropFilter: {
        // Only support DlBlurImageFilter for BackdropFilter.
        if (!self.canApplyBlurBackdrop || !(*iter)->GetFilterMutation().GetFilter().asBlur()) {
          break;
        }
        CGRect filterRect = GetCGRectFromDlRect((*iter)->GetFilterMutation().GetFilterRect());
        // `filterRect` is in global coordinates. We need to convert to local space.
        filterRect = CGRectApplyAffineTransform(
            filterRect, CGAffineTransformMakeScale(1 / screenScale, 1 / screenScale));
        // `filterRect` reprents the rect that should be filtered inside the `_flutterView`.
        // The `PlatformViewFilter` needs the frame inside the `clipView` that needs to be
        // filtered.
        if (CGRectIsNull(CGRectIntersection(filterRect, clipView.frame))) {
          break;
        }
        CGRect intersection = CGRectIntersection(filterRect, clipView.frame);
        CGRect frameInClipView = [self.flutterView convertRect:intersection toView:clipView];
        // sigma_x is arbitrarily chosen as the radius value because Quartz sets
        // sigma_x and sigma_y equal to each other. DlBlurImageFilter's Tile Mode
        // is not supported in Quartz's gaussianBlur CAFilter, so it is not used
        // to blur the PlatformView.
        CGFloat blurRadius = (*iter)->GetFilterMutation().GetFilter().asBlur()->sigma_x();
        UIVisualEffectView* visualEffectView = [[UIVisualEffectView alloc]
            initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        // The visual effect shouldn't swallow touches.
        // See: https://github.com/flutter/flutter/issues/191203
        visualEffectView.userInteractionEnabled = NO;

        // TODO(https://github.com/flutter/flutter/issues/179126)
        CGFloat cornerRadius = 0.0;
        BOOL isRoundedSuperellipse = NO;
        // If there's multiple clips, this uses the innermost to decide if its
        // rse or not. The assumption being the innermost will be the tightest
        if ([pendingClipRRects count] > 0) {
          cornerRadius = pendingClipRRects.lastObject.topLeftRadius;
          isRoundedSuperellipse = pendingClipRRects.lastObject.isRoundedSuperellipse;
          [pendingClipRRects removeAllObjects];
        }
        visualEffectView.layer.cornerRadius = cornerRadius;
        visualEffectView.layer.cornerCurve =
            isRoundedSuperellipse ? kCACornerCurveContinuous : kCACornerCurveCircular;
        visualEffectView.clipsToBounds = YES;

        PlatformViewFilter* filter = [[PlatformViewFilter alloc] initWithFrame:frameInClipView
                                                                    blurRadius:blurRadius
                                                                  cornerRadius:cornerRadius
                                                         isRoundedSuperellipse:isRoundedSuperellipse
                                                              visualEffectView:visualEffectView];
        if (!filter) {
          self.canApplyBlurBackdrop = NO;
        } else {
          [blurFilters addObject:filter];
        }
        break;
      }
      case flutter::MutatorType::kBackdropClipRect: {
        // The frame already handles cropping into the rect so this can
        // no-op
        break;
      }
      case flutter::MutatorType::kBackdropClipRRect: {
        PendingRRectClip* clip = [[PendingRRectClip alloc] init];
        DlRoundRect rrect = (*iter)->GetBackdropClipRRect().rrect;

        impeller::RoundingRadii radii = rrect.GetRadii();
        clip.topLeftRadius = radii.top_left.width;
        clip.topRightRadius = radii.top_right.width;
        clip.bottomLeftRadius = radii.bottom_left.width;
        clip.bottomRightRadius = radii.bottom_right.width;
        [pendingClipRRects addObject:clip];
        break;
      }
      case flutter::MutatorType::kBackdropClipRSuperellipse: {
        PendingRRectClip* clip = [[PendingRRectClip alloc] init];
        flutter::DlRoundSuperellipse rse = (*iter)->GetBackdropClipRSuperellipse().rse;

        impeller::RoundingRadii radii = rse.GetRadii();
        clip.topLeftRadius = radii.top_left.width;
        clip.topRightRadius = radii.top_right.width;
        clip.bottomLeftRadius = radii.bottom_left.width;
        clip.bottomRightRadius = radii.bottom_right.width;
        clip.isRoundedSuperellipse = YES;
        [pendingClipRRects addObject:clip];
        break;
      }
      case flutter::MutatorType::kBackdropClipPath: {
        // TODO(https://github.com/flutter/flutter/issues/179127)
        break;
      }
    }
    ++iter;
  }

  if (self.canApplyBlurBackdrop) {
    [clipView applyBlurBackdropFilters:blurFilters];
  }

  // The UIKit frame is set based on the logical resolution (points) instead of physical.
  // (https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html).
  // However, flow is based on the physical resolution. For example, 1000 pixels in flow equals
  // 500 points in UIKit for devices that has screenScale of 2. We need to scale the transformMatrix
  // down to the logical resoltion before applying it to the layer of PlatformView.
  flutter::DlScalar pointScale = 1.0 / screenScale;
  transformMatrix = DlMatrix::MakeScale({pointScale, pointScale, 1}) * transformMatrix;

  // Reverse the offset of the clipView.
  // The clipView's frame includes the final translate of the final transform matrix.
  // Thus, this translate needs to be reversed so the platform view can layout at the correct
  // offset.
  //
  // Note that the transforms are not applied to the clipping paths because clipping paths happen on
  // the mask view, whose origin is always (0,0) to the _flutterView.
  impeller::Vector3 origin = impeller::Vector3(clipView.frame.origin.x, clipView.frame.origin.y);
  transformMatrix = DlMatrix::MakeTranslation(-origin) * transformMatrix;

  embeddedView.layer.transform = GetCATransform3DFromDlMatrix(transformMatrix);
}

- (void)compositeView:(int64_t)viewId withParams:(const flutter::EmbeddedViewParams&)params {
  // TODO(https://github.com/flutter/flutter/issues/109700)
  CGRect frame = CGRectMake(0, 0, params.sizePoints().width, params.sizePoints().height);
  FlutterTouchInterceptingView* touchInterceptor = self.platformViews[@(viewId)].touchInterceptor;
  touchInterceptor.layer.transform = CATransform3DIdentity;
  touchInterceptor.frame = frame;
  touchInterceptor.alpha = 1;

  const flutter::MutatorsStack& mutatorStack = params.mutatorsStack();
  UIView* clippingView = self.platformViews[@(viewId)].rootView;
  // The frame of the clipping view should be the final bounding rect.
  // Because the translate matrix in the Mutator Stack also includes the offset,
  // when we apply the transforms matrix in |applyMutators:embeddedView:boundingRect|, we need
  // to remember to do a reverse translate.
  const DlRect& rect = params.finalBoundingRect();
  CGFloat screenScale = [UIScreen mainScreen].scale;
  clippingView.frame = CGRectMake(rect.GetX() / screenScale, rect.GetY() / screenScale,
                                  rect.GetWidth() / screenScale, rect.GetHeight() / screenScale);
  [self applyMutators:mutatorStack embeddedView:touchInterceptor boundingRect:rect];
}

- (flutter::DlCanvas*)compositeEmbeddedViewWithId:(int64_t)viewId {
  FML_DCHECK(self.slices.find(viewId) != self.slices.end());
  return self.slices[viewId]->canvas();
}

- (void)reset {
  // `PlatformViewIOS::OnPreEngineRestart` calls this on the platform thread during hot restart.
  // _platformViews must only be modified on the platform thread, and any operations that
  // read or modify platform views should occur there.
  std::vector<int64_t> compositionOrder = self.compositionOrder;
  [self.taskRunner runNowOrPostTask:^{
    for (int64_t viewId : compositionOrder) {
      [self.platformViews[@(viewId)].rootView removeFromSuperview];
    }
    [self.platformViews removeAllObjects];
    [_previousCompositionOrder removeAllObjects];
  }];

  // The state below is otherwise only modified on the raster thread.
  self.compositionOrder.clear();
  self.slices.clear();
  self.currentCompositionParams.clear();
  self.previousCompositionParams.clear();
  self.layerPool->RecycleLayers();
  self.visitedPlatformViews.clear();
}

- (void)submitFrame:(std::unique_ptr<flutter::SurfaceFrame>)background_frame
     withIosContext:(const std::shared_ptr<flutter::IOSContext>&)iosContext {
  TRACE_EVENT0("flutter", "PlatformViewsController::SubmitFrame");

  // No platform views to render.
  if (self.flutterView == nil || (self.compositionOrder.empty() && !self.hadPlatformViews)) {
    // No platform views to render but the FlutterView may need to be resized.
    __weak FlutterPlatformViewsController* weakSelf = self;
    if (self.flutterView != nil) {
      // Pass frameSize by value since self.frameSize is mutated both here (on the platform
      // thread) and in beginFrameWithSize: (on the raster thread).
      const flutter::DlISize frameSize = self.frameSize;
      [self.taskRunner runNowOrPostTask:^{
        FlutterPlatformViewsController* strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        [strongSelf performResize:frameSize];
      }];
    }

    self.hadPlatformViews = NO;

    // No platform views are composited when there is no Flutter view, or when neither this frame
    // nor the previous one had any. The next frame that has platform views must composite all of
    // them.
    self.previousCompositionParams.clear();
    background_frame->Submit();
    return;
  }
  self.hadPlatformViews = !self.compositionOrder.empty();

  // Recomposite only the views whose parameters changed since the previous frame.
  //
  // Backdrop filter and clip mutators are appended to the parameters via the
  // `push*ToVisitedPlatformViews:` methods after preroll. As a result, we can't compare in preroll;
  // we need to do it here.
  std::unordered_set<int64_t> viewsToRecomposite;
  for (int64_t viewId : self.compositionOrder) {
    auto previous = self.previousCompositionParams.find(viewId);
    if (previous == self.previousCompositionParams.end() ||
        previous->second != self.currentCompositionParams[viewId]) {
      viewsToRecomposite.insert(viewId);
    }
  }

  LayersMap platformViewLayers;
  std::vector<std::unique_ptr<flutter::SurfaceFrame>> surfaceFrames;
  surfaceFrames.reserve(self.compositionOrder.size());
  std::unordered_map<int64_t, DlRect> viewRects;

  for (int64_t viewId : self.compositionOrder) {
    viewRects[viewId] = self.currentCompositionParams[viewId].finalBoundingRect();
  }

  std::unordered_map<int64_t, DlRect> overlayLayers =
      SliceViews(background_frame->Canvas(), self.compositionOrder, self.slices, viewRects);

  size_t requiredOverlayLayers = 0;
  for (int64_t viewId : self.compositionOrder) {
    std::unordered_map<int64_t, DlRect>::const_iterator overlay = overlayLayers.find(viewId);
    if (overlay == overlayLayers.end()) {
      continue;
    }
    requiredOverlayLayers++;
  }

  // If there are not sufficient overlay layers, we must construct them on the platform
  // thread, at least until we've refactored iOS surface creation to use IOSurfaces
  // instead of CALayers.
  [self createMissingOverlays:requiredOverlayLayers withIosContext:iosContext];

  int64_t overlayId = 0;
  for (int64_t viewId : self.compositionOrder) {
    std::unordered_map<int64_t, DlRect>::const_iterator overlay = overlayLayers.find(viewId);
    if (overlay == overlayLayers.end()) {
      continue;
    }
    std::shared_ptr<flutter::OverlayLayer> layer = self.nextLayerInPool;
    if (!layer) {
      continue;
    }

    std::unique_ptr<flutter::SurfaceFrame> frame = layer->surface->AcquireFrame(self.frameSize);
    // If frame is null, AcquireFrame already printed out an error message.
    if (!frame) {
      continue;
    }
    flutter::DlCanvas* overlayCanvas = frame->Canvas();
    int restoreCount = overlayCanvas->GetSaveCount();
    overlayCanvas->Save();
    overlayCanvas->ClipRect(overlay->second);
    overlayCanvas->Clear(flutter::DlColor::kTransparent());
    self.slices[viewId]->render_into(overlayCanvas);
    overlayCanvas->RestoreToCount(restoreCount);

    // This flutter view is never the last in a frame, since we always submit the
    // underlay view last.
    frame->set_submit_info({.frame_boundary = false, .present_with_transaction = true});
    frame->Encode();
    platformViewLayers[viewId] = LayerData{
        .rect = overlay->second,  //
        .view_id = viewId,        //
        .overlay_id = overlayId,  //
        .layer = layer            //
    };
    surfaceFrames.push_back(std::move(frame));
    overlayId++;
  }

  auto previousSubmitInfo = background_frame->submit_info();
  background_frame->set_submit_info({
      .frame_damage = previousSubmitInfo.frame_damage,
      .buffer_damage = previousSubmitInfo.buffer_damage,
      .present_with_transaction = true,
  });
  background_frame->Encode();
  surfaceFrames.push_back(std::move(background_frame));

  // Mark all layers as available, so they can be used in the next frame.
  std::vector<std::shared_ptr<flutter::OverlayLayer>> unusedLayers =
      self.layerPool->RemoveUnusedLayers();
  self.layerPool->RecycleLayers();
  self.previousCompositionParams = self.currentCompositionParams;
  auto task = fml::MakeCopyable([self,                                                      //
                                 platformViewLayers = std::move(platformViewLayers),        //
                                 currentCompositionParams = self.currentCompositionParams,  //
                                 viewsToRecomposite = std::move(viewsToRecomposite),        //
                                 compositionOrder = self.compositionOrder,                  //
                                 unusedLayers = std::move(unusedLayers),                    //
                                 surfaceFrames = std::move(surfaceFrames)]() mutable {
    [self performSubmit:platformViewLayers
        currentCompositionParams:currentCompositionParams
              viewsToRecomposite:viewsToRecomposite
                compositionOrder:compositionOrder
                    unusedLayers:unusedLayers
                   surfaceFrames:surfaceFrames];
  });

  [self.taskRunner runNowOrPostTask:^{
    task();
  }];
}

- (void)createMissingOverlays:(size_t)requiredOverlayLayers
               withIosContext:(const std::shared_ptr<flutter::IOSContext>&)iosContext {
  TRACE_EVENT0("flutter", "PlatformViewsController::CreateMissingLayers");

  if (requiredOverlayLayers <= self.layerPool->size()) {
    return;
  }
  auto missingLayerCount = requiredOverlayLayers - self.layerPool->size();

  // If the raster thread isn't merged, create layers on the platform thread and block until
  // complete. The self-capture here is fine since this is effectively synchronous (we block on the
  // latch right below).
  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  [self.taskRunner runNowOrPostTask:^{
    for (auto i = 0u; i < missingLayerCount; i++) {
      [self createLayerWithIosContext:iosContext
                          pixelFormat:((FlutterView*)self.flutterView).pixelFormat];
    }
    latch->CountDown();
  }];
  if (![[NSThread currentThread] isMainThread]) {
    latch->Wait();
  }
}

- (void)performResize:(const flutter::DlISize&)frameSize {
  TRACE_EVENT0("flutter", "PlatformViewsController::PerformResize");
  FML_DCHECK([[NSThread currentThread] isMainThread]);

  if (self.flutterView != nil) {
    [(FlutterView*)self.flutterView
        setIntrinsicContentSize:CGSizeMake(frameSize.width, frameSize.height)];
  }
}

- (void)performSubmit:(const LayersMap&)platformViewLayers
    currentCompositionParams:
        (std::unordered_map<int64_t, flutter::EmbeddedViewParams>&)currentCompositionParams
          viewsToRecomposite:(const std::unordered_set<int64_t>&)viewsToRecomposite
            compositionOrder:(const std::vector<int64_t>&)compositionOrder
                unusedLayers:
                    (const std::vector<std::shared_ptr<flutter::OverlayLayer>>&)unusedLayers
               surfaceFrames:
                   (const std::vector<std::unique_ptr<flutter::SurfaceFrame>>&)surfaceFrames {
  TRACE_EVENT0("flutter", "PlatformViewsController::PerformSubmit");
  FML_DCHECK([[NSThread currentThread] isMainThread]);

  [CATransaction begin];

  // Configure Flutter overlay views.
  for (const auto& [viewId, layerData] : platformViewLayers) {
    layerData.layer->UpdateViewState(self.flutterView,     //
                                     layerData.rect,       //
                                     layerData.view_id,    //
                                     layerData.overlay_id  //
    );
  }

  // Dispose unused Flutter Views.
  for (UIView* view in [self computeViewsToDisposeWithCompositionOrder:compositionOrder]) {
    [view removeFromSuperview];
  }

  // Composite Platform Views.
  for (int64_t viewId : viewsToRecomposite) {
    [self compositeView:viewId withParams:currentCompositionParams[viewId]];
  }

  // Present callbacks.
  for (const auto& frame : surfaceFrames) {
    frame->Submit();
  }

  // If a layer was allocated in the previous frame, but it's not used in the current frame,
  // then it can be removed from the scene.
  [self removeUnusedLayers:unusedLayers withCompositionOrder:compositionOrder];

  // Organize the layers by their z indexes.
  [self bringLayersIntoView:platformViewLayers withCompositionOrder:compositionOrder];

  [CATransaction commit];
}

- (void)bringLayersIntoView:(const LayersMap&)layerMap
       withCompositionOrder:(const std::vector<int64_t>&)compositionOrder {
  UIView* flutterView = self.flutterView;
  if (flutterView == nil) {
    return;
  }

  [_previousCompositionOrder removeAllObjects];
  NSMutableArray* desiredPlatformSubviews = [NSMutableArray array];
  for (int64_t platformViewId : compositionOrder) {
    [_previousCompositionOrder addObject:@(platformViewId)];
    UIView* platformViewRoot = self.platformViews[@(platformViewId)].rootView;
    if (platformViewRoot != nil) {
      [desiredPlatformSubviews addObject:platformViewRoot];
    }

    auto maybeLayerData = layerMap.find(platformViewId);
    if (maybeLayerData != layerMap.end()) {
      auto view = maybeLayerData->second.layer->overlay_view_wrapper;
      if (view != nil) {
        [desiredPlatformSubviews addObject:view];
      }
    }
  }

  NSSet* desiredPlatformSubviewsSet = [NSSet setWithArray:desiredPlatformSubviews];
  NSArray* existingPlatformSubviews = [flutterView.subviews
      filteredArrayUsingPredicate:[NSPredicate
                                      predicateWithBlock:^BOOL(id object, NSDictionary* bindings) {
                                        return [desiredPlatformSubviewsSet containsObject:object];
                                      }]];

  // Manipulate view hierarchy only if needed, to address a performance issue where
  // this method is called even when view hierarchy stays the same.
  // See: https://github.com/flutter/flutter/issues/121833
  // TODO(hellohuanlin): investigate if it is possible to skip unnecessary bringLayersIntoView.
  if (![desiredPlatformSubviews isEqualToArray:existingPlatformSubviews]) {
    for (UIView* subview in desiredPlatformSubviews) {
      // `addSubview` will automatically reorder subview if it is already added.
      [flutterView addSubview:subview];
    }
  }
}

- (std::shared_ptr<flutter::OverlayLayer>)nextLayerInPool {
  return self.layerPool->GetNextLayer();
}

- (void)createLayerWithIosContext:(const std::shared_ptr<flutter::IOSContext>&)iosContext
                      pixelFormat:(MTLPixelFormat)pixelFormat {
  self.layerPool->CreateLayer(iosContext, pixelFormat);
}

- (void)removeUnusedLayers:(const std::vector<std::shared_ptr<flutter::OverlayLayer>>&)unusedLayers
      withCompositionOrder:(const std::vector<int64_t>&)compositionOrder {
  for (const std::shared_ptr<flutter::OverlayLayer>& layer : unusedLayers) {
    [layer->overlay_view_wrapper removeFromSuperview];
  }

  std::unordered_set<int64_t> compositionOrderSet;
  for (int64_t viewId : compositionOrder) {
    compositionOrderSet.insert(viewId);
  }
  // Remove unused platform views.
  for (NSNumber* viewId in _previousCompositionOrder) {
    if (compositionOrderSet.find(viewId.longLongValue) == compositionOrderSet.end()) {
      UIView* platformViewRoot = self.platformViews[viewId].rootView;
      [platformViewRoot removeFromSuperview];
    }
  }
}

- (NSArray<UIView*>*)computeViewsToDisposeWithCompositionOrder:
    (const std::vector<int64_t>&)compositionOrder {
  if (self.viewsToDispose.count == 0) {
    return @[];
  }

  std::unordered_set<int64_t> viewsToComposite(compositionOrder.begin(), compositionOrder.end());
  NSMutableArray<UIView*>* views = [NSMutableArray array];
  NSMutableSet<NSNumber*>* viewsToDelayDispose = [NSMutableSet set];
  for (NSNumber* viewId in self.viewsToDispose) {
    if (viewsToComposite.count(viewId.longLongValue)) {
      [viewsToDelayDispose addObject:viewId];
      continue;
    }
    UIView* rootView = self.platformViews[viewId].rootView;
    if (rootView != nil) {
      [views addObject:rootView];
    }
    [self.platformViews removeObjectForKey:viewId];
  }
  [self.viewsToDispose setSet:viewsToDelayDispose];
  return views;
}

- (void)resetFrameState {
  self.slices.clear();
  self.compositionOrder.clear();
  self.currentCompositionParams.clear();
  self.visitedPlatformViews.clear();
}

- (void)pushVisitedPlatformViewId:(int64_t)viewId {
  self.visitedPlatformViews.push_back(viewId);
}

- (void)pushClipRectToVisitedPlatformViews:(const flutter::DlRect&)clipRect {
  for (int64_t id : self.visitedPlatformViews) {
    flutter::EmbeddedViewParams params = self.currentCompositionParams[id];
    params.PushPlatformViewClipRect(clipRect);
    self.currentCompositionParams[id] = params;
  }
}

- (void)pushClipRRectToVisitedPlatformViews:(const flutter::DlRoundRect&)clipRRect {
  for (int64_t id : self.visitedPlatformViews) {
    flutter::EmbeddedViewParams params = self.currentCompositionParams[id];
    params.PushPlatformViewClipRRect(clipRRect);
    self.currentCompositionParams[id] = params;
  }
}

- (void)pushClipRSuperellipseToVisitedPlatformViews:(const flutter::DlRoundSuperellipse&)clipRse {
  for (int64_t id : self.visitedPlatformViews) {
    flutter::EmbeddedViewParams params = self.currentCompositionParams[id];
    params.PushPlatformViewClipRSuperellipse(clipRse);
    self.currentCompositionParams[id] = params;
  }
}

- (void)pushClipPathToVisitedPlatformViews:(const flutter::DlPath&)clipPath {
  for (int64_t id : self.visitedPlatformViews) {
    flutter::EmbeddedViewParams params = self.currentCompositionParams[id];
    params.PushPlatformViewClipPath(clipPath);
    self.currentCompositionParams[id] = params;
  }
}

- (const flutter::EmbeddedViewParams&)compositionParamsForView:(int64_t)viewId {
  return self.currentCompositionParams.find(viewId)->second;
}

#pragma mark - Properties

- (flutter::OverlayLayerPool*)layerPool {
  return _layerPool.get();
}

- (std::unordered_map<int64_t, std::unique_ptr<flutter::EmbedderViewSlice>>&)slices {
  return _slices;
}

- (std::unordered_map<int64_t, flutter::EmbeddedViewParams>&)currentCompositionParams {
  return _currentCompositionParams;
}

- (std::unordered_map<int64_t, flutter::EmbeddedViewParams>&)previousCompositionParams {
  return _previousCompositionParams;
}

- (std::vector<int64_t>&)compositionOrder {
  return _compositionOrder;
}

- (std::vector<int64_t>&)visitedPlatformViews {
  return _visitedPlatformViews;
}

- (NSArray<NSNumber*>*)previousCompositionOrder {
  return [_previousCompositionOrder copy];
}

@end
