// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/entity/entity_pass.h"

namespace impeller {
namespace testing {

TEST(EntityPassClipRecorderTest, CanPushAndPopEntities) {
  EntityPassClipRecorder recorder = EntityPassClipRecorder();

  EXPECT_TRUE(recorder.GetReplayEntities().empty());

  Entity entity;
  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kAppend);
  EXPECT_EQ(recorder.GetReplayEntities().size(), 1u);

  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kAppend);
  EXPECT_EQ(recorder.GetReplayEntities().size(), 2u);

  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kRestore);
  EXPECT_EQ(recorder.GetReplayEntities().size(), 1u);

  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kRestore);
  EXPECT_TRUE(recorder.GetReplayEntities().empty());
}

TEST(EntityPassClipRecorderTest, CanPopEntitiesSafely) {
  EntityPassClipRecorder recorder = EntityPassClipRecorder();

  EXPECT_TRUE(recorder.GetReplayEntities().empty());

  Entity entity;
  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kRestore);
  EXPECT_TRUE(recorder.GetReplayEntities().empty());
}

TEST(EntityPassClipRecorderTest, CanAppendNoChange) {
  EntityPassClipRecorder recorder = EntityPassClipRecorder();

  EXPECT_TRUE(recorder.GetReplayEntities().empty());

  Entity entity;
  recorder.RecordEntity(entity, Contents::ClipCoverage::Type::kNoChange);
  EXPECT_TRUE(recorder.GetReplayEntities().empty());
}

}  // namespace testing
}  // namespace impeller
