// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"
#include "display_list/geometry/dl_geometry_types.h"

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewFrame.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

static constexpr NSUInteger kFlutterClippingMaskViewPoolCapacity = 5;

static NSString* const kGestureBlockingPolicyEagerValue = @"eager";
static NSString* const kGestureBlockingPolicyWaitUntilTouchesEndedValue = @"waitUntilTouchesEnded";
static NSString* const kGestureBlockingPolicyDoNotBlockGesture = @"doNotBlockGesture";
static NSString* const kGestureBlockingPolicyFallbackToPluginDefault = @"fallbackToPluginDefault";

// Reset the anchor of `layer` to match the transform operation from flow.
//
// The position of the `layer` should be unchanged after resetting the anchor.
static void ResetAnchor(CALayer* layer) {
  // Flow uses (0, 0) to apply transform matrix so we need to match that in Quartz.
  layer.anchorPoint = CGPointZero;
  layer.position = CGPointZero;
}

@interface FlutterPlatformViewsController ()

@property(nonatomic, readonly) FlutterClippingMaskViewPool* maskViewPool;

@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, NSObject<FlutterPlatformViewFactory>*>* factories;

// The FlutterPlatformViewGestureRecognizersBlockingPolicy for each type of platform view, boxed in
// an NSNumber.
@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, NSNumber*>* gestureRecognizersBlockingPoliciesByType;

/// The task runner for posting tasks to the platform thread.
@property(nonatomic, readonly) FlutterFMLTaskRunner* platformTaskRunner;

/// The platform views keyed by view ID.
///
/// This data must only be accessed on the platform thread.
@property(nonatomic, readonly)
    NSMutableDictionary<NSNumber*, FlutterPlatformViewInfo*>* platformViews;

/// The IDs of views to be disposed, as requested via the `dispose` method channel call.
///
/// These will be removed from the view hierarchy in `presentFrame:`, in the same `CATransaction`
/// that presents the next frame, or deferred to a later frame while the view is still in the
/// composition order.
///
/// This state must only be accessed on the platform thread.
@property(nonatomic, readonly) NSMutableSet<NSNumber*>* viewsToDispose;

/// Whether blurred backdrop filters can be applied.
///
/// Defaults to YES, but becomes NO if blurred backdrop filters cannot be applied.
@property(nonatomic, assign) BOOL canApplyBlurBackdrop;

/// Sets the frames and accessibility identifiers of the views in `overlay`.
///
/// `viewId` is the ID of the platform view above which the overlay is painted, and `overlayId` is
/// the index of the overlay within the overlays in the frame.
///
/// This method divides by `devicePixelRatio` to convert the overlay's rect from physical pixels to
/// points.
///
/// Must run on the platform thread.
- (void)updateOverlay:(FlutterPlatformViewOverlay*)overlay
               viewId:(int64_t)viewId
            overlayId:(int64_t)overlayId
     devicePixelRatio:(CGFloat)devicePixelRatio;

- (void)onCreate:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)onDispose:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)onAcceptGesture:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)onRejectGesture:(FlutterMethodCall*)call result:(FlutterResult)result;

- (void)clipViewSetMaskView:(UIView*)clipView devicePixelRatio:(CGFloat)devicePixelRatio;

// Applies the mutators to the UIView chain that was constructed by
// `ReconstructClipViewsChain`
//
// Clips are applied to the `embeddedView`'s super view(|ChildClippingView|) using a
// |FlutterClippingMaskView|. Transforms are applied to `embeddedView`
//
// This method is only called when the `embeddedView` needs to be re-composited at the current
// frame. See: `presentFrame:` for details.
//
// This method divides by `devicePixelRatio` to convert the transforms and the backdrop filter rect
// from physical pixels to points.
- (void)applyMutators:(NSArray<FlutterPlatformViewMutator*>*)mutators
         embeddedView:(UIView*)embeddedView
     devicePixelRatio:(CGFloat)devicePixelRatio;

// Appends the overlay views and platform view and sets their z index based on the composition
// order.
- (void)bringOverlaysIntoView:(NSDictionary<NSNumber*, FlutterPlatformViewOverlay*>*)overlays
         withCompositionOrder:(NSArray<NSNumber*>*)compositionOrder;

