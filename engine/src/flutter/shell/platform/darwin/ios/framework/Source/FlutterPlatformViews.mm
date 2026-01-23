// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

#import <WebKit/WebKit.h>

#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"

FLUTTER_ASSERT_ARC

namespace {
static CGRect GetCGRectFromDlRect(const flutter::DlRect& clipDlRect) {
  return CGRectMake(clipDlRect.GetX(),      //
                    clipDlRect.GetY(),      //
                    clipDlRect.GetWidth(),  //
                    clipDlRect.GetHeight());
}

CATransform3D GetCATransform3DFromDlMatrix(const flutter::DlMatrix& matrix) {
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

class CGPathReceiver final : public flutter::DlPathReceiver {
 public:
  void MoveTo(const flutter::DlPoint& p2, bool will_be_closed) override {  //
    CGPathMoveToPoint(path_ref_, nil, p2.x, p2.y);
  }
  void LineTo(const flutter::DlPoint& p2) override {
    CGPathAddLineToPoint(path_ref_, nil, p2.x, p2.y);
  }
  void QuadTo(const flutter::DlPoint& cp, const flutter::DlPoint& p2) override {
    CGPathAddQuadCurveToPoint(path_ref_, nil, cp.x, cp.y, p2.x, p2.y);
  }
  // bool conic_to(...) { CGPath has no equivalent to the conic curve type }
  void CubicTo(const flutter::DlPoint& cp1,
               const flutter::DlPoint& cp2,
               const flutter::DlPoint& p2) override {
    CGPathAddCurveToPoint(path_ref_, nil,  //
                          cp1.x, cp1.y, cp2.x, cp2.y, p2.x, p2.y);
  }
  void Close() override { CGPathCloseSubpath(path_ref_); }

  CGMutablePathRef TakePath() const { return path_ref_; }

 private:
  CGMutablePathRef path_ref_ = CGPathCreateMutable();
};
}  // namespace

@interface PlatformViewFilter ()

// `YES` if the backdropFilterView has been configured at least once.
@property(nonatomic) BOOL backdropFilterViewConfigured;
@property(nonatomic) UIVisualEffectView* backdropFilterView;

// Updates the `visualEffectView` with the current filter parameters.
// Also sets `self.backdropFilterView` to the updated visualEffectView.
- (void)updateVisualEffectView:(UIVisualEffectView*)visualEffectView;

@end

@implementation PlatformViewFilter

static NSObject* _gaussianBlurFilter = nil;
// The index of "_UIVisualEffectBackdropView" in UIVisualEffectView's subViews.
static NSInteger _indexOfBackdropView = -1;
// The index of "_UIVisualEffectSubview" in UIVisualEffectView's subViews.
static NSInteger _indexOfVisualEffectSubview = -1;
static BOOL _preparedOnce = NO;

- (instancetype)initWithFrame:(CGRect)frame
                   blurRadius:(CGFloat)blurRadius
                 cornerRadius:(CGFloat)cornerRadius
             visualEffectView:(UIVisualEffectView*)visualEffectView {
  if (self = [super init]) {
    _frame = frame;
    _blurRadius = blurRadius;
    _cornerRadius = cornerRadius;
    [PlatformViewFilter prepareOnce:visualEffectView];
    if (![PlatformViewFilter isUIVisualEffectViewImplementationValid]) {
      FML_DLOG(ERROR) << "Apple's API for UIVisualEffectView changed. Update the implementation to "
                         "access the gaussianBlur CAFilter.";
      return nil;
    }
    _backdropFilterView = visualEffectView;
    _backdropFilterViewConfigured = NO;
  }
  return self;
}

+ (void)resetPreparation {
  _preparedOnce = NO;
  _gaussianBlurFilter = nil;
  _indexOfBackdropView = -1;
  _indexOfVisualEffectSubview = -1;
}

+ (void)prepareOnce:(UIVisualEffectView*)visualEffectView {
  if (_preparedOnce) {
    return;
  }
  for (NSUInteger i = 0; i < visualEffectView.subviews.count; i++) {
    UIView* view = visualEffectView.subviews[i];
    if ([NSStringFromClass([view class]) hasSuffix:@"BackdropView"]) {
      _indexOfBackdropView = i;
      for (NSObject* filter in view.layer.filters) {
        if ([[filter valueForKey:@"name"] isEqual:@"gaussianBlur"] &&
            [[filter valueForKey:@"inputRadius"] isKindOfClass:[NSNumber class]]) {
          _gaussianBlurFilter = filter;
          break;
        }
      }
    } else if ([NSStringFromClass([view class]) hasSuffix:@"VisualEffectSubview"]) {
      _indexOfVisualEffectSubview = i;
    }
  }
  _preparedOnce = YES;
}

+ (BOOL)isUIVisualEffectViewImplementationValid {
  return _indexOfBackdropView > -1 && _indexOfVisualEffectSubview > -1 && _gaussianBlurFilter;
}

- (UIVisualEffectView*)backdropFilterView {
  FML_DCHECK(_backdropFilterView);
  if (!self.backdropFilterViewConfigured) {
    [self updateVisualEffectView:_backdropFilterView];
    self.backdropFilterViewConfigured = YES;
  }
  return _backdropFilterView;
}

- (void)updateVisualEffectView:(UIVisualEffectView*)visualEffectView {
  NSObject* gaussianBlurFilter = [_gaussianBlurFilter copy];
  FML_DCHECK(gaussianBlurFilter);
  UIView* backdropView = visualEffectView.subviews[_indexOfBackdropView];
  [gaussianBlurFilter setValue:@(_blurRadius) forKey:@"inputRadius"];
  backdropView.layer.filters = @[ gaussianBlurFilter ];

  UIView* visualEffectSubview = visualEffectView.subviews[_indexOfVisualEffectSubview];
  visualEffectSubview.layer.backgroundColor = UIColor.clearColor.CGColor;
  visualEffectView.frame = _frame;

  visualEffectView.layer.cornerRadius = _cornerRadius;
  visualEffectView.clipsToBounds = YES;

  self.backdropFilterView = visualEffectView;
}

@end

@interface ChildClippingView ()

@property(nonatomic, copy) NSArray<PlatformViewFilter*>* filters;
@property(nonatomic) NSMutableArray<UIVisualEffectView*>* backdropFilterSubviews;

@end

@implementation ChildClippingView

// The ChildClippingView's frame is the bounding rect of the platform view. we only want touches to
// be hit tested and consumed by this view if they are inside the embedded platform view which could
// be smaller the embedded platform view is rotated.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
  for (UIView* view in self.subviews) {
    if ([view pointInside:[self convertPoint:point toView:view] withEvent:event]) {
      return YES;
    }
  }
  return NO;
}

