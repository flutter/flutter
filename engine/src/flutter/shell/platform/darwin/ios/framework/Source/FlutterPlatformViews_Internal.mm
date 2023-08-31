// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"

static int kMaxPointsInVerb = 4;
static const NSUInteger kFlutterClippingMaskViewPoolCapacity = 5;

namespace flutter {

FlutterPlatformViewLayer::FlutterPlatformViewLayer(
    const fml::scoped_nsobject<UIView>& overlay_view,
    const fml::scoped_nsobject<UIView>& overlay_view_wrapper,
    std::unique_ptr<IOSSurface> ios_surface,
    std::unique_ptr<Surface> surface)
    : overlay_view(overlay_view),
      overlay_view_wrapper(overlay_view_wrapper),
      ios_surface(std::move(ios_surface)),
      surface(std::move(surface)){};

FlutterPlatformViewLayer::~FlutterPlatformViewLayer() = default;

FlutterPlatformViewsController::FlutterPlatformViewsController()
    : layer_pool_(std::make_unique<FlutterPlatformViewLayerPool>()),
      weak_factory_(std::make_unique<fml::WeakPtrFactory<FlutterPlatformViewsController>>(this)) {
  mask_view_pool_.reset(
      [[FlutterClippingMaskViewPool alloc] initWithCapacity:kFlutterClippingMaskViewPoolCapacity]);
};

FlutterPlatformViewsController::~FlutterPlatformViewsController() = default;

fml::WeakPtr<flutter::FlutterPlatformViewsController> FlutterPlatformViewsController::GetWeakPtr() {
  return weak_factory_->GetWeakPtr();
}

CATransform3D GetCATransform3DFromSkMatrix(const SkMatrix& matrix) {
  // Skia only supports 2D transform so we don't map z.
  CATransform3D transform = CATransform3DIdentity;
  transform.m11 = matrix.getScaleX();
  transform.m21 = matrix.getSkewX();
  transform.m41 = matrix.getTranslateX();
  transform.m14 = matrix.getPerspX();

  transform.m12 = matrix.getSkewY();
  transform.m22 = matrix.getScaleY();
  transform.m42 = matrix.getTranslateY();
  transform.m24 = matrix.getPerspY();
  return transform;
}

void ResetAnchor(CALayer* layer) {
  // Flow uses (0, 0) to apply transform matrix so we need to match that in Quartz.
  layer.anchorPoint = CGPointZero;
  layer.position = CGPointZero;
}

CGRect GetCGRectFromSkRect(const SkRect& clipSkRect) {
  return CGRectMake(clipSkRect.fLeft, clipSkRect.fTop, clipSkRect.fRight - clipSkRect.fLeft,
                    clipSkRect.fBottom - clipSkRect.fTop);
}

BOOL BlurRadiusEqualToBlurRadius(CGFloat radius1, CGFloat radius2) {
  const CGFloat epsilon = 0.01;
  return radius1 - radius2 < epsilon;
}

}  // namespace flutter

@interface PlatformViewFilter ()

// `YES` if the backdropFilterView has been configured at least once.
@property(nonatomic) BOOL backdropFilterViewConfigured;
@property(nonatomic, retain) UIVisualEffectView* backdropFilterView;

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
             visualEffectView:(UIVisualEffectView*)visualEffectView {
  if (self = [super init]) {
    _frame = frame;
    _blurRadius = blurRadius;
    [PlatformViewFilter prepareOnce:visualEffectView];
    if (![PlatformViewFilter isUIVisualEffectViewImplementationValid]) {
      FML_DLOG(ERROR) << "Apple's API for UIVisualEffectView changed. Update the implementation to "
                         "access the gaussianBlur CAFilter.";
      [self release];
      return nil;
    }
    _backdropFilterView = [visualEffectView retain];
    _backdropFilterViewConfigured = NO;
  }
  return self;
}