/// Removes overlay views and platform views that aren't needed in the current frame.
/// Must run on the platform thread.
- (void)removeUnusedOverlayViews:(NSArray<UIView*>*)unusedOverlayViews
            withCompositionOrder:(NSArray<NSNumber*>*)compositionOrder;

/// Returns the views to be disposed (as requested via the `dispose` method channel call) and
/// removes them from `self.platformViews`. Any views still in `compositionOrder` are not returned,
/// but are instead kept in `viewsToDispose` for disposal on a later call.
///
/// Must run on the platform thread.
- (NSArray<UIView*>*)computeViewsToDisposeWithCompositionOrder:
    (NSArray<NSNumber*>*)compositionOrder;
@end

@implementation FlutterPlatformViewsController {
  // TODO(cbracken): Use @property declarations to automatically synthesize the ivars.
  NSMutableDictionary<NSString*, NSObject<FlutterPlatformViewFactory>*>* _factories;
  NSMutableDictionary<NSString*, NSNumber*>* _gestureRecognizersBlockingPoliciesByType;
  FlutterFMLTaskRunner* _platformTaskRunner;
  NSMutableDictionary<NSNumber*, FlutterPlatformViewInfo*>* _platformViews;
  NSMutableSet<NSNumber*>* _viewsToDispose;
  NSMutableArray<NSNumber*>* _previousCompositionOrder;
}