- (void)applyBlurBackdropFilters:(NSArray<PlatformViewFilter*>*)filters {
  FML_DCHECK(self.filters.count == self.backdropFilterSubviews.count);
  if (self.filters.count == 0 && filters.count == 0) {
    return;
  }
  self.filters = filters;
  NSUInteger index = 0;
  for (index = 0; index < self.filters.count; index++) {
    UIVisualEffectView* backdropFilterView;
    PlatformViewFilter* filter = self.filters[index];
    if (self.backdropFilterSubviews.count <= index) {
      backdropFilterView = filter.backdropFilterView;
      [self addSubview:backdropFilterView];
      [self.backdropFilterSubviews addObject:backdropFilterView];
    } else {
      [filter updateVisualEffectView:self.backdropFilterSubviews[index]];
    }
  }
  for (NSUInteger i = self.backdropFilterSubviews.count; i > index; i--) {
    [self.backdropFilterSubviews[i - 1] removeFromSuperview];
    [self.backdropFilterSubviews removeLastObject];
  }
}

- (NSMutableArray*)backdropFilterSubviews {
  if (!_backdropFilterSubviews) {
    _backdropFilterSubviews = [[NSMutableArray alloc] init];
  }
  return _backdropFilterSubviews;
}

@end

@interface FlutterClippingMaskView ()

