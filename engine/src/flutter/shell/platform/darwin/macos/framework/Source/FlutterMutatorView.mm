// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMutatorView.h"

#include <QuartzCore/QuartzCore.h>

#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/embedder.h"

@interface FlutterMutatorView () {
  /// Each of these views clips to a CGPathRef. These views, if present,
  /// are nested (first is child of FlutterMutatorView and last is parent of
  // _platformView).
  NSMutableArray* _pathClipViews;

  // View right above the platform view. Used to apply the final transform
  // (sans the translation) to the platform view.
  NSView* _platformViewContainer;

  NSView* _platformView;
}

@end

/// View that clips that content to a specific CGPathRef.
/// Clipping is done through a CAShapeLayer mask, which avoids the need to
/// rasterize the mask.
@interface FlutterPathClipView : NSView

@end

@implementation FlutterPathClipView

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    self.wantsLayer = YES;
  }
  return self;
}

- (BOOL)isFlipped {
  return YES;
}

/// Clip the view to the given path. Offset top left corner of platform view
/// in global logical coordinates.
- (void)maskToPath:(CGPathRef)path withOrigin:(CGPoint)origin {
  CAShapeLayer* maskLayer = self.layer.mask;
  if (maskLayer == nil) {
    maskLayer = [CAShapeLayer layer];
    self.layer.mask = maskLayer;
  }
  maskLayer.path = path;
  maskLayer.transform = CATransform3DMakeTranslation(-origin.x, -origin.y, 0);
}

@end

