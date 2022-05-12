// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_attributes_testing.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/types.h"
#include "gtest/gtest.h"
#include "include/core/SkPath.h"
#include "include/core/SkScalar.h"

namespace flutter {
namespace testing {

TEST(DisplayListPathEffect, BuilderSetGet) {
  const SkScalar TestDashes1[] = {4.0, 2.0};
  auto dash_path_effect = DlDashPathEffect::Make(TestDashes1, 2, 0.0);
  DisplayListBuilder builder;
  ASSERT_EQ(builder.getPathEffect(), nullptr);
  builder.setPathEffect(dash_path_effect.get());
  ASSERT_NE(builder.getPathEffect(), nullptr);
  ASSERT_TRUE(Equals(builder.getPathEffect(),
                     static_cast<DlPathEffect*>(dash_path_effect.get())));
  builder.setPathEffect(nullptr);
  ASSERT_EQ(builder.getPathEffect(), nullptr);
}

TEST(DisplayListPathEffect, FromSkiaNullPathEffect) {
  std::shared_ptr<DlPathEffect> path_effect = DlPathEffect::From(nullptr);
  ASSERT_EQ(path_effect, nullptr);
  ASSERT_EQ(path_effect.get(), nullptr);
}

TEST(DisplayListPathEffect, FromSkiaPathEffect) {
  const SkScalar TestDashes2[] = {1.0, 1.5};
  sk_sp<SkPathEffect> sk_path_effect =
      SkDashPathEffect::Make(TestDashes2, 2, 0.0);
  std::shared_ptr<DlPathEffect> dl_path_effect =
      DlPathEffect::From(sk_path_effect);

  ASSERT_EQ(dl_path_effect->type(), DlPathEffectType::kDash);
  ASSERT_TRUE(
      Equals(dl_path_effect, DlDashPathEffect::Make(TestDashes2, 2, 0.0)));
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
  const SkScalar TestDashes1[] = {4.0, 2.0};
  const SkScalar TestDashes2[] = {5.0, 2.0};
  const SkScalar TestDashes3[] = {4.0, 3.0};
  const SkScalar TestDashes4[] = {4.0, 2.0, 6.0};
  auto effect1 = DlDashPathEffect::Make(TestDashes1, 2, 0.0);
  auto effect2 = DlDashPathEffect::Make(TestDashes2, 2, 0.0);
  auto effect3 = DlDashPathEffect::Make(TestDashes3, 2, 0.0);
  auto effect4 = DlDashPathEffect::Make(TestDashes4, 3, 0.0);
  auto effect5 = DlDashPathEffect::Make(TestDashes1, 2, 1.0);

  TestNotEquals(*effect1, *effect2, "Interval 1 differs");
  TestNotEquals(*effect1, *effect3, "Interval 2 differs");
  TestNotEquals(*effect1, *effect4, "Dash count differs");
  TestNotEquals(*effect1, *effect5, "Dash phase differs");
}

TEST(DisplayListPathEffect, UnknownConstructor) {
  const SkScalar TestDashes1[] = {4.0, 2.0};
  DlUnknownPathEffect path_effect(SkDashPathEffect::Make(TestDashes1, 2, 0.0));
}

TEST(DisplayListPathEffect, UnknownShared) {
  const SkScalar TestDashes1[] = {4.0, 2.0};
  DlUnknownPathEffect path_effect(SkDashPathEffect::Make(TestDashes1, 2, 0.0));
  ASSERT_NE(path_effect.shared().get(), &path_effect);
  ASSERT_EQ(*path_effect.shared(), path_effect);
}

TEST(DisplayListPathEffect, UnknownContents) {
  const SkScalar TestDashes1[] = {4.0, 2.0};
  sk_sp<SkPathEffect> sk_effect = SkDashPathEffect::Make(TestDashes1, 2, 0.0);
  DlUnknownPathEffect effect(sk_effect);
  ASSERT_EQ(effect.skia_object(), sk_effect);
  ASSERT_EQ(effect.skia_object().get(), sk_effect.get());
}

TEST(DisplayListPathEffect, UnknownEquals) {
  const SkScalar TestDashes1[] = {4.0, 2.0};
  sk_sp<SkPathEffect> sk_effect = SkDashPathEffect::Make(TestDashes1, 2, 0.0);
  DlUnknownPathEffect effect1(sk_effect);
  DlUnknownPathEffect effect2(sk_effect);
  TestEquals(effect1, effect1);
}

TEST(DisplayListPathEffect, UnknownNotEquals) {
  const SkScalar TestDashes1[] = {4.0, 2.0};
  // Even though the effect is the same, it is a different instance
  // and we cannot currently tell them apart because the Skia
  // DashEffect::Make objects do not implement ==
  DlUnknownPathEffect path_effect1(SkDashPathEffect::Make(TestDashes1, 2, 0.0));
  DlUnknownPathEffect path_effect2(SkDashPathEffect::Make(TestDashes1, 2, 0.0));
  TestNotEquals(path_effect1, path_effect2,
                "SkDashPathEffect instance differs");
}

}  // namespace testing
}  // namespace flutter