// A `CATransform3D` matrix represnts a scale transform that revese UIScreen.scale.
//
// The transform matrix passed in clipRect/clipRRect/clipPath methods are in device coordinate
// space. The transfrom matrix concats `reverseScreenScale` to create a transform matrix in the iOS
// logical coordinates (points).
//
// See https://developer.apple.com/documentation/uikit/uiscreen/1617836-scale?language=objc for
// information about screen scale.
@property(nonatomic) CATransform3D reverseScreenScale;

- (fml::CFRef<CGPathRef>)getTransformedPath:(CGPathRef)path matrix:(CATransform3D)matrix;

@end

@implementation FlutterClippingMaskView {
  std::vector<fml::CFRef<CGPathRef>> paths_;
  BOOL containsNonRectPath_;
  CGRect rectSoFar_;
}

- (instancetype)initWithFrame:(CGRect)frame {
  return [self initWithFrame:frame screenScale:[UIScreen mainScreen].scale];
}

- (instancetype)initWithFrame:(CGRect)frame screenScale:(CGFloat)screenScale {
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = UIColor.clearColor;
    _reverseScreenScale = CATransform3DMakeScale(1 / screenScale, 1 / screenScale, 1);
    rectSoFar_ = self.bounds;
    containsNonRectPath_ = NO;
  }
  return self;
}

+ (Class)layerClass {
  return [CAShapeLayer class];
}

- (CAShapeLayer*)shapeLayer {
  return (CAShapeLayer*)self.layer;
}

- (void)reset {
  paths_.clear();
  rectSoFar_ = self.bounds;
  containsNonRectPath_ = NO;
  [self shapeLayer].path = nil;
  [self setNeedsDisplay];
}

// In some scenarios, when we add this view as a maskView of the ChildClippingView, iOS added
// this view as a subview of the ChildClippingView.
// This results this view blocking touch events on the ChildClippingView.
// So we should always ignore any touch events sent to this view.
// See https://github.com/flutter/flutter/issues/66044
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
  return NO;
}

- (void)drawRect:(CGRect)rect {
  // It's hard to compute intersection of arbitrary non-rect paths.
  // So we fallback to software rendering.
  if (containsNonRectPath_ && paths_.size() > 1) {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    // For mask view, only the alpha channel is used.
    CGContextSetAlpha(context, 1);

    for (size_t i = 0; i < paths_.size(); i++) {
      CGContextAddPath(context, paths_.at(i));
      CGContextClip(context);
    }
    CGContextFillRect(context, rect);
    CGContextRestoreGState(context);
  } else {
    // Either a single path, or multiple rect paths.
    // Use hardware rendering with CAShapeLayer.
    [super drawRect:rect];
    if (![self shapeLayer].path) {
      if (paths_.size() == 1) {
        // A single path, either rect or non-rect.
        [self shapeLayer].path = paths_.at(0);
      } else {
        // Multiple paths, all paths must be rects.
        CGPathRef pathSoFar = CGPathCreateWithRect(rectSoFar_, nil);
        [self shapeLayer].path = pathSoFar;
        CGPathRelease(pathSoFar);
      }
    }
  }
}

- (void)clipRect:(const flutter::DlRect&)clipDlRect matrix:(const flutter::DlMatrix&)matrix {
  CGRect clipRect = GetCGRectFromDlRect(clipDlRect);
  CGPathRef path = CGPathCreateWithRect(clipRect, nil);
  // The `matrix` is based on the physical pixels, convert it to UIKit points.
  CATransform3D matrixInPoints =
      CATransform3DConcat(GetCATransform3DFromDlMatrix(matrix), _reverseScreenScale);
  paths_.push_back([self getTransformedPath:path matrix:matrixInPoints]);
  CGAffineTransform affine = [self affineWithMatrix:matrixInPoints];
  // Make sure the rect is not rotated (only translated or scaled).
  if (affine.b == 0 && affine.c == 0) {
    rectSoFar_ = CGRectIntersection(rectSoFar_, CGRectApplyAffineTransform(clipRect, affine));
  } else {
    containsNonRectPath_ = YES;
  }
}