namespace {
CATransform3D ToCATransform3D(const FlutterTransformation& t) {
  CATransform3D transform = CATransform3DIdentity;
  transform.m11 = t.scaleX;
  transform.m21 = t.skewX;
  transform.m41 = t.transX;
  transform.m14 = t.pers0;
  transform.m12 = t.skewY;
  transform.m22 = t.scaleY;
  transform.m42 = t.transY;
  transform.m24 = t.pers1;
  return transform;
}

CGRect FromFlutterRect(const FlutterRect& rect) {
  return CGRectMake(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
}

FlutterRect ToFlutterRect(const CGRect& rect) {
  return FlutterRect{
      .left = rect.origin.x,
      .top = rect.origin.y,
      .right = rect.origin.x + rect.size.width,
      .bottom = rect.origin.y + rect.size.height,

  };
}

/// Returns whether the point is inside ellipse with given radius (centered at 0, 0).
bool PointInsideEllipse(const CGPoint& point, const FlutterSize& radius) {
  return (point.x * point.x) / (radius.width * radius.width) +
             (point.y * point.y) / (radius.height * radius.height) <
         1.0;
}

bool RoundRectCornerIntersects(const FlutterRoundedRect& roundRect, const FlutterRect& rect) {
  // Inner coordinate of the top left corner of the round rect.
  CGPoint inner_top_left =
      CGPointMake(roundRect.rect.left + roundRect.upper_left_corner_radius.width,
                  roundRect.rect.top + roundRect.upper_left_corner_radius.height);

  // Position of `rect` corner relative to inner_top_left.
  CGPoint relative_top_left =
      CGPointMake(rect.left - inner_top_left.x, rect.top - inner_top_left.y);

  // `relative_top_left` is in upper left quadrant.
  if (relative_top_left.x < 0 && relative_top_left.y < 0) {
    if (!PointInsideEllipse(relative_top_left, roundRect.upper_left_corner_radius)) {
      return true;
    }
  }

  // Inner coordinate of the top right corner of the round rect.
  CGPoint inner_top_right =
      CGPointMake(roundRect.rect.right - roundRect.upper_right_corner_radius.width,
                  roundRect.rect.top + roundRect.upper_right_corner_radius.height);

  // Positon of `rect` corner relative to inner_top_right.
  CGPoint relative_top_right =
      CGPointMake(rect.right - inner_top_right.x, rect.top - inner_top_right.y);

  // `relative_top_right` is in top right quadrant.
  if (relative_top_right.x > 0 && relative_top_right.y < 0) {
    if (!PointInsideEllipse(relative_top_right, roundRect.upper_right_corner_radius)) {
      return true;
    }
  }

  // Inner coordinate of the bottom left corner of the round rect.
  CGPoint inner_bottom_left =
      CGPointMake(roundRect.rect.left + roundRect.lower_left_corner_radius.width,
                  roundRect.rect.bottom - roundRect.lower_left_corner_radius.height);

  // Position of `rect` corner relative to inner_bottom_left.
  CGPoint relative_bottom_left =
      CGPointMake(rect.left - inner_bottom_left.x, rect.bottom - inner_bottom_left.y);

  // `relative_bottom_left` is in bottom left quadrant.
  if (relative_bottom_left.x < 0 && relative_bottom_left.y > 0) {
    if (!PointInsideEllipse(relative_bottom_left, roundRect.lower_left_corner_radius)) {
      return true;
    }
  }

  // Inner coordinate of the bottom right corner of the round rect.
  CGPoint inner_bottom_right =
      CGPointMake(roundRect.rect.right - roundRect.lower_right_corner_radius.width,
                  roundRect.rect.bottom - roundRect.lower_right_corner_radius.height);

  // Position of `rect` corner relative to inner_bottom_right.
  CGPoint relative_bottom_right =
      CGPointMake(rect.right - inner_bottom_right.x, rect.bottom - inner_bottom_right.y);

  // `relative_bottom_right` is in bottom right quadrant.
  if (relative_bottom_right.x > 0 && relative_bottom_right.y > 0) {
    if (!PointInsideEllipse(relative_bottom_right, roundRect.lower_right_corner_radius)) {
      return true;
    }
  }

  return false;
}

CGPathRef PathFromRoundedRect(const FlutterRoundedRect& roundedRect) {
  CGMutablePathRef path = CGPathCreateMutable();

  const auto& rect = roundedRect.rect;
  const auto& topLeft = roundedRect.upper_left_corner_radius;
  const auto& topRight = roundedRect.upper_right_corner_radius;
  const auto& bottomLeft = roundedRect.lower_left_corner_radius;
  const auto& bottomRight = roundedRect.lower_right_corner_radius;

  CGPathMoveToPoint(path, nullptr, rect.left + topLeft.width, rect.top);
  CGPathAddLineToPoint(path, nullptr, rect.right - topRight.width, rect.top);
  CGPathAddCurveToPoint(path, nullptr, rect.right, rect.top, rect.right, rect.top + topRight.height,
                        rect.right, rect.top + topRight.height);
  CGPathAddLineToPoint(path, nullptr, rect.right, rect.bottom - bottomRight.height);
  CGPathAddCurveToPoint(path, nullptr, rect.right, rect.bottom, rect.right - bottomRight.width,
                        rect.bottom, rect.right - bottomRight.width, rect.bottom);
  CGPathAddLineToPoint(path, nullptr, rect.left + bottomLeft.width, rect.bottom);
  CGPathAddCurveToPoint(path, nullptr, rect.left, rect.bottom, rect.left,
                        rect.bottom - bottomLeft.height, rect.left,
                        rect.bottom - bottomLeft.height);
  CGPathAddLineToPoint(path, nullptr, rect.left, rect.top + topLeft.height);
  CGPathAddCurveToPoint(path, nullptr, rect.left, rect.top, rect.left + topLeft.width, rect.top,
                        rect.left + topLeft.width, rect.top);
  CGPathCloseSubpath(path);
  return path;
}

using MutationVector = std::vector<FlutterPlatformViewMutation>;

/// Returns a vector of FlutterPlatformViewMutation object pointers associated with a platform view.
/// The transforms sent from the engine include a transform from logical to physical coordinates.
/// Since Cocoa deals only in logical points, this function prepends a scale transform that scales
/// back from physical to logical coordinates to compensate.
MutationVector MutationsForPlatformView(const FlutterPlatformView* view, float scale) {
  MutationVector mutations;
  mutations.reserve(view->mutations_count + 1);
  mutations.push_back({
      .type = kFlutterPlatformViewMutationTypeTransformation,
      .transformation{
          .scaleX = 1.0 / scale,
          .scaleY = 1.0 / scale,
      },
  });
  for (size_t i = 0; i < view->mutations_count; ++i) {
    mutations.push_back(*view->mutations[i]);
  }
  return mutations;
}

/// Returns the composition of all transformation mutations in the mutations vector.
CATransform3D CATransformFromMutations(const MutationVector& mutations) {
  CATransform3D transform = CATransform3DIdentity;
  for (auto mutation : mutations) {
    switch (mutation.type) {
      case kFlutterPlatformViewMutationTypeTransformation: {
        CATransform3D mutationTransform = ToCATransform3D(mutation.transformation);
        transform = CATransform3DConcat(mutationTransform, transform);
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRect:
      case kFlutterPlatformViewMutationTypeClipRoundedRect:
      case kFlutterPlatformViewMutationTypeOpacity:
        break;
    }
  }
  return transform;
}

/// Returns the opacity for all opacity mutations in the mutations vector.
float OpacityFromMutations(const MutationVector& mutations) {
  float opacity = 1.0;
  for (auto mutation : mutations) {
    switch (mutation.type) {
      case kFlutterPlatformViewMutationTypeOpacity:
        opacity *= mutation.opacity;
        break;
      case kFlutterPlatformViewMutationTypeClipRect:
      case kFlutterPlatformViewMutationTypeClipRoundedRect:
      case kFlutterPlatformViewMutationTypeTransformation:
        break;
    }
  }
  return opacity;
}

/// Returns the clip rect generated by the intersection of clips in the mutations vector.
CGRect MasterClipFromMutations(CGRect bounds, const MutationVector& mutations) {
  // Master clip in global logical coordinates. This is intersection of all clip rectangles
  // present in mutators.
  CGRect master_clip = bounds;

  // Create the initial transform.
  CATransform3D transform = CATransform3DIdentity;
  for (auto mutation : mutations) {
    switch (mutation.type) {
      case kFlutterPlatformViewMutationTypeClipRect: {
        CGRect rect = CGRectApplyAffineTransform(FromFlutterRect(mutation.clip_rect),
                                                 CATransform3DGetAffineTransform(transform));
        master_clip = CGRectIntersection(rect, master_clip);
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundedRect: {
        CGAffineTransform affineTransform = CATransform3DGetAffineTransform(transform);
        CGRect rect = CGRectApplyAffineTransform(FromFlutterRect(mutation.clip_rounded_rect.rect),
                                                 affineTransform);
        master_clip = CGRectIntersection(rect, master_clip);
        break;
      }
      case kFlutterPlatformViewMutationTypeTransformation:
        transform = CATransform3DConcat(ToCATransform3D(mutation.transformation), transform);
        break;
      case kFlutterPlatformViewMutationTypeOpacity:
        break;
    }
  }
  return master_clip;
}

/// A rounded rectangle and transform associated with it.
typedef struct {
  FlutterRoundedRect rrect;
  CGAffineTransform transform;
} ClipRoundedRect;

/// Returns the set of all rounded rect paths generated by clips in the mutations vector.
NSMutableArray* RoundedRectClipsFromMutations(CGRect master_clip, const MutationVector& mutations) {
  std::vector<ClipRoundedRect> rounded_rects;

  CATransform3D transform = CATransform3DIdentity;
  for (auto mutation : mutations) {
    switch (mutation.type) {
      case kFlutterPlatformViewMutationTypeClipRoundedRect: {
        CGAffineTransform affineTransform = CATransform3DGetAffineTransform(transform);
        rounded_rects.push_back({mutation.clip_rounded_rect, affineTransform});
        break;
      }
      case kFlutterPlatformViewMutationTypeTransformation:
        transform = CATransform3DConcat(ToCATransform3D(mutation.transformation), transform);
        break;
      case kFlutterPlatformViewMutationTypeClipRect:
      case kFlutterPlatformViewMutationTypeOpacity:
        break;
    }
  }

  NSMutableArray* paths = [NSMutableArray array];
  for (const auto& r : rounded_rects) {
    CGAffineTransform inverse = CGAffineTransformInvert(r.transform);
    // Transform master clip to clip rect coordinates and check if this view intersects one of the
    // corners, which means we need to use path clipping.
    CGRect localMasterClip = CGRectApplyAffineTransform(master_clip, inverse);

    // Only clip to rounded rectangle path if the view intersects some of the round corners. If
    // not, clipping to masterClip is enough.
    if (RoundRectCornerIntersects(r.rrect, ToFlutterRect(localMasterClip))) {
      CGPathRef path = PathFromRoundedRect(r.rrect);
      CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(path, &r.transform);
      [paths addObject:(__bridge id)transformedPath];
      CGPathRelease(transformedPath);
      CGPathRelease(path);
    }
  }
  return paths;
}
}  // namespace

@implementation FlutterMutatorView

- (NSView*)platformView {
  return _platformView;
}

- (NSMutableArray*)pathClipViews {
  return _pathClipViews;
}

- (NSView*)platformViewContainer {
  return _platformViewContainer;
}

- (instancetype)initWithPlatformView:(NSView*)platformView {
  if (self = [super initWithFrame:NSZeroRect]) {
    _platformView = platformView;
    _pathClipViews = [NSMutableArray array];
    self.wantsLayer = YES;
  }
  return self;
}

- (NSView*)hitTest:(NSPoint)point {
  return nil;
}

- (BOOL)isFlipped {
  return YES;
}

/// Returns the scale factor to translate logical pixels to physical pixels for this view.
- (CGFloat)contentsScale {
  return self.superview != nil ? self.superview.layer.contentsScale : 1.0;
}

/// Whenever possible view will be clipped using layer bounds.
/// If clipping to path is needed, CAShapeLayer(s) will be used as mask.
/// Clipping to round rect only clips to path if round corners are intersected.
- (void)applyFlutterLayer:(const FlutterLayer*)layer {
  // Compute the untransformed bounding rect for the platform view in logical pixels.
  // FlutterLayer.size is in physical pixels but Cocoa uses logical points.
  CGFloat scale = [self contentsScale];
  MutationVector mutations = MutationsForPlatformView(layer->platform_view, scale);

  CATransform3D finalTransform = CATransformFromMutations(mutations);

  // Compute the untransformed bounding rect for the platform view in logical pixels.
  // FlutterLayer.size is in physical pixels but Cocoa uses logical points.
  CGRect untransformedBoundingRect =
      CGRectMake(0, 0, layer->size.width / scale, layer->size.height / scale);
  CGRect finalBoundingRect = CGRectApplyAffineTransform(
      untransformedBoundingRect, CATransform3DGetAffineTransform(finalTransform));
  self.frame = finalBoundingRect;

  // Compute the layer opacity.
  self.layer.opacity = OpacityFromMutations(mutations);

  // Compute the master clip in global logical coordinates.
  CGRect masterClip = MasterClipFromMutations(finalBoundingRect, mutations);
  if (CGRectIsNull(masterClip)) {
    self.hidden = YES;
    return;
  }
  self.hidden = NO;

  /// Paths in global logical coordinates that need to be clipped to.
  NSMutableArray* paths = RoundedRectClipsFromMutations(masterClip, mutations);

  // Add / remove path clip views depending on the number of paths.
  while (_pathClipViews.count > paths.count) {
    NSView* view = _pathClipViews.lastObject;
    [view removeFromSuperview];
    [_pathClipViews removeLastObject];
  }

  NSView* lastView = self;

  for (size_t i = 0; i < paths.count; ++i) {
    FlutterPathClipView* pathClipView = nil;
    if (i < _pathClipViews.count) {
      pathClipView = _pathClipViews[i];
    } else {
      pathClipView = [[FlutterPathClipView alloc] initWithFrame:self.bounds];
      [_pathClipViews addObject:pathClipView];
      [lastView addSubview:pathClipView];
    }
    pathClipView.frame = self.bounds;
    [pathClipView maskToPath:(__bridge CGPathRef)[paths objectAtIndex:i]
                  withOrigin:finalBoundingRect.origin];
    lastView = pathClipView;
  }

  // Used to apply sublayer transform.
  if (_platformViewContainer == nil) {
    _platformViewContainer = [[NSView alloc] initWithFrame:self.bounds];
    _platformViewContainer.wantsLayer = YES;
  }

  [lastView addSubview:_platformViewContainer];
  _platformViewContainer.frame = self.bounds;

  [_platformViewContainer addSubview:_platformView];
  _platformView.frame = untransformedBoundingRect;

  // Transform for the platform view is finalTransform adjusted for bounding rect origin.
  _platformViewContainer.layer.sublayerTransform = CATransform3DTranslate(
      finalTransform, -finalBoundingRect.origin.x / finalTransform.m11 /* scaleX */,
      -finalBoundingRect.origin.y / finalTransform.m22 /* scaleY */, 0);

  // By default NSView clips children to frame. If masterClip is tighter than mutator view frame,
  // the frame is set to masterClip and child offset adjusted to compensate for the difference.
  if (!CGRectEqualToRect(masterClip, finalBoundingRect)) {
    FML_DCHECK(self.subviews.count == 1);
    auto subview = self.subviews.firstObject;
    FML_DCHECK(subview.frame.origin.x == 0 && subview.frame.origin.y == 0);
    subview.frame = CGRectMake(finalBoundingRect.origin.x - masterClip.origin.x,
                               finalBoundingRect.origin.y - masterClip.origin.y,
                               subview.frame.size.width, subview.frame.size.height);
    self.frame = masterClip;
  }
}

@end
