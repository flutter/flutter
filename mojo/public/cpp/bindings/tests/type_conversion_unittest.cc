// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/interfaces/bindings/tests/test_structs.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

struct RedmondRect {
  int32_t left;
  int32_t top;
  int32_t right;
  int32_t bottom;
};

struct RedmondNamedRegion {
  std::string name;
  std::vector<RedmondRect> rects;
};

bool AreEqualRectArrays(const Array<test::RectPtr>& rects1,
                        const Array<test::RectPtr>& rects2) {
  if (rects1.size() != rects2.size())
    return false;

  for (size_t i = 0; i < rects1.size(); ++i) {
    if (rects1[i]->x != rects2[i]->x || rects1[i]->y != rects2[i]->y ||
        rects1[i]->width != rects2[i]->width ||
        rects1[i]->height != rects2[i]->height) {
      return false;
    }
  }

  return true;
}

}  // namespace

template <>
struct TypeConverter<test::RectPtr, RedmondRect> {
  static test::RectPtr Convert(const RedmondRect& input) {
    test::RectPtr rect(test::Rect::New());
    rect->x = input.left;
    rect->y = input.top;
    rect->width = input.right - input.left;
    rect->height = input.bottom - input.top;
    return rect.Pass();
  }
};

template <>
struct TypeConverter<RedmondRect, test::RectPtr> {
  static RedmondRect Convert(const test::RectPtr& input) {
    RedmondRect rect;
    rect.left = input->x;
    rect.top = input->y;
    rect.right = input->x + input->width;
    rect.bottom = input->y + input->height;
    return rect;
  }
};

template <>
struct TypeConverter<test::NamedRegionPtr, RedmondNamedRegion> {
  static test::NamedRegionPtr Convert(const RedmondNamedRegion& input) {
    test::NamedRegionPtr region(test::NamedRegion::New());
    region->name = input.name;
    region->rects = Array<test::RectPtr>::From(input.rects);
    return region.Pass();
  }
};

template <>
struct TypeConverter<RedmondNamedRegion, test::NamedRegionPtr> {
  static RedmondNamedRegion Convert(const test::NamedRegionPtr& input) {
    RedmondNamedRegion region;
    region.name = input->name;
    region.rects = input->rects.To<std::vector<RedmondRect>>();
    return region;
  }
};

namespace test {
namespace {

TEST(TypeConversionTest, String) {
  const char kText[6] = "hello";

  String a = std::string(kText);
  String b(kText);
  String c(static_cast<const char*>(kText));

  EXPECT_EQ(std::string(kText), a.To<std::string>());
  EXPECT_EQ(std::string(kText), b.To<std::string>());
  EXPECT_EQ(std::string(kText), c.To<std::string>());
}

TEST(TypeConversionTest, String_Null) {
  String a;
  EXPECT_TRUE(a.is_null());
  EXPECT_EQ(std::string(), a.To<std::string>());

  String b = String::From(static_cast<const char*>(nullptr));
  EXPECT_TRUE(b.is_null());
}

TEST(TypeConversionTest, String_Empty) {
  String a = "";
  EXPECT_EQ(std::string(), a.To<std::string>());

  String b = std::string();
  EXPECT_FALSE(b.is_null());
  EXPECT_EQ(std::string(), b.To<std::string>());
}

TEST(TypeConversionTest, StringWithEmbeddedNull) {
  const std::string kText("hel\0lo", 6);

  String a(kText);
  EXPECT_EQ(kText, a.To<std::string>());

  // Expect truncation:
  String b(kText.c_str());
  EXPECT_EQ(std::string("hel"), b.To<std::string>());
}

TEST(TypeConversionTest, CustomTypeConverter) {
  RectPtr rect(Rect::New());
  rect->x = 10;
  rect->y = 20;
  rect->width = 50;
  rect->height = 45;

  RedmondRect rr = rect.To<RedmondRect>();
  EXPECT_EQ(10, rr.left);
  EXPECT_EQ(20, rr.top);
  EXPECT_EQ(60, rr.right);
  EXPECT_EQ(65, rr.bottom);

  RectPtr rect2(Rect::From(rr));
  EXPECT_EQ(rect->x, rect2->x);
  EXPECT_EQ(rect->y, rect2->y);
  EXPECT_EQ(rect->width, rect2->width);
  EXPECT_EQ(rect->height, rect2->height);
}

TEST(TypeConversionTest, CustomTypeConverter_Array_Null) {
  Array<RectPtr> rects;

  std::vector<RedmondRect> redmond_rects = rects.To<std::vector<RedmondRect>>();

  EXPECT_TRUE(redmond_rects.empty());
}

TEST(TypeConversionTest, CustomTypeConverter_Array) {
  const RedmondRect kBase = {10, 20, 30, 40};

  Array<RectPtr> rects(10);
  for (size_t i = 0; i < rects.size(); ++i) {
    RedmondRect rr = kBase;
    rr.left += static_cast<int32_t>(i);
    rr.top += static_cast<int32_t>(i);
    rects[i] = Rect::From(rr);
  }

  std::vector<RedmondRect> redmond_rects = rects.To<std::vector<RedmondRect>>();

  Array<RectPtr> rects2 = Array<RectPtr>::From(redmond_rects);
  EXPECT_TRUE(AreEqualRectArrays(rects, rects2));
}

TEST(TypeConversionTest, CustomTypeConverter_Nested) {
  RedmondNamedRegion redmond_region;
  redmond_region.name = "foopy";

  const RedmondRect kBase = {10, 20, 30, 40};

  for (size_t i = 0; i < 10; ++i) {
    RedmondRect rect = kBase;
    rect.left += static_cast<int32_t>(i);
    rect.top += static_cast<int32_t>(i);
    redmond_region.rects.push_back(rect);
  }

  // Round-trip through generated struct and TypeConverter.

  NamedRegionPtr copy = NamedRegion::From(redmond_region);
  RedmondNamedRegion redmond_region2 = copy.To<RedmondNamedRegion>();

  EXPECT_EQ(redmond_region.name, redmond_region2.name);
  EXPECT_EQ(redmond_region.rects.size(), redmond_region2.rects.size());
  for (size_t i = 0; i < redmond_region.rects.size(); ++i) {
    EXPECT_EQ(redmond_region.rects[i].left, redmond_region2.rects[i].left);
    EXPECT_EQ(redmond_region.rects[i].top, redmond_region2.rects[i].top);
    EXPECT_EQ(redmond_region.rects[i].right, redmond_region2.rects[i].right);
    EXPECT_EQ(redmond_region.rects[i].bottom, redmond_region2.rects[i].bottom);
  }
}

}  // namespace
}  // namespace test
}  // namespace mojo