- (void)clipRRect:(const flutter::DlRoundRect&)clipDlRRect matrix:(const flutter::DlMatrix&)matrix {
  if (clipDlRRect.IsEmpty()) {
    return;
  } else if (clipDlRRect.IsRect()) {
    [self clipRect:clipDlRRect.GetBounds() matrix:matrix];
    return;
  } else {
    CGPathRef pathRef = nullptr;
    containsNonRectPath_ = YES;

    if (clipDlRRect.GetRadii().AreAllCornersSame()) {
      CGRect clipRect = GetCGRectFromDlRect(clipDlRRect.GetBounds());
      auto radii = clipDlRRect.GetRadii();
      pathRef =
          CGPathCreateWithRoundedRect(clipRect, radii.top_left.width, radii.top_left.height, nil);
    } else {
      CGMutablePathRef mutablePathRef = CGPathCreateMutable();
      // Complex types, we manually add each corner.
      flutter::DlRect clipDlRect = clipDlRRect.GetBounds();
      auto left = clipDlRect.GetLeft();
      auto top = clipDlRect.GetTop();
      auto right = clipDlRect.GetRight();
      auto bottom = clipDlRect.GetBottom();
      flutter::DlRoundingRadii radii = clipDlRRect.GetRadii();
      auto& top_left = radii.top_left;
      auto& top_right = radii.top_right;
      auto& bottom_left = radii.bottom_left;
      auto& bottom_right = radii.bottom_right;

      // Start drawing RRect
      // These calculations are off, the AddCurve methods add a Bezier curve
      // which, for round rects should be a "magic distance" from the end
      // point of the horizontal/vertical section to the corner.
      // Move point to the top left corner adding the top left radii's x.
      CGPathMoveToPoint(mutablePathRef, nil,  //
                        left + top_left.width, top);
      // Move point horizontally right to the top right corner and add the top right curve.
      CGPathAddLineToPoint(mutablePathRef, nil,  //
                           right - top_right.width, top);
      CGPathAddCurveToPoint(mutablePathRef, nil,            //
                            right, top,                     //
                            right, top + top_right.height,  //
                            right, top + top_right.height);
      // Move point vertically down to the bottom right corner and add the bottom right curve.
      CGPathAddLineToPoint(mutablePathRef, nil,  //
                           right, bottom - bottom_right.height);
      CGPathAddCurveToPoint(mutablePathRef, nil,                 //
                            right, bottom,                       //
                            right - bottom_right.width, bottom,  //
                            right - bottom_right.width, bottom);
      // Move point horizontally left to the bottom left corner and add the bottom left curve.
      CGPathAddLineToPoint(mutablePathRef, nil,  //
                           left + bottom_left.width, bottom);
      CGPathAddCurveToPoint(mutablePathRef, nil,                //
                            left, bottom,                       //
                            left, bottom - bottom_left.height,  //
                            left, bottom - bottom_left.height);
      // Move point vertically up to the top left corner and add the top left curve.
      CGPathAddLineToPoint(mutablePathRef, nil,  //
                           left, top + top_left.height);
      CGPathAddCurveToPoint(mutablePathRef, nil,         //
                            left, top,                   //
                            left + top_left.width, top,  //
                            left + top_left.width, top);
      CGPathCloseSubpath(mutablePathRef);
      pathRef = mutablePathRef;
    }
    // The `matrix` is based on the physical pixels, convert it to UIKit points.
    CATransform3D matrixInPoints =
        CATransform3DConcat(GetCATransform3DFromDlMatrix(matrix), _reverseScreenScale);
    // TODO(cyanglaz): iOS does not seem to support hard edge on CAShapeLayer. It clearly stated
    // that the CAShaperLayer will be drawn antialiased. Need to figure out a way to do the hard
    // edge clipping on iOS.
    paths_.push_back([self getTransformedPath:pathRef matrix:matrixInPoints]);
  }
}

