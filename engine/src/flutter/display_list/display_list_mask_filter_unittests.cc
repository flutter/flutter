// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/display_list_mask_filter.h"
#include "flutter/display_list/testing/dl_test_equality.h"
#include "flutter/display_list/types.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(DisplayListMaskFilter, BuilderSetGet) {
  DlBlurMaskFilter filter(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  DisplayListBuilder builder;
  ASSERT_EQ(builder.getMaskFilter(), nullptr);
  builder.setMaskFilter(&filter);
  ASSERT_NE(builder.getMaskFilter(), nullptr);
  ASSERT_TRUE(
      Equals(builder.getMaskFilter(), static_cast<DlMaskFilter*>(&filter)));
  builder.setMaskFilter(nullptr);
  ASSERT_EQ(builder.getMaskFilter(), nullptr);
}

TEST(DisplayListMaskFilter, FromSkiaNullFilter) {
  std::shared_ptr<DlMaskFilter> filter = DlMaskFilter::From(nullptr);
  ASSERT_EQ(filter, nullptr);
  ASSERT_EQ(filter.get(), nullptr);
}

TEST(DisplayListMaskFilter, FromSkiaBlurFilter) {
  sk_sp<SkMaskFilter> sk_filter =
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  std::shared_ptr<DlMaskFilter> filter = DlMaskFilter::From(sk_filter);
  ASSERT_EQ(filter->type(), DlMaskFilterType::kUnknown);
  // We cannot recapture the blur parameters from an SkBlurMaskFilter
  ASSERT_EQ(filter->asBlur(), nullptr);
  ASSERT_EQ(filter->skia_object(), sk_filter);
}

