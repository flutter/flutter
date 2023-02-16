// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMutatorView.h"

#include "third_party/googletest/googletest/include/gtest/gtest.h"

@interface FlutterMutatorView (Private)

@property(readonly, nonatomic, nonnull) NSMutableArray<NSView*>* pathClipViews;
@property(readonly, nonatomic, nullable) NSView* platformViewContainer;

@end

namespace {
void ApplyFlutterLayer(FlutterMutatorView* view,
                       FlutterSize size,
                       const std::vector<FlutterPlatformViewMutation>& mutations) {
  FlutterLayer layer;
  layer.struct_size = sizeof(FlutterLayer);
  layer.type = kFlutterLayerContentTypePlatformView;
  // Offset is ignored by mutator view, the bounding rect is determined by
  // width and transform.
  layer.offset = FlutterPoint{0, 0};
  layer.size = size;

  FlutterPlatformView flutterPlatformView;
  flutterPlatformView.struct_size = sizeof(FlutterPlatformView);
  flutterPlatformView.identifier = 0;

  std::vector<const FlutterPlatformViewMutation*> mutationPointers;
  for (auto& mutation : mutations) {
    mutationPointers.push_back(&mutation);
  }
  flutterPlatformView.mutations = mutationPointers.data();
  flutterPlatformView.mutations_count = mutationPointers.size();
  layer.platform_view = &flutterPlatformView;

  [view applyFlutterLayer:&layer];
}
}  // namespace

TEST(FlutterMutatorViewTest, BasicFrameIsCorrect) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];

  EXPECT_EQ(mutatorView.platformView, platformView);

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(100, 50, 30, 20)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 0ull);
  EXPECT_NE(mutatorView.platformViewContainer, nil);
}

TEST(FlutterMutatorViewTest, TransformedFrameIsCorrect) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];
  NSView* mutatorViewParent = [[NSView alloc] init];
  mutatorViewParent.wantsLayer = YES;
  mutatorViewParent.layer.contentsScale = 2.0;
  [mutatorViewParent addSubview:mutatorView];

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 2,
                  .scaleY = 2,
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1.5,
                  .transX = -7.5,
                  .scaleY = 1.5,
                  .transY = -5,
              },
      },
  };

  // PlatformView size form engine comes in physical pixels
  ApplyFlutterLayer(mutatorView, FlutterSize{30 * 2, 20 * 2}, mutations);
  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(92.5, 45, 45, 30)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
  EXPECT_TRUE(
      CATransform3DEqualToTransform(mutatorView.platformViewContainer.layer.sublayerTransform,
                                    CATransform3DMakeScale(1.5, 1.5, 1)));
}

TEST(FlutterMutatorViewTest, FrameWithLooseClipIsCorrect) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];

  EXPECT_EQ(mutatorView.platformView, platformView);

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeClipRect,
          .clip_rect = FlutterRect{80, 40, 200, 100},
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(100, 50, 30, 20)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
}

TEST(FlutterMutatorViewTest, FrameWithTightClipIsCorrect) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];

  EXPECT_EQ(mutatorView.platformView, platformView);

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeClipRect,
          .clip_rect = FlutterRect{80, 40, 200, 100},
      },
      {
          .type = kFlutterPlatformViewMutationTypeClipRect,
          .clip_rect = FlutterRect{110, 55, 120, 65},
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(110, 55, 10, 10)));
  EXPECT_TRUE(
      CGRectEqualToRect(mutatorView.subviews.firstObject.frame, CGRectMake(-10, -5, 30, 20)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
}

TEST(FlutterMutatorViewTest, FrameWithTightClipAndTransformIsCorrect) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];
  NSView* mutatorViewParent = [[NSView alloc] init];
  mutatorViewParent.wantsLayer = YES;
  mutatorViewParent.layer.contentsScale = 2.0;
  [mutatorViewParent addSubview:mutatorView];

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 2,
                  .scaleY = 2,
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeClipRect,
          .clip_rect = FlutterRect{80, 40, 200, 100},
      },
      {
          .type = kFlutterPlatformViewMutationTypeClipRect,
          .clip_rect = FlutterRect{110, 55, 120, 65},
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1.5,
                  .transX = -7.5,
                  .scaleY = 1.5,
                  .transY = -5,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30 * 2, 20 * 2}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(110, 55, 10, 10)));
  EXPECT_TRUE(
      CGRectEqualToRect(mutatorView.subviews.firstObject.frame, CGRectMake(-17.5, -10, 45, 30)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
}

// Rounded rectangle without hitting the corner
TEST(FlutterMutatorViewTest, RoundRectClipsToSimpleRectangle) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeClipRoundedRect,
          .clip_rounded_rect =
              FlutterRoundedRect{
                  .rect = FlutterRect{110, 30, 120, 90},
                  .upper_left_corner_radius = FlutterSize{10, 10},
                  .upper_right_corner_radius = FlutterSize{10, 10},
                  .lower_right_corner_radius = FlutterSize{10, 10},
                  .lower_left_corner_radius = FlutterSize{10, 10},
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(110, 50, 10, 20)));
  EXPECT_TRUE(
      CGRectEqualToRect(mutatorView.subviews.firstObject.frame, CGRectMake(-10, 0, 30, 20)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 0ul);
}