- (void)clipPath:(const flutter::DlPath&)dlPath matrix:(const flutter::DlMatrix&)matrix {
  containsNonRectPath_ = YES;

  CGPathReceiver receiver;

  // TODO(flar): https://github.com/flutter/flutter/issues/164826
  // CGPaths do not have an inherit fill type, we would need to remember
  // the fill type and employ it when we use the path.
  dlPath.Dispatch(receiver);

  // The `matrix` is based on the physical pixels, convert it to UIKit points.
  CATransform3D matrixInPoints =
      CATransform3DConcat(GetCATransform3DFromDlMatrix(matrix), _reverseScreenScale);
  paths_.push_back([self getTransformedPath:receiver.TakePath() matrix:matrixInPoints]);
}

- (CGAffineTransform)affineWithMatrix:(CATransform3D)matrix {
  return CGAffineTransformMake(matrix.m11, matrix.m12, matrix.m21, matrix.m22, matrix.m41,
                               matrix.m42);
}

- (fml::CFRef<CGPathRef>)getTransformedPath:(CGPathRef)path matrix:(CATransform3D)matrix {
  CGAffineTransform affine = [self affineWithMatrix:matrix];
  CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(path, &affine);

  CGPathRelease(path);
  return fml::CFRef<CGPathRef>(transformedPath);
}

@end

@interface FlutterClippingMaskViewPool ()

// The maximum number of `FlutterClippingMaskView` the pool can contain.
// This prevents the pool to grow infinately and limits the maximum memory a pool can use.
@property(nonatomic) NSUInteger capacity;

// The pool contains the views that are available to use.
// The number of items in the pool must not excceds `capacity`.
@property(nonatomic) NSMutableSet<FlutterClippingMaskView*>* pool;

@end

@implementation FlutterClippingMaskViewPool : NSObject

- (instancetype)initWithCapacity:(NSInteger)capacity {
  if (self = [super init]) {
    // Most of cases, there are only one PlatformView in the scene.
    // Thus init with the capacity of 1.
    _pool = [[NSMutableSet alloc] initWithCapacity:1];
    _capacity = capacity;
  }
  return self;
}

- (FlutterClippingMaskView*)getMaskViewWithFrame:(CGRect)frame {
  FML_DCHECK(self.pool.count <= self.capacity);
  if (self.pool.count == 0) {
    // The pool is empty, alloc a new one.
    return [[FlutterClippingMaskView alloc] initWithFrame:frame
                                              screenScale:UIScreen.mainScreen.scale];
  }
  FlutterClippingMaskView* maskView = [self.pool anyObject];
  maskView.frame = frame;
  [maskView reset];
  [self.pool removeObject:maskView];
  return maskView;
}

- (void)insertViewToPoolIfNeeded:(FlutterClippingMaskView*)maskView {
  FML_DCHECK(![self.pool containsObject:maskView]);
  FML_DCHECK(self.pool.count <= self.capacity);
  if (self.pool.count == self.capacity) {
    return;
  }
  [self.pool addObject:maskView];
}

@end

@implementation UIView (FirstResponder)
- (BOOL)flt_hasFirstResponderInViewHierarchySubtree {
  if (self.isFirstResponder) {
    return YES;
  }
  for (UIView* subview in self.subviews) {
    if (subview.flt_hasFirstResponderInViewHierarchySubtree) {
      return YES;
    }
  }
  return NO;
}
@end

@interface FlutterTouchInterceptingView ()
@property(nonatomic, weak, readonly) UIView* embeddedView;
@property(nonatomic, readonly) FlutterDelayingGestureRecognizer* delayingRecognizer;
@property(nonatomic, readonly) FlutterPlatformViewGestureRecognizersBlockingPolicy blockingPolicy;
@end

