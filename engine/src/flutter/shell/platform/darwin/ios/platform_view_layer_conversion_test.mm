// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/platform_view_layer_conversion.h"

#import <XCTest/XCTest.h>

#include "flutter/display_list/effects/dl_image_filters.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@interface PlatformViewLayerConversionTest : XCTestCase
@end

@implementation PlatformViewLayerConversionTest

- (void)testMutatorsAreOrderedOutermostFirst {
  flutter::DlMatrix scale = flutter::DlMatrix::MakeScale({3, 3, 1});
  flutter::DlMatrix translation = flutter::DlMatrix::MakeTranslation({10, 20});
  flutter::MutatorsStack stack;
  stack.PushTransform(scale);
  stack.PushClipRect(flutter::DlRect::MakeLTRB(0, 0, 50, 50));
  stack.PushTransform(translation);
  stack.PushOpacity(128);
  flutter::EmbeddedViewParams params(scale * translation, flutter::DlSize(100, 100), stack);

  FlutterPlatformViewLayer* layer =
      flutter::GetPlatformViewLayerFromEmbeddedViewParams(1, params, 3);

  NSArray<FlutterPlatformViewMutator*>* expected = @[
    [FlutterPlatformViewMutator mutatorWithTransform:CATransform3DMakeScale(3, 3, 1)],
    [FlutterPlatformViewMutator mutatorWithClipRect:CGRectMake(0, 0, 50, 50)],
    [FlutterPlatformViewMutator mutatorWithTransform:CATransform3DMakeTranslation(10, 20, 0)],
    [FlutterPlatformViewMutator mutatorWithOpacity:flutter::DlColor::toOpacity(128)],
  ];
  XCTAssertEqualObjects(layer.mutators, expected);
}

- (void)testLayerHasViewIdBoundingRectAndSize {
  flutter::DlMatrix scale = flutter::DlMatrix::MakeScale({3, 3, 1});
  flutter::DlMatrix translation = flutter::DlMatrix::MakeTranslation({10, 20});
  flutter::MutatorsStack stack;
  stack.PushTransform(scale);
  stack.PushTransform(translation);
  flutter::EmbeddedViewParams params(scale * translation, flutter::DlSize(100, 50), stack);

  FlutterPlatformViewLayer* layer =
      flutter::GetPlatformViewLayerFromEmbeddedViewParams(7, params, 3);

  XCTAssertEqual(layer.viewId, 7);
  // Verify the bounding rect is the view's rect in physical pixels once transformed.
  XCTAssertTrue(CGRectEqualToRect(layer.boundingRect, CGRectMake(30, 60, 300, 150)));
  // Verify the size is the view's size in points scaled by the device pixel ratio.
  XCTAssertTrue(CGSizeEqualToSize(layer.size, CGSizeMake(300, 150)));
}

- (void)testClipsThatCoverTheViewAreOmitted {
  // A 100x100 point view at the origin has a 200x200 pixel bounding rect.
  flutter::DlMatrix scale = flutter::DlMatrix::MakeScale({2, 2, 1});
  flutter::MutatorsStack stack;
  stack.PushTransform(scale);
  // These clips cover the view.
  stack.PushClipRect(flutter::DlRect::MakeLTRB(0, 0, 100, 100));
  stack.PushClipRRect(
      flutter::DlRoundRect::MakeRectXY(flutter::DlRect::MakeLTRB(-50, -50, 150, 150), 5, 5));
  stack.PushClipRSE(flutter::DlRoundSuperellipse::MakeRectXY(
      flutter::DlRect::MakeLTRB(-50, -50, 150, 150), 5, 5));
  // These clips do not.
  stack.PushClipRect(flutter::DlRect::MakeLTRB(10, 10, 100, 100));
  stack.PushClipRRect(
      flutter::DlRoundRect::MakeRectXY(flutter::DlRect::MakeLTRB(0, 0, 100, 100), 20, 20));
  stack.PushClipRSE(
      flutter::DlRoundSuperellipse::MakeRectXY(flutter::DlRect::MakeLTRB(0, 0, 100, 100), 20, 20));
  flutter::EmbeddedViewParams params(scale, flutter::DlSize(100, 100), stack);

  FlutterPlatformViewLayer* layer =
      flutter::GetPlatformViewLayerFromEmbeddedViewParams(1, params, 2);

  FlutterPlatformViewCornerRadii radii = {
      .topLeft = CGSizeMake(20, 20),
      .topRight = CGSizeMake(20, 20),
      .bottomRight = CGSizeMake(20, 20),
      .bottomLeft = CGSizeMake(20, 20),
  };
  NSArray<FlutterPlatformViewMutator*>* expected = @[
    [FlutterPlatformViewMutator mutatorWithTransform:CATransform3DMakeScale(2, 2, 1)],
    [FlutterPlatformViewMutator mutatorWithClipRect:CGRectMake(10, 10, 90, 90)],
    [FlutterPlatformViewMutator mutatorWithClipRoundedRect:CGRectMake(0, 0, 100, 100) radii:radii],
    [FlutterPlatformViewMutator mutatorWithClipRoundedSuperellipse:CGRectMake(0, 0, 100, 100)
                                                             radii:radii],
  ];
  XCTAssertEqualObjects(layer.mutators, expected);
}

