// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/platform_view_layer_conversion.h"

#include "flutter/display_list/effects/image_filters/dl_blur_image_filter.h"
#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

namespace flutter {

namespace {

class CGPathReceiver final : public DlPathReceiver {
 public:
  void MoveTo(const DlPoint& p2, bool will_be_closed) override {
    CGPathMoveToPoint(path_ref_, nil, p2.x, p2.y);
  }
  void LineTo(const DlPoint& p2) override { CGPathAddLineToPoint(path_ref_, nil, p2.x, p2.y); }
  void QuadTo(const DlPoint& cp, const DlPoint& p2) override {
    CGPathAddQuadCurveToPoint(path_ref_, nil, cp.x, cp.y, p2.x, p2.y);
  }
  // bool conic_to(...) { CGPath has no equivalent to the conic curve type }
  void CubicTo(const DlPoint& cp1, const DlPoint& cp2, const DlPoint& p2) override {
    CGPathAddCurveToPoint(path_ref_, nil, cp1.x, cp1.y, cp2.x, cp2.y, p2.x, p2.y);
  }
  void Close() override { CGPathCloseSubpath(path_ref_); }

  fml::CFRef<CGPathRef> TakePath() { return fml::CFRef<CGPathRef>(path_ref_.Release()); }

 private:
  fml::CFRef<CGMutablePathRef> path_ref_ = fml::CFRef<CGMutablePathRef>(CGPathCreateMutable());
};

FlutterPlatformViewCornerRadii GetCornerRadiiFromDlRoundingRadii(const DlRoundingRadii& radii) {
  return {
      .topLeft = CGSizeMake(radii.top_left.width, radii.top_left.height),
      .topRight = CGSizeMake(radii.top_right.width, radii.top_right.height),
      .bottomRight = CGSizeMake(radii.bottom_right.width, radii.bottom_right.height),
      .bottomLeft = CGSizeMake(radii.bottom_left.width, radii.bottom_left.height),
  };
}

// Returns the mutators in `mutators_stack`, ordered outermost first.
//
// `bounding_rect` is the bounding rect of the platform view once its transforms have been applied.
NSArray<FlutterPlatformViewMutator*>* GetMutatorsFromMutatorsStack(
    const MutatorsStack& mutators_stack,
    const DlRect& bounding_rect) {
  NSMutableArray<FlutterPlatformViewMutator*>* mutators = [[NSMutableArray alloc] init];

  // The product of the transforms that enclose the current mutator.
  // Clips are in that coordinate space, so we need it to check whether a clip covers the view.
  DlMatrix transform;
  for (auto iter = mutators_stack.Begin(); iter != mutators_stack.End(); ++iter) {
    const Mutator& mutator = **iter;
    switch (mutator.GetType()) {
      case MutatorType::kTransform: {
        transform = transform * mutator.GetMatrix();
        CATransform3D matrix = GetCATransform3DFromDlMatrix(mutator.GetMatrix());
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithTransform:matrix]];
        break;
      }
      case MutatorType::kClipRect: {
        if (DisplayListMatrixClipState::TransformedRectCoversBounds(mutator.GetRect(), transform,
                                                                    bounding_rect)) {
          break;
        }
        CGRect rect = GetCGRectFromDlRect(mutator.GetRect());
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithClipRect:rect]];
        break;
      }
      case MutatorType::kClipRRect: {
        const DlRoundRect& rrect = mutator.GetRRect();
        if (DisplayListMatrixClipState::TransformedRRectCoversBounds(rrect, transform,
                                                                     bounding_rect)) {
          break;
        }
        CGRect rect = GetCGRectFromDlRect(rrect.GetBounds());
        FlutterPlatformViewCornerRadii radii = GetCornerRadiiFromDlRoundingRadii(rrect.GetRadii());
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithClipRoundedRect:rect
                                                                             radii:radii]];
        break;
      }
      case MutatorType::kClipRSE: {
        const DlRoundSuperellipse& rse = mutator.GetRSE();
        if (DisplayListMatrixClipState::TransformedRoundSuperellipseCoversBounds(rse, transform,
                                                                                 bounding_rect)) {
          break;
        }
        CGRect rect = GetCGRectFromDlRect(rse.GetBounds());
        FlutterPlatformViewCornerRadii radii = GetCornerRadiiFromDlRoundingRadii(rse.GetRadii());
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithClipRoundedSuperellipse:rect
                                                                                     radii:radii]];
        break;
      }
      case MutatorType::kClipPath: {
        // TODO(cyanglaz): Find a way to pre-determine if path contains the PlatformView bounding
        // rect. See `ClipRRectContainsPlatformViewBoundingRect`.
        // https://github.com/flutter/flutter/issues/118650
        fml::CFRef<CGPathRef> path = GetCGPathFromDlPath(mutator.GetPath());
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithClipPath:path]];
        break;
      }
      case MutatorType::kOpacity:
        [mutators
            addObject:[FlutterPlatformViewMutator mutatorWithOpacity:mutator.GetAlphaFloat()]];
        break;
      case MutatorType::kBackdropFilter: {
        // Only support DlBlurImageFilter for BackdropFilter.
        const DlBlurImageFilter* blur = mutator.GetFilterMutation().GetFilter().asBlur();
        if (blur == nullptr) {
          break;
        }
        CGRect rect = GetCGRectFromDlRect(mutator.GetFilterMutation().GetFilterRect());
        [mutators
            addObject:[FlutterPlatformViewMutator mutatorWithBackdropFilterRect:rect
                                                                     blurSigmaX:blur->sigma_x()
                                                                     blurSigmaY:blur->sigma_y()]];
        break;
      }
      case MutatorType::kBackdropClipRect: {
        CGRect rect = GetCGRectFromDlRect(mutator.GetBackdropClipRect().rect);
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithBackdropClipRect:rect]];
        break;
      }
      case MutatorType::kBackdropClipRRect: {
        const DlRoundRect& rrect = mutator.GetBackdropClipRRect().rrect;
        CGRect rect = GetCGRectFromDlRect(rrect.GetBounds());
        FlutterPlatformViewCornerRadii radii = GetCornerRadiiFromDlRoundingRadii(rrect.GetRadii());
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithBackdropClipRoundedRect:rect
                                                                                     radii:radii]];
        break;
      }
      case MutatorType::kBackdropClipRSuperellipse: {
        const DlRoundSuperellipse& rse = mutator.GetBackdropClipRSuperellipse().rse;
        CGRect rect = GetCGRectFromDlRect(rse.GetBounds());
        FlutterPlatformViewCornerRadii radii = GetCornerRadiiFromDlRoundingRadii(rse.GetRadii());
        [mutators addObject:[FlutterPlatformViewMutator
                                mutatorWithBackdropClipRoundedSuperellipse:rect
                                                                     radii:radii]];
        break;
      }
      case MutatorType::kBackdropClipPath: {
        fml::CFRef<CGPathRef> path = GetCGPathFromDlPath(mutator.GetBackdropClipPath().path);
        [mutators addObject:[FlutterPlatformViewMutator mutatorWithBackdropClipPath:path]];
        break;
      }
    }
  }
  return mutators;
}

}  // namespace