@implementation FlutterTouchInterceptingView
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView
             platformViewsController:(FlutterPlatformViewsController*)platformViewsController
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)blockingPolicy {
  self = [super initWithFrame:embeddedView.frame];
  if (self) {
    self.multipleTouchEnabled = YES;
    _embeddedView = embeddedView;
    embeddedView.autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    [self addSubview:embeddedView];

    ForwardingGestureRecognizer* forwardingRecognizer =
        [[ForwardingGestureRecognizer alloc] initWithTarget:self
                                    platformViewsController:platformViewsController];

    _delayingRecognizer =
        [[FlutterDelayingGestureRecognizer alloc] initWithTarget:self
                                                          action:nil
                                            forwardingRecognizer:forwardingRecognizer];
    _blockingPolicy = blockingPolicy;

    [self addGestureRecognizer:_delayingRecognizer];
    [self addGestureRecognizer:forwardingRecognizer];
  }
  return self;
}

- (void)forceResetForwardingGestureRecognizerState {
  // When iPad pencil is involved in a finger touch gesture, the gesture is not reset to "possible"
  // state and is stuck on "failed" state, which causes subsequent touches to be blocked. As a
  // workaround, we force reset the state by recreating the forwarding gesture recognizer. See:
  // https://github.com/flutter/flutter/issues/136244
  ForwardingGestureRecognizer* oldForwardingRecognizer =
      (ForwardingGestureRecognizer*)self.delayingRecognizer.forwardingRecognizer;
  ForwardingGestureRecognizer* newForwardingRecognizer =
      [oldForwardingRecognizer recreateRecognizerWithTarget:self];
  self.delayingRecognizer.forwardingRecognizer = newForwardingRecognizer;
  [self removeGestureRecognizer:oldForwardingRecognizer];
  [self addGestureRecognizer:newForwardingRecognizer];
}

- (void)releaseGesture {
  self.delayingRecognizer.state = UIGestureRecognizerStateFailed;
}

- (BOOL)containsWebView:(UIView*)view remainingSubviewDepth:(int)remainingSubviewDepth {
  if (remainingSubviewDepth < 0) {
    return NO;
  }
  if ([view isKindOfClass:[WKWebView class]]) {
    return YES;
  }
  for (UIView* subview in view.subviews) {
    if ([self containsWebView:subview remainingSubviewDepth:remainingSubviewDepth - 1]) {
      return YES;
    }
  }
  return NO;
}

- (void)searchAndFixWebView:(UIView*)view {
  if ([view isKindOfClass:[WKWebView class]]) {
    return [self searchAndFixWebViewGestureRecognzier:view];
  } else {
    for (UIView* subview in view.subviews) {
      [self searchAndFixWebView:subview];
    }
  }
}

- (void)searchAndFixWebViewGestureRecognzier:(UIView*)view {
  for (UIGestureRecognizer* recognizer in view.gestureRecognizers) {
    // This is to fix a bug on iOS 26 where web view link is not tappable.
    // We reset the web view's WKTouchEventsGestureRecognizer in a bad state
    // by disabling and re-enabling it.
    // See: https://github.com/flutter/flutter/issues/175099.
    // See also: https://github.com/flutter/engine/pull/56804 for an explanation of the
    // bug on iOS 18.2, which is still valid on iOS 26.
    // Warning: This is just a quick fix that patches the bug. For example,
    // touches on a drawing website is still not completely blocked. A proper solution
    // should rely on overriding the hitTest behavior.
    // See: https://github.com/flutter/flutter/issues/179916.
    if (recognizer.enabled &&
        [NSStringFromClass([recognizer class]) hasSuffix:@"TouchEventsGestureRecognizer"]) {
      recognizer.enabled = NO;
      recognizer.enabled = YES;
    }
  }
  for (UIView* subview in view.subviews) {
    [self searchAndFixWebViewGestureRecognzier:subview];
  }
}