- (void)testClipPathIsConverted {
  flutter::MutatorsStack stack;
  stack.PushClipPath(flutter::DlPath::MakeRect(flutter::DlRect::MakeLTRB(10, 20, 60, 80)));
  flutter::EmbeddedViewParams params(flutter::DlMatrix(), flutter::DlSize(100, 100), stack);

  FlutterPlatformViewLayer* layer =
      flutter::GetPlatformViewLayerFromEmbeddedViewParams(1, params, 1);

  XCTAssertEqual(layer.mutators.count, 1u);
  FlutterPlatformViewMutator* mutator = layer.mutators[0];
  XCTAssertEqual(mutator.type, FlutterPlatformViewMutatorTypeClipPath);
  XCTAssertTrue(CGRectEqualToRect(CGPathGetBoundingBox(mutator.path), CGRectMake(10, 20, 50, 60)));
}

- (void)testBackdropMutatorsFollowTheMutatorsFromPreroll {
  flutter::DlMatrix scale = flutter::DlMatrix::MakeScale({2, 2, 1});
  flutter::MutatorsStack stack;
  stack.PushTransform(scale);
  flutter::EmbeddedViewParams params(scale, flutter::DlSize(100, 100), stack);
  // Backdrop filters and backdrop clips are appended to the params after preroll.
  params.PushPlatformViewClipRect(flutter::DlRect::MakeLTRB(0, 0, 200, 200));
  params.PushPlatformViewClipRRect(
      flutter::DlRoundRect::MakeRectXY(flutter::DlRect::MakeLTRB(0, 0, 200, 200), 8, 8));
  params.PushPlatformViewClipRSuperellipse(
      flutter::DlRoundSuperellipse::MakeRectXY(flutter::DlRect::MakeLTRB(0, 0, 200, 200), 12, 12));
  params.PushImageFilter(flutter::DlBlurImageFilter::Make(4, 6, flutter::DlTileMode::kClamp),
                         flutter::DlRect::MakeLTRB(0, 0, 150, 150));

  FlutterPlatformViewLayer* layer =
      flutter::GetPlatformViewLayerFromEmbeddedViewParams(1, params, 2);

  FlutterPlatformViewCornerRadii rrectRadii = {
      .topLeft = CGSizeMake(8, 8),
      .topRight = CGSizeMake(8, 8),
      .bottomRight = CGSizeMake(8, 8),
      .bottomLeft = CGSizeMake(8, 8),
  };
  FlutterPlatformViewCornerRadii rseRadii = {
      .topLeft = CGSizeMake(12, 12),
      .topRight = CGSizeMake(12, 12),
      .bottomRight = CGSizeMake(12, 12),
      .bottomLeft = CGSizeMake(12, 12),
  };
  NSArray<FlutterPlatformViewMutator*>* expected = @[
    [FlutterPlatformViewMutator mutatorWithTransform:CATransform3DMakeScale(2, 2, 1)],
    [FlutterPlatformViewMutator mutatorWithBackdropClipRect:CGRectMake(0, 0, 200, 200)],
    [FlutterPlatformViewMutator mutatorWithBackdropClipRoundedRect:CGRectMake(0, 0, 200, 200)
                                                             radii:rrectRadii],
    [FlutterPlatformViewMutator
        mutatorWithBackdropClipRoundedSuperellipse:CGRectMake(0, 0, 200, 200)
                                             radii:rseRadii],
    [FlutterPlatformViewMutator mutatorWithBackdropFilterRect:CGRectMake(0, 0, 150, 150)
                                                   blurSigmaX:4
                                                   blurSigmaY:6],
  ];
  XCTAssertEqualObjects(layer.mutators, expected);
}

- (void)testBackdropFiltersOtherThanBlursAreOmitted {
  flutter::MutatorsStack stack;
  flutter::EmbeddedViewParams params(flutter::DlMatrix(), flutter::DlSize(100, 100), stack);
  params.PushImageFilter(flutter::DlDilateImageFilter::Make(2, 2),
                         flutter::DlRect::MakeLTRB(0, 0, 100, 100));

  FlutterPlatformViewLayer* layer =
      flutter::GetPlatformViewLayerFromEmbeddedViewParams(1, params, 1);

  XCTAssertEqual(layer.mutators.count, 0u);
}

- (void)testLayersAreEqualIfTheirParamsAreEqual {
  auto makeLayer = [](flutter::DlScalar offset) {
    flutter::DlMatrix translation = flutter::DlMatrix::MakeTranslation({offset, 0});
    flutter::MutatorsStack stack;
    stack.PushTransform(translation);
    stack.PushClipPath(flutter::DlPath::MakeRect(flutter::DlRect::MakeLTRB(0, 0, 50, 50)));
    flutter::EmbeddedViewParams params(translation, flutter::DlSize(100, 100), stack);
    params.PushImageFilter(flutter::DlBlurImageFilter::Make(4, 4, flutter::DlTileMode::kClamp),
                           flutter::DlRect::MakeLTRB(0, 0, 150, 150));
    return flutter::GetPlatformViewLayerFromEmbeddedViewParams(1, params, 1);
  };

  XCTAssertEqualObjects(makeLayer(10), makeLayer(10));
  XCTAssertNotEqualObjects(makeLayer(10), makeLayer(11));
}

@end