- (id)init {
  if (self = [super init]) {
    _factories = [[NSMutableDictionary alloc] init];
    _gestureRecognizersBlockingPoliciesByType = [[NSMutableDictionary alloc] init];
    _platformViews = [[NSMutableDictionary alloc] init];
    _viewsToDispose = [[NSMutableSet alloc] init];
    _previousCompositionOrder = [[NSMutableArray alloc] init];
    _maskViewPool =
        [[FlutterClippingMaskViewPool alloc] initWithCapacity:kFlutterClippingMaskViewPoolCapacity];
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

- (void)setFlutterView:(UIView*)flutterView {
  FML_DCHECK([[NSThread currentThread] isMainThread]);
  if (_flutterView == flutterView) {
    return;
  }
  _flutterView = flutterView;

  // Clear the platform views' last composited layers so that they are recomposited in the next
  // frame that includes them.
  // Otherwise views would keep clips computed against the previous Flutter view.
  for (FlutterPlatformViewInfo* info in self.platformViews.objectEnumerator) {
    info.lastCompositedLayer = nil;
  }
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

- (void)clipViewSetMaskView:(UIView*)clipView devicePixelRatio:(CGFloat)devicePixelRatio {
  FML_DCHECK([[NSThread currentThread] isMainThread]);
  if (clipView.maskView) {
    return;
  }
  CGRect frame =
      CGRectMake(-clipView.frame.origin.x, -clipView.frame.origin.y,
                 CGRectGetWidth(self.flutterView.bounds), CGRectGetHeight(self.flutterView.bounds));
  clipView.maskView = [self.maskViewPool getMaskViewWithFrame:frame
                                             devicePixelRatio:devicePixelRatio];
}

- (void)applyMutators:(NSArray<FlutterPlatformViewMutator*>*)mutators
         embeddedView:(UIView*)embeddedView
     devicePixelRatio:(CGFloat)devicePixelRatio {
  if (self.flutterView == nil) {
    return;
  }

  ResetAnchor(embeddedView.layer);
  ChildClippingView* clipView = (ChildClippingView*)embeddedView.superview;

  CATransform3D transformMatrix = CATransform3DIdentity;
  NSMutableArray* blurFilters = [[NSMutableArray alloc] init];
  NSMutableArray<PendingRRectClip*>* pendingClipRRects = [[NSMutableArray alloc] init];

  FML_DCHECK(!clipView.maskView ||
             [clipView.maskView isKindOfClass:[FlutterClippingMaskView class]]);
  if (clipView.maskView) {
    [self.maskViewPool insertViewToPoolIfNeeded:(FlutterClippingMaskView*)(clipView.maskView)];
    clipView.maskView = nil;
  }
  for (FlutterPlatformViewMutator* mutator in mutators) {
    switch (mutator.type) {
      case FlutterPlatformViewMutatorTypeTransform: {
        transformMatrix = CATransform3DConcat(mutator.transform, transformMatrix);
        break;
      }
      case FlutterPlatformViewMutatorTypeClipRect: {
        [self clipViewSetMaskView:clipView devicePixelRatio:devicePixelRatio];
        [(FlutterClippingMaskView*)clipView.maskView clipRect:mutator.rect matrix:transformMatrix];
        break;
      }
      case FlutterPlatformViewMutatorTypeClipRoundedRect:
      case FlutterPlatformViewMutatorTypeClipRoundedSuperellipse: {
        [self clipViewSetMaskView:clipView devicePixelRatio:devicePixelRatio];
        [(FlutterClippingMaskView*)clipView.maskView clipRRect:mutator.rect
                                                         radii:mutator.cornerRadii
                                                        matrix:transformMatrix];
        break;
      }
      case FlutterPlatformViewMutatorTypeClipPath: {
        [self clipViewSetMaskView:clipView devicePixelRatio:devicePixelRatio];
        [(FlutterClippingMaskView*)clipView.maskView clipPath:mutator.path matrix:transformMatrix];
        break;
      }
      case FlutterPlatformViewMutatorTypeOpacity:
        embeddedView.alpha = mutator.opacity * embeddedView.alpha;
        break;
      case FlutterPlatformViewMutatorTypeBackdropFilter: {
        if (!self.canApplyBlurBackdrop) {
          break;
        }
        CGRect filterRect = mutator.rect;
        // `filterRect` is in global coordinates. We need to convert to local space.
        filterRect = CGRectApplyAffineTransform(
            filterRect, CGAffineTransformMakeScale(1 / devicePixelRatio, 1 / devicePixelRatio));
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
        CGFloat blurRadius = mutator.blurSigmaX;
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
      case FlutterPlatformViewMutatorTypeBackdropClipRect: {
        // The frame already handles cropping into the rect so this can
        // no-op
        break;
      }
      case FlutterPlatformViewMutatorTypeBackdropClipRoundedRect:
      case FlutterPlatformViewMutatorTypeBackdropClipRoundedSuperellipse: {
        PendingRRectClip* clip = [[PendingRRectClip alloc] init];
        FlutterPlatformViewCornerRadii radii = mutator.cornerRadii;
        clip.topLeftRadius = radii.topLeft.width;
        clip.topRightRadius = radii.topRight.width;
        clip.bottomLeftRadius = radii.bottomLeft.width;
        clip.bottomRightRadius = radii.bottomRight.width;
        clip.isRoundedSuperellipse =
            mutator.type == FlutterPlatformViewMutatorTypeBackdropClipRoundedSuperellipse;
        [pendingClipRRects addObject:clip];
        break;
      }
      case FlutterPlatformViewMutatorTypeBackdropClipPath: {
        // TODO(https://github.com/flutter/flutter/issues/179127)
        break;
      }
    }
  }

  if (self.canApplyBlurBackdrop) {
    [clipView applyBlurBackdropFilters:blurFilters];
  }

  // The UIKit frame is set based on the logical resolution (points) instead of physical.
  // (https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html).
  // However, flow is based on the physical resolution. For example, 1000 pixels in flow equals
  // 500 points in UIKit for devices that has screenScale of 2. We need to scale the transformMatrix
  // down to the logical resoltion before applying it to the layer of PlatformView.
  CGFloat pointScale = 1.0 / devicePixelRatio;
  transformMatrix =
      CATransform3DConcat(transformMatrix, CATransform3DMakeScale(pointScale, pointScale, 1));

  // Reverse the offset of the clipView.
  // The clipView's frame includes the final translate of the final transform matrix.
  // Thus, this translate needs to be reversed so the platform view can layout at the correct
  // offset.
  //
  // Note that the transforms are not applied to the clipping paths because clipping paths happen on
  // the mask view, whose origin is always (0,0) to the _flutterView.
  CGPoint origin = clipView.frame.origin;
  transformMatrix =
      CATransform3DConcat(transformMatrix, CATransform3DMakeTranslation(-origin.x, -origin.y, 0));

  embeddedView.layer.transform = transformMatrix;
}

- (void)compositeLayer:(FlutterPlatformViewLayer*)layer devicePixelRatio:(CGFloat)devicePixelRatio {
  // TODO(https://github.com/flutter/flutter/issues/109700)
  CGRect frame =
      CGRectMake(0, 0, layer.size.width / devicePixelRatio, layer.size.height / devicePixelRatio);
  FlutterTouchInterceptingView* touchInterceptor =
      self.platformViews[@(layer.viewId)].touchInterceptor;
  touchInterceptor.layer.transform = CATransform3DIdentity;
  touchInterceptor.frame = frame;
  touchInterceptor.alpha = 1;

  UIView* clippingView = self.platformViews[@(layer.viewId)].rootView;
  // The frame of the clipping view should be the final bounding rect.
  // Because the translate matrix in the Mutator Stack also includes the offset,
  // when we apply the transforms matrix in |applyMutators:embeddedView:devicePixelRatio:|, we need
  // to remember to do a reverse translate.
  CGRect rect = layer.boundingRect;
  clippingView.frame =
      CGRectMake(rect.origin.x / devicePixelRatio, rect.origin.y / devicePixelRatio,
                 rect.size.width / devicePixelRatio, rect.size.height / devicePixelRatio);
  [self applyMutators:layer.mutators
          embeddedView:touchInterceptor
      devicePixelRatio:devicePixelRatio];
}

- (void)reset {
  // `platformViews` must only be modified on the platform thread.
  [self.taskRunner runNowOrPostTask:^{
    for (FlutterPlatformViewInfo* info in self.platformViews.objectEnumerator) {
      [info.rootView removeFromSuperview];
    }
    [self.platformViews removeAllObjects];
    [_previousCompositionOrder removeAllObjects];

    // Discard any pending disposals, since their views were removed above.
    // If we don't do this, `presentFrame:` would incorrectly dispose a view created with the same
    // ID after the hot restart.
    [self.viewsToDispose removeAllObjects];
  }];
}

- (void)performResize:(CGSize)frameSize {
  TRACE_EVENT0("flutter", "PlatformViewsController::PerformResize");
  FML_DCHECK([[NSThread currentThread] isMainThread]);

  if (self.flutterView != nil) {
    [(FlutterView*)self.flutterView setIntrinsicContentSize:frameSize];
  }
}

- (void)presentFrame:(FlutterPlatformViewFrame*)frame {
  TRACE_EVENT0("flutter", "PlatformViewsController::PerformSubmit");
  FML_DCHECK([[NSThread currentThread] isMainThread]);

  NSMutableArray<NSNumber*>* compositionOrder =
      [NSMutableArray arrayWithCapacity:frame.layers.count];
  for (FlutterPlatformViewLayer* layer in frame.layers) {
    [compositionOrder addObject:@(layer.viewId)];
  }

  [CATransaction begin];

  // Configure Flutter overlay views.
  int64_t overlayId = 0;
  for (FlutterPlatformViewLayer* layer in frame.layers) {
    FlutterPlatformViewOverlay* overlay = frame.overlays[@(layer.viewId)];
    if (overlay == nil) {
      continue;
    }
    [self updateOverlay:overlay
                  viewId:layer.viewId
               overlayId:overlayId
        devicePixelRatio:frame.devicePixelRatio];
    overlayId++;
  }

  // Dispose unused Flutter Views.
  for (UIView* view in [self computeViewsToDisposeWithCompositionOrder:compositionOrder]) {
    [view removeFromSuperview];
  }

  // Composite Platform Views.
  for (FlutterPlatformViewLayer* layer in frame.layers) {
    FlutterPlatformViewInfo* info = self.platformViews[@(layer.viewId)];
    // Recomposite only the views whose layers changed since they were last composited.
    if ([info.lastCompositedLayer isEqual:layer]) {
      continue;
    }
    [self compositeLayer:layer devicePixelRatio:frame.devicePixelRatio];
    info.lastCompositedLayer = layer;
  }

  // Present callbacks.
  frame.present();

  // If a layer was allocated in the previous frame, but it's not used in the current frame,
  // then it can be removed from the scene.
  [self removeUnusedOverlayViews:frame.unusedOverlayViews withCompositionOrder:compositionOrder];

  // Organize the layers by their z indexes.
  [self bringOverlaysIntoView:frame.overlays withCompositionOrder:compositionOrder];

  [CATransaction commit];
}

- (void)updateOverlay:(FlutterPlatformViewOverlay*)overlay
               viewId:(int64_t)viewId
            overlayId:(int64_t)overlayId
     devicePixelRatio:(CGFloat)devicePixelRatio {
  // Set the size of the clipping view, which clips the overlay view to `overlay.rect`.
  CGRect rect = overlay.rect;
  overlay.clippingView.frame =
      CGRectMake(rect.origin.x / devicePixelRatio, rect.origin.y / devicePixelRatio,
                 rect.size.width / devicePixelRatio, rect.size.height / devicePixelRatio);

  // Set a unique view identifier.
  // This allows the clipping view to be identified in XCUITests.
  overlay.clippingView.accessibilityIdentifier =
      [NSString stringWithFormat:@"platform_view[%lld].overlay[%lld]", viewId, overlayId];

  // Make the overlay view the size of the Flutter view, and line it up with the Flutter view.
  UIView* flutterView = self.flutterView;
  overlay.view.frame = [flutterView convertRect:flutterView.bounds toView:overlay.clippingView];

  // Set a unique view identifier.
  // This allows the overlay view to be identified in XCUITests.
  overlay.view.accessibilityIdentifier =
      [NSString stringWithFormat:@"platform_view[%lld].overlay_view[%lld]", viewId, overlayId];
}

- (void)bringOverlaysIntoView:(NSDictionary<NSNumber*, FlutterPlatformViewOverlay*>*)overlays
         withCompositionOrder:(NSArray<NSNumber*>*)compositionOrder {
  UIView* flutterView = self.flutterView;
  if (flutterView == nil) {
    return;
  }

  [_previousCompositionOrder setArray:compositionOrder];
  NSMutableArray* desiredPlatformSubviews = [NSMutableArray array];
  for (NSNumber* platformViewId in compositionOrder) {
    UIView* platformViewRoot = self.platformViews[platformViewId].rootView;
    if (platformViewRoot != nil) {
      [desiredPlatformSubviews addObject:platformViewRoot];
    }

    FlutterPlatformViewOverlay* overlay = overlays[platformViewId];
    if (overlay != nil) {
      [desiredPlatformSubviews addObject:overlay.clippingView];
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
  // TODO(hellohuanlin): investigate if it is possible to skip unnecessary bringOverlaysIntoView.
  if (![desiredPlatformSubviews isEqualToArray:existingPlatformSubviews]) {
    for (UIView* subview in desiredPlatformSubviews) {
      // `addSubview` will automatically reorder subview if it is already added.
      [flutterView addSubview:subview];
    }
  }
}

- (void)removeUnusedOverlayViews:(NSArray<UIView*>*)unusedOverlayViews
            withCompositionOrder:(NSArray<NSNumber*>*)compositionOrder {
  for (UIView* view in unusedOverlayViews) {
    [view removeFromSuperview];
  }

  // Remove unused platform views.
  for (NSNumber* viewId in _previousCompositionOrder) {
    if (![compositionOrder containsObject:viewId]) {
      FlutterPlatformViewInfo* info = self.platformViews[viewId];
      [info.rootView removeFromSuperview];
      // Clear the layer so that the view is composited in the next frame that includes it.
      info.lastCompositedLayer = nil;
    }
  }
}

- (NSArray<UIView*>*)computeViewsToDisposeWithCompositionOrder:
    (NSArray<NSNumber*>*)compositionOrder {
  if (self.viewsToDispose.count == 0) {
    return @[];
  }

  NSMutableArray<UIView*>* views = [NSMutableArray array];
  NSMutableSet<NSNumber*>* viewsToDelayDispose = [NSMutableSet set];
  for (NSNumber* viewId in self.viewsToDispose) {
    if ([compositionOrder containsObject:viewId]) {
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

#pragma mark - Properties

- (NSArray<NSNumber*>*)previousCompositionOrder {
  return [_previousCompositionOrder copy];
}

@end
