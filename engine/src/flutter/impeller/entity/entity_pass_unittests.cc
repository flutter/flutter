// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass_clip_stack.h"

namespace impeller {
namespace testing {

TEST(EntityPassClipStackTest, CanPushAndPopEntities) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  EXPECT_TRUE(recorder.GetReplayEntities().empty());

  Entity entity;
  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kAppend,
                        Rect::MakeLTRB(0, 0, 100, 100));
  EXPECT_EQ(recorder.GetReplayEntities().size(), 1u);

  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kAppend,
                        Rect::MakeLTRB(0, 0, 50, 50));
  EXPECT_EQ(recorder.GetReplayEntities().size(), 2u);
  ASSERT_TRUE(recorder.GetReplayEntities()[0].clip_coverage.has_value());
  ASSERT_TRUE(recorder.GetReplayEntities()[1].clip_coverage.has_value());
  // NOLINTBEGIN(bugprone-unchecked-optional-access)
  EXPECT_EQ(recorder.GetReplayEntities()[0].clip_coverage.value(),
            Rect::MakeLTRB(0, 0, 100, 100));
  EXPECT_EQ(recorder.GetReplayEntities()[1].clip_coverage.value(),
            Rect::MakeLTRB(0, 0, 50, 50));
  // NOLINTEND(bugprone-unchecked-optional-access)

  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kRestore, Rect());
  EXPECT_EQ(recorder.GetReplayEntities().size(), 1u);

  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kRestore, Rect());
  EXPECT_TRUE(recorder.GetReplayEntities().empty());
}

TEST(EntityPassClipStackTest, CanPopEntitiesSafely) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  EXPECT_TRUE(recorder.GetReplayEntities().empty());

  Entity entity;
  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kRestore, Rect());
  EXPECT_TRUE(recorder.GetReplayEntities().empty());
}

TEST(EntityPassClipStackTest, CanAppendNoChange) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  EXPECT_TRUE(recorder.GetReplayEntities().empty());

  Entity entity;
  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kNoChange,
                        Rect());
  EXPECT_TRUE(recorder.GetReplayEntities().empty());
}

TEST(EntityPassClipStackTest, AppendCoverageNoChange) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].coverage,
            Rect::MakeSize(Size::MakeWH(100, 100)));
  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].clip_height, 0u);

  Entity entity;
  EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kNoChange,
          .coverage = std::nullopt,
      },
      entity, 0, Point(0, 0));
  EXPECT_TRUE(result.should_render);
  EXPECT_FALSE(result.clip_did_change);

  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].coverage,
            Rect::MakeSize(Size::MakeWH(100, 100)));
  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].clip_height, 0u);
}

TEST(EntityPassClipStackTest, AppendAndRestoreClipCoverage) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);

  // Push a clip.
  Entity entity;
  EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kAppend,
          .coverage = Rect::MakeLTRB(50, 50, 55, 55),
      },
      entity, 0, Point(0, 0));
  EXPECT_TRUE(result.should_render);
  EXPECT_TRUE(result.clip_did_change);

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 2u);
  EXPECT_EQ(recorder.GetClipCoverageLayers()[1].coverage,
            Rect::MakeLTRB(50, 50, 55, 55));
  EXPECT_EQ(recorder.GetClipCoverageLayers()[1].clip_height, 1u);
  EXPECT_EQ(recorder.GetReplayEntities().size(), 1u);

  // Restore the clip.
  auto restore_clip = std::make_shared<ClipRestoreContents>();
  restore_clip->SetRestoreHeight(0);
  entity.SetContents(std::move(restore_clip));
  recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kRestore,
          .coverage = Rect::MakeLTRB(50, 50, 55, 55),
      },
      entity, 0, Point(0, 0));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);
  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].coverage,
            Rect::MakeSize(Size::MakeWH(100, 100)));
  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].clip_height, 0u);
  EXPECT_EQ(recorder.GetReplayEntities().size(), 0u);
}

// Append two clip coverages, the second is larger the first. This
// should result in the second clip not requiring any update.
TEST(EntityPassClipStackTest, AppendLargerClipCoverage) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);

  // Push a clip.
  Entity entity;
  EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kAppend,
          .coverage = Rect::MakeLTRB(50, 50, 55, 55),
      },
      entity, 0, Point(0, 0));
  EXPECT_TRUE(result.should_render);
  EXPECT_TRUE(result.clip_did_change);

  // Push a clip with larger coverage than the previous state.
  result = recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kAppend,
          .coverage = Rect::MakeLTRB(0, 0, 100, 100),
      },
      entity, 0, Point(0, 0));

  EXPECT_FALSE(result.should_render);
  EXPECT_FALSE(result.clip_did_change);
}