CATransform3D GetCATransform3DFromDlMatrix(const DlMatrix& matrix) {
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

CGRect GetCGRectFromDlRect(const DlRect& rect) {
  return CGRectMake(rect.GetX(), rect.GetY(), rect.GetWidth(), rect.GetHeight());
}

fml::CFRef<CGPathRef> GetCGPathFromDlPath(const DlPath& path) {
  CGPathReceiver receiver;

  // TODO(flar): https://github.com/flutter/flutter/issues/164826
  // CGPaths do not have an inherit fill type, we would need to remember
  // the fill type and employ it when we use the path.
  path.Dispatch(receiver);
  return receiver.TakePath();
}

FlutterPlatformViewLayer* GetPlatformViewLayerFromEmbeddedViewParams(
    int64_t view_id,
    const EmbeddedViewParams& params,
    double device_pixel_ratio) {
  const DlRect& bounding_rect = params.finalBoundingRect();
  CGSize size = CGSizeMake(params.sizePoints().width * device_pixel_ratio,
                           params.sizePoints().height * device_pixel_ratio);
  NSArray<FlutterPlatformViewMutator*>* mutators =
      GetMutatorsFromMutatorsStack(params.mutatorsStack(), bounding_rect);
  return [[FlutterPlatformViewLayer alloc] initWithViewId:view_id
                                             boundingRect:GetCGRectFromDlRect(bounding_rect)
                                                     size:size
                                                 mutators:mutators];
}

}  // namespace flutter