TEST(FlutterMutatorViewTest, RoundRectClipsToPath) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeClipRoundedRect,
          .clip_rounded_rect =
              FlutterRoundedRect{
                  .rect = FlutterRect{110, 60, 150, 150},
                  .upper_left_corner_radius = FlutterSize{10, 10},
                  .upper_right_corner_radius = FlutterSize{10, 10},
                  .lower_right_corner_radius = FlutterSize{10, 10},
                  .lower_left_corner_radius = FlutterSize{10, 10},
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(110, 60, 20, 10)));
  EXPECT_TRUE(
      CGRectEqualToRect(mutatorView.subviews.firstObject.frame, CGRectMake(-10, -10, 30, 20)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 1ul);
  EXPECT_TRUE(
      CATransform3DEqualToTransform(mutatorView.pathClipViews.firstObject.layer.mask.transform,
                                    CATransform3DMakeTranslation(-100, -50, 0)));
}

TEST(FlutterMutatorViewTest, PathClipViewsAreAddedAndRemoved) {
  NSView* platformView = [[NSView alloc] init];
  FlutterMutatorView* mutatorView = [[FlutterMutatorView alloc] initWithPlatformView:platformView];

  std::vector<FlutterPlatformViewMutation> mutations{
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(100, 50, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 0ull);

  std::vector<FlutterPlatformViewMutation> mutations2{
      {
          .type = kFlutterPlatformViewMutationTypeClipRoundedRect,
          .clip_rounded_rect =
              FlutterRoundedRect{
                  .rect = FlutterRect{110, 60, 150, 150},
                  .upper_left_corner_radius = FlutterSize{10, 10},
                  .upper_right_corner_radius = FlutterSize{10, 10},
                  .lower_right_corner_radius = FlutterSize{10, 10},
                  .lower_left_corner_radius = FlutterSize{10, 10},
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations2);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(110, 60, 20, 10)));
  EXPECT_TRUE(
      CGRectEqualToRect(mutatorView.subviews.firstObject.frame, CGRectMake(-10, -10, 30, 20)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 1ul);

  EXPECT_EQ(platformView.superview, mutatorView.platformViewContainer);
  EXPECT_EQ(mutatorView.platformViewContainer.superview, mutatorView.pathClipViews[0]);
  EXPECT_EQ(mutatorView.pathClipViews[0].superview, mutatorView);

  std::vector<FlutterPlatformViewMutation> mutations3{
      {
          .type = kFlutterPlatformViewMutationTypeClipRoundedRect,
          .clip_rounded_rect =
              FlutterRoundedRect{
                  .rect = FlutterRect{110, 55, 150, 150},
                  .upper_left_corner_radius = FlutterSize{10, 10},
                  .upper_right_corner_radius = FlutterSize{10, 10},
                  .lower_right_corner_radius = FlutterSize{10, 10},
                  .lower_left_corner_radius = FlutterSize{10, 10},
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeClipRoundedRect,
          .clip_rounded_rect =
              FlutterRoundedRect{
                  .rect = FlutterRect{30, 30, 120, 65},
                  .upper_left_corner_radius = FlutterSize{10, 10},
                  .upper_right_corner_radius = FlutterSize{10, 10},
                  .lower_right_corner_radius = FlutterSize{10, 10},
                  .lower_left_corner_radius = FlutterSize{10, 10},
              },
      },
      {
          .type = kFlutterPlatformViewMutationTypeTransformation,
          .transformation =
              FlutterTransformation{
                  .scaleX = 1,
                  .transX = 100,
                  .scaleY = 1,
                  .transY = 50,
              },
      },
  };

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations3);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(110, 55, 10, 10)));
  EXPECT_TRUE(
      CGRectEqualToRect(mutatorView.subviews.firstObject.frame, CGRectMake(-10, -5, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 2ul);

  EXPECT_EQ(platformView.superview, mutatorView.platformViewContainer);
  EXPECT_EQ(mutatorView.platformViewContainer.superview, mutatorView.pathClipViews[1]);
  EXPECT_EQ(mutatorView.pathClipViews[1].superview, mutatorView.pathClipViews[0]);
  EXPECT_EQ(mutatorView.pathClipViews[0].superview, mutatorView);

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations2);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(110, 60, 20, 10)));
  EXPECT_TRUE(
      CGRectEqualToRect(mutatorView.subviews.firstObject.frame, CGRectMake(-10, -10, 30, 20)));
  EXPECT_TRUE(CGRectEqualToRect(platformView.frame, CGRectMake(0, 0, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 1ul);

  EXPECT_EQ(platformView.superview, mutatorView.platformViewContainer);
  EXPECT_EQ(mutatorView.platformViewContainer.superview, mutatorView.pathClipViews[0]);
  EXPECT_EQ(mutatorView.pathClipViews[0].superview, mutatorView);

  ApplyFlutterLayer(mutatorView, FlutterSize{30, 20}, mutations);

  EXPECT_TRUE(CGRectEqualToRect(mutatorView.frame, CGRectMake(100, 50, 30, 20)));
  EXPECT_EQ(mutatorView.pathClipViews.count, 0ull);
}