+ (void)resetPreparation {
  _preparedOnce = NO;
  [_gaussianBlurFilter release];
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
          _gaussianBlurFilter = [filter retain];
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

- (void)dealloc {
  [_backdropFilterView release];
  _backdropFilterView = nil;

  [super dealloc];
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
  NSObject* gaussianBlurFilter = [[_gaussianBlurFilter copy] autorelease];
  FML_DCHECK(gaussianBlurFilter);
  UIView* backdropView = visualEffectView.subviews[_indexOfBackdropView];
  [gaussianBlurFilter setValue:@(_blurRadius) forKey:@"inputRadius"];
  backdropView.layer.filters = @[ gaussianBlurFilter ];

  UIView* visualEffectSubview = visualEffectView.subviews[_indexOfVisualEffectSubview];
  visualEffectSubview.layer.backgroundColor = UIColor.clearColor.CGColor;
  visualEffectView.frame = _frame;

  if (_backdropFilterView != visualEffectView) {
    _backdropFilterView = [visualEffectView retain];
  }
}

@end

@interface ChildClippingView ()

@property(retain, nonatomic) NSArray<PlatformViewFilter*>* filters;
@property(retain, nonatomic) NSMutableArray<UIVisualEffectView*>* backdropFilterSubviews;

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

- (void)dealloc {
  [_filters release];
  _filters = nil;

  [_backdropFilterSubviews release];
  _backdropFilterSubviews = nil;

  [super dealloc];
}

- (NSMutableArray*)backdropFilterSubviews {
  if (!_backdropFilterSubviews) {
    _backdropFilterSubviews = [[[NSMutableArray alloc] init] retain];
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
}

- (instancetype)initWithFrame:(CGRect)frame {
  return [self initWithFrame:frame screenScale:[UIScreen mainScreen].scale];
}

- (instancetype)initWithFrame:(CGRect)frame screenScale:(CGFloat)screenScale {
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = UIColor.clearColor;
    _reverseScreenScale = CATransform3DMakeScale(1 / screenScale, 1 / screenScale, 1);
  }
  return self;
}

- (void)reset {
  paths_.clear();
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
}

- (void)clipRect:(const SkRect&)clipSkRect matrix:(const SkMatrix&)matrix {
  CGRect clipRect = flutter::GetCGRectFromSkRect(clipSkRect);
  CGPathRef path = CGPathCreateWithRect(clipRect, nil);
  // The `matrix` is based on the physical pixels, convert it to UIKit points.
  CATransform3D matrixInPoints =
      CATransform3DConcat(flutter::GetCATransform3DFromSkMatrix(matrix), _reverseScreenScale);
  paths_.push_back([self getTransformedPath:path matrix:matrixInPoints]);
}

- (void)clipRRect:(const SkRRect&)clipSkRRect matrix:(const SkMatrix&)matrix {
  CGPathRef pathRef = nullptr;
  switch (clipSkRRect.getType()) {
    case SkRRect::kEmpty_Type: {
      break;
    }
    case SkRRect::kRect_Type: {
      [self clipRect:clipSkRRect.rect() matrix:matrix];
      return;
    }
    case SkRRect::kOval_Type:
    case SkRRect::kSimple_Type: {
      CGRect clipRect = flutter::GetCGRectFromSkRect(clipSkRRect.rect());
      pathRef = CGPathCreateWithRoundedRect(clipRect, clipSkRRect.getSimpleRadii().x(),
                                            clipSkRRect.getSimpleRadii().y(), nil);
      break;
    }
    case SkRRect::kNinePatch_Type:
    case SkRRect::kComplex_Type: {
      CGMutablePathRef mutablePathRef = CGPathCreateMutable();
      // Complex types, we manually add each corner.
      SkRect clipSkRect = clipSkRRect.rect();
      SkVector topLeftRadii = clipSkRRect.radii(SkRRect::kUpperLeft_Corner);
      SkVector topRightRadii = clipSkRRect.radii(SkRRect::kUpperRight_Corner);
      SkVector bottomRightRadii = clipSkRRect.radii(SkRRect::kLowerRight_Corner);
      SkVector bottomLeftRadii = clipSkRRect.radii(SkRRect::kLowerLeft_Corner);

      // Start drawing RRect
      // Move point to the top left corner adding the top left radii's x.
      CGPathMoveToPoint(mutablePathRef, nil, clipSkRect.fLeft + topLeftRadii.x(), clipSkRect.fTop);
      // Move point horizontally right to the top right corner and add the top right curve.
      CGPathAddLineToPoint(mutablePathRef, nil, clipSkRect.fRight - topRightRadii.x(),
                           clipSkRect.fTop);
      CGPathAddCurveToPoint(mutablePathRef, nil, clipSkRect.fRight, clipSkRect.fTop,
                            clipSkRect.fRight, clipSkRect.fTop + topRightRadii.y(),
                            clipSkRect.fRight, clipSkRect.fTop + topRightRadii.y());
      // Move point vertically down to the bottom right corner and add the bottom right curve.
      CGPathAddLineToPoint(mutablePathRef, nil, clipSkRect.fRight,
                           clipSkRect.fBottom - bottomRightRadii.y());
      CGPathAddCurveToPoint(mutablePathRef, nil, clipSkRect.fRight, clipSkRect.fBottom,
                            clipSkRect.fRight - bottomRightRadii.x(), clipSkRect.fBottom,
                            clipSkRect.fRight - bottomRightRadii.x(), clipSkRect.fBottom);
      // Move point horizontally left to the bottom left corner and add the bottom left curve.
      CGPathAddLineToPoint(mutablePathRef, nil, clipSkRect.fLeft + bottomLeftRadii.x(),
                           clipSkRect.fBottom);
      CGPathAddCurveToPoint(mutablePathRef, nil, clipSkRect.fLeft, clipSkRect.fBottom,
                            clipSkRect.fLeft, clipSkRect.fBottom - bottomLeftRadii.y(),
                            clipSkRect.fLeft, clipSkRect.fBottom - bottomLeftRadii.y());
      // Move point vertically up to the top left corner and add the top left curve.
      CGPathAddLineToPoint(mutablePathRef, nil, clipSkRect.fLeft,
                           clipSkRect.fTop + topLeftRadii.y());
      CGPathAddCurveToPoint(mutablePathRef, nil, clipSkRect.fLeft, clipSkRect.fTop,
                            clipSkRect.fLeft + topLeftRadii.x(), clipSkRect.fTop,
                            clipSkRect.fLeft + topLeftRadii.x(), clipSkRect.fTop);
      CGPathCloseSubpath(mutablePathRef);

      pathRef = mutablePathRef;
      break;
    }
  }
  // The `matrix` is based on the physical pixels, convert it to UIKit points.
  CATransform3D matrixInPoints =
      CATransform3DConcat(flutter::GetCATransform3DFromSkMatrix(matrix), _reverseScreenScale);
  // TODO(cyanglaz): iOS does not seem to support hard edge on CAShapeLayer. It clearly stated that
  // the CAShaperLayer will be drawn antialiased. Need to figure out a way to do the hard edge
  // clipping on iOS.
  paths_.push_back([self getTransformedPath:pathRef matrix:matrixInPoints]);
}

- (void)clipPath:(const SkPath&)path matrix:(const SkMatrix&)matrix {
  if (!path.isValid()) {
    return;
  }
  if (path.isEmpty()) {
    return;
  }
  CGMutablePathRef pathRef = CGPathCreateMutable();

  // Loop through all verbs and translate them into CGPath
  SkPath::Iter iter(path, true);
  SkPoint pts[kMaxPointsInVerb];
  SkPath::Verb verb = iter.next(pts);
  SkPoint last_pt_from_last_verb = SkPoint::Make(0, 0);
  while (verb != SkPath::kDone_Verb) {
    if (verb == SkPath::kLine_Verb || verb == SkPath::kQuad_Verb || verb == SkPath::kConic_Verb ||
        verb == SkPath::kCubic_Verb) {
      FML_DCHECK(last_pt_from_last_verb == pts[0]);
    }
    switch (verb) {
      case SkPath::kMove_Verb: {
        CGPathMoveToPoint(pathRef, nil, pts[0].x(), pts[0].y());
        last_pt_from_last_verb = pts[0];
        break;
      }
      case SkPath::kLine_Verb: {
        CGPathAddLineToPoint(pathRef, nil, pts[1].x(), pts[1].y());
        last_pt_from_last_verb = pts[1];
        break;
      }
      case SkPath::kQuad_Verb: {
        CGPathAddQuadCurveToPoint(pathRef, nil, pts[1].x(), pts[1].y(), pts[2].x(), pts[2].y());
        last_pt_from_last_verb = pts[2];
        break;
      }
      case SkPath::kConic_Verb: {
        // Conic is not available in quartz, we use quad to approximate.
        // TODO(cyanglaz): Better approximate the conic path.
        // https://github.com/flutter/flutter/issues/35062
        CGPathAddQuadCurveToPoint(pathRef, nil, pts[1].x(), pts[1].y(), pts[2].x(), pts[2].y());
        last_pt_from_last_verb = pts[2];
        break;
      }
      case SkPath::kCubic_Verb: {
        CGPathAddCurveToPoint(pathRef, nil, pts[1].x(), pts[1].y(), pts[2].x(), pts[2].y(),
                              pts[3].x(), pts[3].y());
        last_pt_from_last_verb = pts[3];
        break;
      }
      case SkPath::kClose_Verb: {
        CGPathCloseSubpath(pathRef);
        break;
      }
      case SkPath::kDone_Verb: {
        break;
      }
    }
    verb = iter.next(pts);
  }
  // The `matrix` is based on the physical pixels, convert it to UIKit points.
  CATransform3D matrixInPoints =
      CATransform3DConcat(flutter::GetCATransform3DFromSkMatrix(matrix), _reverseScreenScale);
  paths_.push_back([self getTransformedPath:pathRef matrix:matrixInPoints]);
}

- (fml::CFRef<CGPathRef>)getTransformedPath:(CGPathRef)path matrix:(CATransform3D)matrix {
  CGAffineTransform affine =
      CGAffineTransformMake(matrix.m11, matrix.m12, matrix.m21, matrix.m22, matrix.m41, matrix.m42);
  CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(path, &affine);
  CGPathRelease(path);
  return fml::CFRef<CGPathRef>(transformedPath);
}

@end

@interface FlutterClippingMaskViewPool ()

// The maximum number of `FlutterClippingMaskView` the pool can contain.
// This prevents the pool to grow infinately and limits the maximum memory a pool can use.
@property(assign, nonatomic) NSUInteger capacity;

// The pool contains the views that are available to use.
// The number of items in the pool must not excceds `capacity`.
@property(retain, nonatomic) NSMutableSet<FlutterClippingMaskView*>* pool;

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
    return
        [[[FlutterClippingMaskView alloc] initWithFrame:frame
                                            screenScale:[UIScreen mainScreen].scale] autorelease];
  }
  FlutterClippingMaskView* maskView = [[[self.pool anyObject] retain] autorelease];
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

- (void)dealloc {
  [_pool release];

  [super dealloc];
}

@end