- (void)blockGesture {
  switch (_blockingPolicy) {
    case FlutterPlatformViewGestureRecognizersBlockingPolicyEager:
      // We block all other gesture recognizers immediately in this policy.
      self.delayingRecognizer.state = UIGestureRecognizerStateEnded;

      // On iOS 18.2, WKWebView's internal recognizer likely caches the old state of its blocking
      // recognizers (i.e. delaying recognizer), resulting in non-tappable links. See
      // https://github.com/flutter/flutter/issues/158961. Removing and adding back the delaying
      // recognizer solves the problem, possibly because UIKit notifies all the recognizers related
      // to (blocking or blocked by) this recognizer. It is not possible to inject this workaround
      // from the web view plugin level. Right now we only observe this issue for
      // FlutterPlatformViewGestureRecognizersBlockingPolicyEager, but we should try it if a similar
      // issue arises for the other policy.
      if (@available(iOS 26.0, *)) {
        // This performs a nested DFS, with the outer one searching for any web view, and the inner
        // one searching for a TouchEventsGestureRecognizer inside the web view. Once found, disable
        // and immediately reenable it to reset its state.
        // TODO(hellohuanlin): remove this flag after it is battle tested.
        NSNumber* isWorkaroundDisabled =
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FLTDisableWebViewGestureReset"];
        if (!isWorkaroundDisabled.boolValue) {
          [self searchAndFixWebView:self.embeddedView];
        }
      } else if (@available(iOS 18.2, *)) {
        // This workaround is designed for WKWebView only. The 1P web view plugin provides a
        // WKWebView itself as the platform view. However, some 3P plugins provide wrappers of
        // WKWebView instead. So we perform DFS to search the view hierarchy (with a depth limit).
        // Passing a limit of 0 means only searching for platform view itself; Pass 1 to include its
        // children as well, and so on. We should be conservative and start with a small number. The
        // AdMob banner has a WKWebView at depth 7.
        if ([self containsWebView:self.embeddedView remainingSubviewDepth:1]) {
          [self removeGestureRecognizer:self.delayingRecognizer];
          [self addGestureRecognizer:self.delayingRecognizer];
        }
      }

      break;
    case FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded:
      if (self.delayingRecognizer.touchedEndedWithoutBlocking) {
        // If touchesEnded of the `DelayingGesureRecognizer` has been already invoked,
        // we want to set the state of the `DelayingGesureRecognizer` to
        // `UIGestureRecognizerStateEnded` as soon as possible.
        self.delayingRecognizer.state = UIGestureRecognizerStateEnded;
      } else {
        // If touchesEnded of the `DelayingGesureRecognizer` has not been invoked,
        // We will set a flag to notify the `DelayingGesureRecognizer` to set the state to
        // `UIGestureRecognizerStateEnded` when touchesEnded is called.
        self.delayingRecognizer.shouldEndInNextTouchesEnded = YES;
      }
      break;
    default:
      break;
  }
}

// We want the intercepting view to consume the touches and not pass the touches up to the parent
// view. Make the touch event method not call super will not pass the touches up to the parent view.
// Hence we overide the touch event methods and do nothing.
- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
}

- (id)accessibilityContainer {
  return self.flutterAccessibilityContainer;
}

@end

@implementation FlutterDelayingGestureRecognizer

