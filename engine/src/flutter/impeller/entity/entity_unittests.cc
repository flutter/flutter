// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/playground/playground.h"

namespace impeller {
namespace testing {

using EntityTest = EntityPlayground;

TEST_F(EntityTest, CanCreateEntity) {
  Entity entity;
  ASSERT_TRUE(entity.GetTransformation().IsIdentity());
}

TEST_F(EntityTest, CanDrawRect) {
  Entity entity;
  entity.SetPath(PathBuilder{}.AddRect({100, 100, 100, 100}).CreatePath());
  entity.SetContents(SolidColorContents::Make(Color::Red()));
  // ASSERT_TRUE(OpenPlaygroundHere(entity));
}

}  // namespace testing
}  // namespace impeller
