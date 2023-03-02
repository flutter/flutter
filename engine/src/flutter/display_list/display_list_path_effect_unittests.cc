// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/testing/dl_test_equality.h"
#include "flutter/display_list/types.h"
#include "gtest/gtest.h"
#include "include/core/SkPath.h"
#include "include/core/SkScalar.h"

namespace flutter {
namespace testing {

TEST(DisplayListPathEffect, BuilderSetGet) {
  const SkScalar test_dashes[] = {4.0, 2.0};
  auto dash_path_effect = DlDashPathEffect::Make(test_dashes, 2, 0.0);
  DisplayListBuilder builder;
  ASSERT_EQ(builder.getPathEffect(), nullptr);
  builder.setPathEffect(dash_path_effect.get());
  ASSERT_NE(builder.getPathEffect(), nullptr);
  ASSERT_TRUE(Equals(builder.getPathEffect(),
                     static_cast<DlPathEffect*>(dash_path_effect.get())));
  builder.setPathEffect(nullptr);
  ASSERT_EQ(builder.getPathEffect(), nullptr);
}

TEST(DisplayListPathEffect, EffectShared) {
  const SkScalar TestDashes2[] = {1.0, 1.5};
  auto effect = DlDashPathEffect::Make(TestDashes2, 2, 0.0);
  ASSERT_TRUE(Equals(effect->shared(), effect));
}

TEST(DisplayListPathEffect, DashEffectAsDash) {
  const SkScalar TestDashes2[] = {1.0, 1.5};
  auto effect = DlDashPathEffect::Make(TestDashes2, 2, 0.0);
  ASSERT_NE(effect->asDash(), nullptr);
  ASSERT_EQ(effect->asDash(), effect.get());
}

TEST(DisplayListPathEffect, DashEffectEquals) {
  const SkScalar TestDashes2[] = {1.0, 1.5};
  auto effect1 = DlDashPathEffect::Make(TestDashes2, 2, 0.0);
  auto effect2 = DlDashPathEffect::Make(TestDashes2, 2, 0.0);
  TestEquals(*effect1, *effect1);
}

TEST(DisplayListPathEffect, CheckEffectProperties) {
  const SkScalar test_dashes[] = {4.0, 2.0};
  const SkScalar TestDashes2[] = {5.0, 2.0};
  const SkScalar TestDashes3[] = {4.0, 3.0};
  const SkScalar TestDashes4[] = {4.0, 2.0, 6.0};
  auto effect1 = DlDashPathEffect::Make(test_dashes, 2, 0.0);
  auto effect2 = DlDashPathEffect::Make(TestDashes2, 2, 0.0);
  auto effect3 = DlDashPathEffect::Make(TestDashes3, 2, 0.0);
  auto effect4 = DlDashPathEffect::Make(TestDashes4, 3, 0.0);
  auto effect5 = DlDashPathEffect::Make(test_dashes, 2, 1.0);

  TestNotEquals(*effect1, *effect2, "Interval 1 differs");
  TestNotEquals(*effect1, *effect3, "Interval 2 differs");
  TestNotEquals(*effect1, *effect4, "Dash count differs");
  TestNotEquals(*effect1, *effect5, "Dash phase differs");
}

}  // namespace testing
}  // namespace flutter