TEST(DisplayListMaskFilter, BlurConstructor) {
  DlBlurMaskFilter filter(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
}

TEST(DisplayListMaskFilter, BlurShared) {
  DlBlurMaskFilter filter(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListMaskFilter, BlurAsBlur) {
  DlBlurMaskFilter filter(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  ASSERT_NE(filter.asBlur(), nullptr);
  ASSERT_EQ(filter.asBlur(), &filter);
}

TEST(DisplayListMaskFilter, BlurContents) {
  DlBlurMaskFilter filter(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  ASSERT_EQ(filter.style(), SkBlurStyle::kNormal_SkBlurStyle);
  ASSERT_EQ(filter.sigma(), 5.0);
}

TEST(DisplayListMaskFilter, BlurEquals) {
  DlBlurMaskFilter filter1(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  DlBlurMaskFilter filter2(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  TestEquals(filter1, filter2);
}

TEST(DisplayListMaskFilter, BlurNotEquals) {
  DlBlurMaskFilter filter1(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  DlBlurMaskFilter filter2(SkBlurStyle::kInner_SkBlurStyle, 5.0);
  DlBlurMaskFilter filter3(SkBlurStyle::kNormal_SkBlurStyle, 6.0);
  TestNotEquals(filter1, filter2, "Blur style differs");
  TestNotEquals(filter1, filter3, "blur radius differs");
}

TEST(DisplayListMaskFilter, UnknownConstructor) {
  DlUnknownMaskFilter filter(
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 5.0));
}

TEST(DisplayListMaskFilter, UnknownShared) {
  DlUnknownMaskFilter filter(
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 5.0));
  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListMaskFilter, UnknownContents) {
  sk_sp<SkMaskFilter> sk_filter =
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  DlUnknownMaskFilter filter(sk_filter);
  ASSERT_EQ(filter.skia_object(), sk_filter);
  ASSERT_EQ(filter.skia_object().get(), sk_filter.get());
}

TEST(DisplayListMaskFilter, UnknownEquals) {
  sk_sp<SkMaskFilter> sk_filter =
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  DlUnknownMaskFilter filter1(sk_filter);
  DlUnknownMaskFilter filter2(sk_filter);
  TestEquals(filter1, filter2);
}

TEST(DisplayListMaskFilter, UnknownNotEquals) {
  // Even though the filter is the same, it is a different instance
  // and we cannot currently tell them apart because the Skia
  // MaskFilter objects do not implement ==
  DlUnknownMaskFilter filter1(
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 5.0));
  DlUnknownMaskFilter filter2(
      SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 5.0));
  TestNotEquals(filter1, filter2, "SkMaskFilter instance differs");
}

void testEquals(DlMaskFilter* a, DlMaskFilter* b) {
  // a and b have the same nullness or values
  ASSERT_TRUE(Equals(a, b));
  ASSERT_FALSE(NotEquals(a, b));
  ASSERT_TRUE(Equals(b, a));
  ASSERT_FALSE(NotEquals(b, a));
}

void testNotEquals(DlMaskFilter* a, DlMaskFilter* b) {
  // a and b do not have the same nullness or values
  ASSERT_FALSE(Equals(a, b));
  ASSERT_TRUE(NotEquals(a, b));
  ASSERT_FALSE(Equals(b, a));
  ASSERT_TRUE(NotEquals(b, a));
}

void testEquals(const std::shared_ptr<const DlMaskFilter>& a, DlMaskFilter* b) {
  // a and b have the same nullness or values
  ASSERT_TRUE(Equals(a, b));
  ASSERT_FALSE(NotEquals(a, b));
  ASSERT_TRUE(Equals(b, a));
  ASSERT_FALSE(NotEquals(b, a));
}

void testNotEquals(const std::shared_ptr<const DlMaskFilter>& a,
                   DlMaskFilter* b) {
  // a and b do not have the same nullness or values
  ASSERT_FALSE(Equals(a, b));
  ASSERT_TRUE(NotEquals(a, b));
  ASSERT_FALSE(Equals(b, a));
  ASSERT_TRUE(NotEquals(b, a));
}

void testEquals(const std::shared_ptr<const DlMaskFilter>& a,
                const std::shared_ptr<const DlMaskFilter>& b) {
  // a and b have the same nullness or values
  ASSERT_TRUE(Equals(a, b));
  ASSERT_FALSE(NotEquals(a, b));
  ASSERT_TRUE(Equals(b, a));
  ASSERT_FALSE(NotEquals(b, a));
}

void testNotEquals(const std::shared_ptr<const DlMaskFilter>& a,
                   const std::shared_ptr<const DlMaskFilter>& b) {
  // a and b do not have the same nullness or values
  ASSERT_FALSE(Equals(a, b));
  ASSERT_TRUE(NotEquals(a, b));
  ASSERT_FALSE(Equals(b, a));
  ASSERT_TRUE(NotEquals(b, a));
}

TEST(DisplayListMaskFilter, ComparableTemplates) {
  DlBlurMaskFilter filter1a(SkBlurStyle::kNormal_SkBlurStyle, 3.0);
  DlBlurMaskFilter filter1b(SkBlurStyle::kNormal_SkBlurStyle, 3.0);
  DlBlurMaskFilter filter2(SkBlurStyle::kNormal_SkBlurStyle, 5.0);
  std::shared_ptr<DlMaskFilter> shared_null;

  // null to null
  testEquals(nullptr, nullptr);
  testEquals(shared_null, nullptr);
  testEquals(shared_null, shared_null);

  // ptr to null
  testNotEquals(&filter1a, nullptr);
  testNotEquals(&filter1b, nullptr);
  testNotEquals(&filter2, nullptr);

  // shared_ptr to null and shared_null to ptr
  testNotEquals(filter1a.shared(), nullptr);
  testNotEquals(filter1b.shared(), nullptr);
  testNotEquals(filter2.shared(), nullptr);
  testNotEquals(shared_null, &filter1a);
  testNotEquals(shared_null, &filter1b);
  testNotEquals(shared_null, &filter2);

  // ptr to ptr
  testEquals(&filter1a, &filter1a);
  testEquals(&filter1a, &filter1b);
  testEquals(&filter1b, &filter1b);
  testEquals(&filter2, &filter2);
  testNotEquals(&filter1a, &filter2);

  // shared_ptr to ptr
  testEquals(filter1a.shared(), &filter1a);
  testEquals(filter1a.shared(), &filter1b);
  testEquals(filter1b.shared(), &filter1b);
  testEquals(filter2.shared(), &filter2);
  testNotEquals(filter1a.shared(), &filter2);
  testNotEquals(filter1b.shared(), &filter2);
  testNotEquals(filter2.shared(), &filter1a);
  testNotEquals(filter2.shared(), &filter1b);

  // shared_ptr to shared_ptr
  testEquals(filter1a.shared(), filter1a.shared());
  testEquals(filter1a.shared(), filter1b.shared());
  testEquals(filter1b.shared(), filter1b.shared());
  testEquals(filter2.shared(), filter2.shared());
  testNotEquals(filter1a.shared(), filter2.shared());
  testNotEquals(filter1b.shared(), filter2.shared());
  testNotEquals(filter2.shared(), filter1a.shared());
  testNotEquals(filter2.shared(), filter1b.shared());
}

}  // namespace testing
}  // namespace flutter