// Since clip entities return the outer coverage we can only cull axis aligned
// rectangles and intersect clips.
TEST(EntityPassClipStackTest,
     AppendLargerClipCoverageWithDifferenceOrNonSquare) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);

  // Push a clip.
  Entity entity;
  EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kAppend,
          .coverage = Rect::MakeLTRB(50, 50, 55, 55),
      },
      entity, 0, Point(0, 0));
  EXPECT_TRUE(result.should_render);
  EXPECT_TRUE(result.clip_did_change);

  // Push a clip with larger coverage than the previous state.
  result = recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kAppend,
          .is_difference_or_non_square = true,
          .coverage = Rect::MakeLTRB(0, 0, 100, 100),
      },
      entity, 0, Point(0, 0));

  EXPECT_TRUE(result.should_render);
  EXPECT_TRUE(result.clip_did_change);
}

TEST(EntityPassClipStackTest, AppendDecreasingSizeClipCoverage) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);

  // Push Clips that shrink in size. All should be applied.
  Entity entity;

  for (auto i = 1; i < 20; i++) {
    EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
        Contents::ClipCoverage{
            .type = Contents::ClipCoverage::Type::kAppend,
            .coverage = Rect::MakeLTRB(i, i, 100 - i, 100 - i),
        },
        entity, 0, Point(0, 0));
    EXPECT_TRUE(result.should_render);
    EXPECT_TRUE(result.clip_did_change);
    EXPECT_EQ(recorder.CurrentClipCoverage(),
              Rect::MakeLTRB(i, i, 100 - i, 100 - i));
  }
}

TEST(EntityPassClipStackTest, AppendIncreasingSizeClipCoverage) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);

  // Push Clips that grow in size. All should be skipped.
  Entity entity;

  for (auto i = 1; i < 20; i++) {
    EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
        Contents::ClipCoverage{
            .type = Contents::ClipCoverage::Type::kAppend,
            .coverage = Rect::MakeLTRB(0 - i, 0 - i, 100 + i, 100 + i),
        },
        entity, 0, Point(0, 0));
    EXPECT_FALSE(result.should_render);
    EXPECT_FALSE(result.clip_did_change);
    EXPECT_EQ(recorder.CurrentClipCoverage(), Rect::MakeLTRB(0, 0, 100, 100));
  }
}

TEST(EntityPassClipStackTest, UnbalancedRestore) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);

  // Restore the clip.
  Entity entity;
  auto restore_clip = std::make_shared<ClipRestoreContents>();
  restore_clip->SetRestoreHeight(0);
  entity.SetContents(std::move(restore_clip));
  EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
      Contents::ClipCoverage{
          .type = Contents::ClipCoverage::Type::kRestore,
          .coverage = Rect::MakeLTRB(50, 50, 55, 55),
      },
      entity, 0, Point(0, 0));
  EXPECT_FALSE(result.should_render);
  EXPECT_FALSE(result.clip_did_change);

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);
  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].coverage,
            Rect::MakeSize(Size::MakeWH(100, 100)));
  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].clip_height, 0u);
  EXPECT_EQ(recorder.GetReplayEntities().size(), 0u);
}

TEST(EntityPassClipStackTest, ClipAndRestoreWithSubpasses) {
  EntityPassClipStack recorder =
      EntityPassClipStack(Rect::MakeLTRB(0, 0, 100, 100));

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);

  // Push a clip.
  Entity entity;
  {
    EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
        Contents::ClipCoverage{
            .type = Contents::ClipCoverage::Type::kAppend,
            .coverage = Rect::MakeLTRB(50, 50, 55, 55),
        },
        entity, 0, Point(0, 0));
    EXPECT_TRUE(result.should_render);
    EXPECT_TRUE(result.clip_did_change);
  }

  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 2u);
  EXPECT_EQ(recorder.GetClipCoverageLayers()[1].coverage,
            Rect::MakeLTRB(50, 50, 55, 55));
  EXPECT_EQ(recorder.GetClipCoverageLayers()[1].clip_height, 1u);
  EXPECT_EQ(recorder.GetReplayEntities().size(), 1u);

  // Begin a subpass.
  recorder.PushSubpass(Rect::MakeLTRB(50, 50, 55, 55), 1);
  ASSERT_EQ(recorder.GetClipCoverageLayers().size(), 1u);
  EXPECT_EQ(recorder.GetClipCoverageLayers()[0].coverage,
            Rect::MakeLTRB(50, 50, 55, 55));

  {
    EntityPassClipStack::ClipStateResult result = recorder.ApplyClipState(
        Contents::ClipCoverage{
            .type = Contents::ClipCoverage::Type::kAppend,
            .coverage = Rect::MakeLTRB(54, 54, 55, 55),
        },
        entity, 0, Point(0, 0));
    EXPECT_TRUE(result.should_render);
    EXPECT_TRUE(result.clip_did_change);
  }

  EXPECT_EQ(recorder.GetClipCoverageLayers()[1].coverage,
            Rect::MakeLTRB(54, 54, 55, 55));

  // End subpass.
  recorder.PopSubpass();

  EXPECT_EQ(recorder.GetClipCoverageLayers()[1].coverage,
            Rect::MakeLTRB(50, 50, 55, 55));
}

}  // namespace testing
}  // namespace impeller