- (instancetype)initWithTarget:(id)target
                        action:(SEL)action
          forwardingRecognizer:(UIGestureRecognizer*)forwardingRecognizer {
  self = [super initWithTarget:target action:action];
  if (self) {
    self.delaysTouchesBegan = YES;
    self.delaysTouchesEnded = YES;
    self.delegate = self;
    _shouldEndInNextTouchesEnded = NO;
    _touchedEndedWithoutBlocking = NO;
    _forwardingRecognizer = forwardingRecognizer;
  }
  return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  // The forwarding gesture recognizer should always get all touch events, so it should not be
  // required to fail by any other gesture recognizer.
  return otherGestureRecognizer != _forwardingRecognizer && otherGestureRecognizer != self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  return otherGestureRecognizer == self;
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  self.touchedEndedWithoutBlocking = NO;
  [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  if (self.shouldEndInNextTouchesEnded) {
    self.state = UIGestureRecognizerStateEnded;
    self.shouldEndInNextTouchesEnded = NO;
  } else {
    self.touchedEndedWithoutBlocking = YES;
  }
  [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  self.state = UIGestureRecognizerStateFailed;
}
@end

@implementation ForwardingGestureRecognizer {
  // Weak reference to PlatformViewsController. The PlatformViewsController has
  // a reference to the FlutterViewController, where we can dispatch pointer events to.
  //
  // The lifecycle of PlatformViewsController is bind to FlutterEngine, which should always
  // outlives the FlutterViewController. And ForwardingGestureRecognizer is owned by a subview of
  // FlutterView, so the ForwardingGestureRecognizer never out lives FlutterViewController.
  // Therefore, `_platformViewsController` should never be nullptr.
  __weak FlutterPlatformViewsController* _platformViewsController;
  // Counting the pointers that has started in one touch sequence.
  NSInteger _currentTouchPointersCount;
  // We can't dispatch events to the framework without this back pointer.
  // This gesture recognizer retains the `FlutterViewController` until the
  // end of a gesture sequence, that is all the touches in touchesBegan are concluded
  // with |touchesCancelled| or |touchesEnded|.
  UIViewController<FlutterViewResponder>* _flutterViewController;
}

- (instancetype)initWithTarget:(id)target
       platformViewsController:(FlutterPlatformViewsController*)platformViewsController {
  self = [super initWithTarget:target action:nil];
  if (self) {
    self.delegate = self;
    FML_DCHECK(platformViewsController);
    _platformViewsController = platformViewsController;
    _currentTouchPointersCount = 0;
  }
  return self;
}

- (ForwardingGestureRecognizer*)recreateRecognizerWithTarget:(id)target {
  return [[ForwardingGestureRecognizer alloc] initWithTarget:target
                                     platformViewsController:_platformViewsController];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  FML_DCHECK(_currentTouchPointersCount >= 0);
  if (_currentTouchPointersCount == 0) {
    // At the start of each gesture sequence, we reset the `_flutterViewController`,
    // so that all the touch events in the same sequence are forwarded to the same
    // `_flutterViewController`.
    _flutterViewController = _platformViewsController.flutterViewController;
  }
  [_flutterViewController touchesBegan:touches withEvent:event];
  _currentTouchPointersCount += touches.count;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController touchesEnded:touches withEvent:event];
  _currentTouchPointersCount -= touches.count;
  // Touches in one touch sequence are sent to the touchesEnded method separately if different
  // fingers stop touching the screen at different time. So one touchesEnded method triggering does
  // not necessarially mean the touch sequence has ended. We Only set the state to
  // UIGestureRecognizerStateFailed when all the touches in the current touch sequence is ended.
  if (_currentTouchPointersCount == 0) {
    self.state = UIGestureRecognizerStateFailed;
    _flutterViewController = nil;
    [self forceResetStateIfNeeded];
  }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  // In the event of platform view is removed, iOS generates a "stationary" change type instead of
  // "cancelled" change type.
  // Flutter needs all the cancelled touches to be "cancelled" change types in order to correctly
  // handle gesture sequence.
  // We always override the change type to "cancelled".
  [_flutterViewController forceTouchesCancelled:touches];
  _currentTouchPointersCount -= touches.count;
  if (_currentTouchPointersCount == 0) {
    self.state = UIGestureRecognizerStateFailed;
    _flutterViewController = nil;
    [self forceResetStateIfNeeded];
  }
}

- (void)forceResetStateIfNeeded {
  __weak ForwardingGestureRecognizer* weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    ForwardingGestureRecognizer* strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (strongSelf.state != UIGestureRecognizerStatePossible) {
      [(FlutterTouchInterceptingView*)strongSelf.view forceResetForwardingGestureRecognizerState];
    }
  });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  return YES;
}
@end

@implementation PendingRRectClip
@end
