// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_region.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "gtest/gtest.h"

#include "third_party/skia/include/core/SkRegion.h"

#include <random>

namespace flutter {
namespace testing {

TEST(DisplayListRegion, EmptyRegion) {
  DlRegion region;
  EXPECT_TRUE(region.isEmpty());
  EXPECT_TRUE(region.getRects().empty());
}

TEST(DisplayListRegion, SingleRectangle) {
  DlRegion region({DlIRect::MakeLTRB(10, 10, 50, 50)});
  auto rects = region.getRects();
  ASSERT_EQ(rects.size(), 1u);
  EXPECT_EQ(rects.front(), DlIRect::MakeLTRB(10, 10, 50, 50));
}

TEST(DisplayListRegion, NonOverlappingRectangles1) {
  std::vector<DlIRect> rects_in;
  for (int i = 0; i < 10; ++i) {
    DlIRect rect = DlIRect::MakeXYWH(50 * i, 50 * i, 50, 50);
    rects_in.push_back(rect);
  }
  DlRegion region(rects_in);
  auto rects = region.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeLTRB(0, 0, 50, 50),
      DlIRect::MakeLTRB(50, 50, 100, 100),
      DlIRect::MakeLTRB(100, 100, 150, 150),
      DlIRect::MakeLTRB(150, 150, 200, 200),
      DlIRect::MakeLTRB(200, 200, 250, 250),
      DlIRect::MakeLTRB(250, 250, 300, 300),
      DlIRect::MakeLTRB(300, 300, 350, 350),
      DlIRect::MakeLTRB(350, 350, 400, 400),
      DlIRect::MakeLTRB(400, 400, 450, 450),
      DlIRect::MakeLTRB(450, 450, 500, 500),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, NonOverlappingRectangles2) {
  DlRegion region({
      DlIRect::MakeXYWH(5, 5, 10, 10),
      DlIRect::MakeXYWH(25, 5, 10, 10),
      DlIRect::MakeXYWH(5, 25, 10, 10),
      DlIRect::MakeXYWH(25, 25, 10, 10),
  });
  auto rects = region.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(5, 5, 10, 10),
      DlIRect::MakeXYWH(25, 5, 10, 10),
      DlIRect::MakeXYWH(5, 25, 10, 10),
      DlIRect::MakeXYWH(25, 25, 10, 10),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, NonOverlappingRectangles3) {
  DlRegion region({
      DlIRect::MakeXYWH(0, 0, 10, 10),
      DlIRect::MakeXYWH(-11, -11, 10, 10),
      DlIRect::MakeXYWH(11, 11, 10, 10),
      DlIRect::MakeXYWH(-11, 0, 10, 10),
      DlIRect::MakeXYWH(0, 11, 10, 10),
      DlIRect::MakeXYWH(0, -11, 10, 10),
      DlIRect::MakeXYWH(11, 0, 10, 10),
      DlIRect::MakeXYWH(11, -11, 10, 10),
      DlIRect::MakeXYWH(-11, 11, 10, 10),
  });
  auto rects = region.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(-11, -11, 10, 10),  //
      DlIRect::MakeXYWH(0, -11, 10, 10),    //
      DlIRect::MakeXYWH(11, -11, 10, 10),   //
      DlIRect::MakeXYWH(-11, 0, 10, 10),    //
      DlIRect::MakeXYWH(0, 0, 10, 10),      //
      DlIRect::MakeXYWH(11, 0, 10, 10),     //
      DlIRect::MakeXYWH(-11, 11, 10, 10),   //
      DlIRect::MakeXYWH(0, 11, 10, 10),     //
      DlIRect::MakeXYWH(11, 11, 10, 10),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, MergeTouchingRectangles) {
  DlRegion region({
      DlIRect::MakeXYWH(0, 0, 10, 10),
      DlIRect::MakeXYWH(-10, -10, 10, 10),
      DlIRect::MakeXYWH(10, 10, 10, 10),
      DlIRect::MakeXYWH(-10, 0, 10, 10),
      DlIRect::MakeXYWH(0, 10, 10, 10),
      DlIRect::MakeXYWH(0, -10, 10, 10),
      DlIRect::MakeXYWH(10, 0, 10, 10),
      DlIRect::MakeXYWH(10, -10, 10, 10),
      DlIRect::MakeXYWH(-10, 10, 10, 10),
  });

  auto rects = region.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(-10, -10, 30, 30),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, OverlappingRectangles) {
  std::vector<DlIRect> rects_in;
  for (int i = 0; i < 10; ++i) {
    DlIRect rect = DlIRect::MakeXYWH(10 * i, 10 * i, 50, 50);
    rects_in.push_back(rect);
  }
  DlRegion region(rects_in);
  auto rects = region.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeLTRB(0, 0, 50, 10),
      DlIRect::MakeLTRB(0, 10, 60, 20),
      DlIRect::MakeLTRB(0, 20, 70, 30),
      DlIRect::MakeLTRB(0, 30, 80, 40),
      DlIRect::MakeLTRB(0, 40, 90, 50),
      DlIRect::MakeLTRB(10, 50, 100, 60),
      DlIRect::MakeLTRB(20, 60, 110, 70),
      DlIRect::MakeLTRB(30, 70, 120, 80),
      DlIRect::MakeLTRB(40, 80, 130, 90),
      DlIRect::MakeLTRB(50, 90, 140, 100),
      DlIRect::MakeLTRB(60, 100, 140, 110),
      DlIRect::MakeLTRB(70, 110, 140, 120),
      DlIRect::MakeLTRB(80, 120, 140, 130),
      DlIRect::MakeLTRB(90, 130, 140, 140),
  };

  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, Deband) {
  DlRegion region({
      DlIRect::MakeXYWH(0, 0, 50, 50),
      DlIRect::MakeXYWH(60, 0, 20, 20),
      DlIRect::MakeXYWH(90, 0, 50, 50),
  });

  auto rects_with_deband = region.getRects(true);
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(60, 0, 20, 20),
      DlIRect::MakeXYWH(0, 0, 50, 50),
      DlIRect::MakeXYWH(90, 0, 50, 50),
  };
  EXPECT_EQ(rects_with_deband, expected);

  auto rects_without_deband = region.getRects(false);
  std::vector<DlIRect> expected_without_deband{
      DlIRect::MakeXYWH(0, 0, 50, 20),   //
      DlIRect::MakeXYWH(60, 0, 20, 20),  //
      DlIRect::MakeXYWH(90, 0, 50, 20),  //
      DlIRect::MakeXYWH(0, 20, 50, 30),  //
      DlIRect::MakeXYWH(90, 20, 50, 30),
  };
  EXPECT_EQ(rects_without_deband, expected_without_deband);

  // Single-scanline multi-span region (fast path).
  DlRegion single_band({
      DlIRect::MakeXYWH(0, 0, 10, 20),
      DlIRect::MakeXYWH(20, 0, 10, 20),
  });
  EXPECT_EQ(single_band.getRects(true),
            (std::vector<DlIRect>{DlIRect::MakeXYWH(0, 0, 10, 20),
                                  DlIRect::MakeXYWH(20, 0, 10, 20)}));

  // Staggered columns exercising new spans left of active spans, exact
  // continuation, and trailing active-span flushes.
  DlRegion staggered({
      DlIRect::MakeLTRB(20, 0, 40, 20),
      DlIRect::MakeLTRB(60, 0, 80, 10),
      DlIRect::MakeLTRB(0, 10, 15, 20),
  });
  EXPECT_EQ(staggered.getRects(true), (std::vector<DlIRect>{
                                          DlIRect::MakeLTRB(60, 0, 80, 10),
                                          DlIRect::MakeLTRB(0, 10, 15, 20),
                                          DlIRect::MakeLTRB(20, 0, 40, 20),
                                      }));

  // Wide multi-span region exceeding the inline active-buffer threshold (>16).
  std::vector<DlIRect> wide_input;
  std::vector<DlIRect> wide_expected;
  for (int i = 0; i < 20; ++i) {
    int32_t left = i * 20;
    if (i % 2 == 0) {
      wide_input.push_back(DlIRect::MakeLTRB(left, 0, left + 10, 20));
    } else {
      wide_input.push_back(DlIRect::MakeLTRB(left, 0, left + 10, 10));
      wide_expected.push_back(DlIRect::MakeLTRB(left, 0, left + 10, 10));
    }
  }
  for (int i = 0; i < 20; i += 2) {
    int32_t left = i * 20;
    wide_expected.push_back(DlIRect::MakeLTRB(left, 0, left + 10, 20));
  }
  DlRegion wide_region(wide_input);
  EXPECT_EQ(wide_region.getRects(true), wide_expected);
}

TEST(DisplayListRegion, DebandOrderParity) {
  auto reference_deband = [](const std::vector<DlIRect>& non_debanded) {
    std::vector<DlIRect> rects;
    size_t previous_span_end = 0;
    bool has_top = false;
    int32_t cur_top = 0;
    for (const auto& r : non_debanded) {
      if (!has_top || cur_top != r.GetTop()) {
        previous_span_end = rects.size();
        cur_top = r.GetTop();
        has_top = true;
      }
      int32_t top = r.GetTop();
      auto iter = rects.begin() + previous_span_end;
      while (iter != rects.begin()) {
        --iter;
        if (iter->GetBottom() < top) {
          break;
        }
        if (iter->GetLeft() == r.GetLeft() &&
            iter->GetRight() == r.GetRight()) {
          top = iter->GetTop();
          rects.erase(iter);
          --previous_span_end;
          break;
        }
      }
      rects.push_back(
          DlIRect::MakeLTRB(r.GetLeft(), top, r.GetRight(), r.GetBottom()));
    }
    return rects;
  };

  std::seed_seq seed{42, 7, 13};
  std::mt19937 rng(seed);
  std::uniform_int_distribution<int32_t> pos(0, 60);
  std::uniform_int_distribution<int32_t> size(1, 20);

  for (int trial = 0; trial < 100; ++trial) {
    std::vector<DlIRect> input;
    input.reserve(40);
    for (int i = 0; i < 40; ++i) {
      int32_t x = pos(rng);
      int32_t y = pos(rng);
      int32_t w = size(rng);
      int32_t h = size(rng);
      input.push_back(DlIRect::MakeXYWH(x, y, w, h));
    }
    DlRegion region(input);
    auto non_debanded = region.getRects(false);
    auto debanded = region.getRects(true);
    EXPECT_EQ(debanded, reference_deband(non_debanded));
  }
}

TEST(DisplayListRegion, Intersects1) {
  DlRegion region1({
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(20, 20, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(20, 0, 20, 20),
      DlIRect::MakeXYWH(0, 20, 20, 20),
  });
  EXPECT_FALSE(region1.intersects(region2));
  EXPECT_FALSE(region2.intersects(region1));

  EXPECT_TRUE(region1.intersects(region2.bounds()));
  EXPECT_TRUE(region2.intersects(region1.bounds()));

  EXPECT_TRUE(region1.intersects(DlIRect::MakeXYWH(0, 0, 20, 20)));
  EXPECT_FALSE(region1.intersects(DlIRect::MakeXYWH(20, 0, 20, 20)));

  EXPECT_TRUE(region1.intersects(
      DlRegion(std::vector<DlIRect>{DlIRect::MakeXYWH(0, 0, 20, 20)})));
  EXPECT_FALSE(region1.intersects(
      DlRegion(std::vector<DlIRect>{DlIRect::MakeXYWH(20, 0, 20, 20)})));

  EXPECT_FALSE(region1.intersects(DlIRect::MakeXYWH(-1, -1, 1, 1)));
  EXPECT_TRUE(region1.intersects(DlIRect::MakeXYWH(0, 0, 1, 1)));

  EXPECT_FALSE(region1.intersects(DlIRect::MakeXYWH(40, 40, 1, 1)));
  EXPECT_TRUE(region1.intersects(DlIRect::MakeXYWH(39, 39, 1, 1)));
}

TEST(DisplayListRegion, Intersects2) {
  DlRegion region1({
      DlIRect::MakeXYWH(-10, -10, 20, 20),
      DlIRect::MakeXYWH(-30, -30, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(20, 20, 5, 5),
      DlIRect::MakeXYWH(0, 0, 20, 20),
  });
  EXPECT_TRUE(region1.intersects(region2));
  EXPECT_TRUE(region2.intersects(region1));
}

TEST(DisplayListRegion, Intersection1) {
  DlRegion region1({
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(20, 20, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(20, 0, 20, 20),
      DlIRect::MakeXYWH(0, 20, 20, 20),
  });
  DlRegion i = DlRegion::MakeIntersection(region1, region2);
  EXPECT_EQ(i.bounds(), DlIRect());
  EXPECT_TRUE(i.isEmpty());
  auto rects = i.getRects();
  EXPECT_TRUE(rects.empty());
}

TEST(DisplayListRegion, Intersection2) {
  DlRegion region1({
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(20, 20, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(20, 20, 20, 20),
  });
  DlRegion i = DlRegion::MakeIntersection(region1, region2);
  EXPECT_EQ(i.bounds(), DlIRect::MakeXYWH(0, 0, 40, 40));
  auto rects = i.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(20, 20, 20, 20),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, Intersection3) {
  DlRegion region1({
      DlIRect::MakeXYWH(0, 0, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(-10, -10, 20, 20),
      DlIRect::MakeXYWH(10, 10, 20, 20),
  });
  DlRegion i = DlRegion::MakeIntersection(region1, region2);
  EXPECT_EQ(i.bounds(), DlIRect::MakeXYWH(0, 0, 20, 20));
  auto rects = i.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(0, 0, 10, 10),
      DlIRect::MakeXYWH(10, 10, 10, 10),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, Union1) {
  DlRegion region1({
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(20, 20, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(20, 0, 20, 20),
      DlIRect::MakeXYWH(0, 20, 20, 20),
  });
  DlRegion u = DlRegion::MakeUnion(region1, region2);
  EXPECT_EQ(u.bounds(), DlIRect::MakeXYWH(0, 0, 40, 40));
  EXPECT_TRUE(u.isSimple());
  auto rects = u.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(0, 0, 40, 40),  //
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, Union2) {
  DlRegion region1({
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(21, 21, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(21, 0, 20, 20),
      DlIRect::MakeXYWH(0, 21, 20, 20),
  });
  DlRegion u = DlRegion::MakeUnion(region1, region2);
  EXPECT_EQ(u.bounds(), DlIRect::MakeXYWH(0, 0, 41, 41));
  auto rects = u.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(0, 0, 20, 20),
      DlIRect::MakeXYWH(21, 0, 20, 20),
      DlIRect::MakeXYWH(0, 21, 20, 20),
      DlIRect::MakeXYWH(21, 21, 20, 20),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, Union3) {
  DlRegion region1({
      DlIRect::MakeXYWH(-10, -10, 20, 20),
  });
  DlRegion region2({
      DlIRect::MakeXYWH(0, 0, 20, 20),
  });
  DlRegion u = DlRegion::MakeUnion(region1, region2);
  EXPECT_EQ(u.bounds(), DlIRect::MakeXYWH(-10, -10, 30, 30));
  auto rects = u.getRects();
  std::vector<DlIRect> expected{
      DlIRect::MakeXYWH(-10, -10, 20, 10),
      DlIRect::MakeXYWH(-10, 0, 30, 10),
      DlIRect::MakeXYWH(0, 10, 20, 10),
  };
  EXPECT_EQ(rects, expected);
}

TEST(DisplayListRegion, UnionEmpty) {
  {
    DlRegion region1(std::vector<DlIRect>{});
    DlRegion region2(std::vector<DlIRect>{});
    DlRegion u = DlRegion::MakeUnion(region1, region2);
    EXPECT_EQ(u.bounds(), DlIRect());
    EXPECT_TRUE(u.isEmpty());
    auto rects = u.getRects();
    EXPECT_TRUE(rects.empty());
  }
  {
    DlRegion region1(std::vector<DlIRect>{});
    DlRegion region2({
        DlIRect::MakeXYWH(0, 0, 20, 20),
    });
    DlRegion u = DlRegion::MakeUnion(region1, region2);
    EXPECT_EQ(u.bounds(), DlIRect::MakeXYWH(0, 0, 20, 20));
    auto rects = u.getRects();
    std::vector<DlIRect> expected{
        DlIRect::MakeXYWH(0, 0, 20, 20),
    };
    EXPECT_EQ(rects, expected);
  }
  {
    DlRegion region1({
        DlIRect::MakeXYWH(0, 0, 20, 20),
    });
    DlRegion region2(std::vector<DlIRect>{});
    DlRegion u = DlRegion::MakeUnion(region1, region2);
    EXPECT_EQ(u.bounds(), DlIRect::MakeXYWH(0, 0, 20, 20));
    auto rects = u.getRects();
    std::vector<DlIRect> expected{
        DlIRect::MakeXYWH(0, 0, 20, 20),
    };
    EXPECT_EQ(rects, expected);
  }
}

void CheckEquality(const DlRegion& dl_region, const SkRegion& sk_region) {
  EXPECT_EQ(dl_region.bounds(), ToDlIRect(sk_region.getBounds()));

  // Do not deband the rectangles - identical to SkRegion::Iterator
  auto rects = dl_region.getRects(false);

  std::vector<DlIRect> skia_rects;

  auto iterator = SkRegion::Iterator(sk_region);
  while (!iterator.done()) {
    skia_rects.push_back(ToDlIRect(iterator.rect()));
    iterator.next();
  }

  EXPECT_EQ(rects, skia_rects);
}

TEST(DisplayListRegion, TestAgainstSkRegion) {
  struct Settings {
    int max_size;
  };
  std::vector<Settings> all_settings{{100}, {400}, {800}};

  std::vector<size_t> iterations{1, 10, 100, 1000};

  for (const auto& settings : all_settings) {
    for (const auto iterations_1 : iterations) {
      for (const auto iterations_2 : iterations) {
        std::random_device d;
        std::seed_seq seed{::testing::UnitTest::GetInstance()->random_seed()};
        std::mt19937 rng(seed);

        SkRegion sk_region1;
        SkRegion sk_region2;

        std::uniform_int_distribution pos(0, 4000);
        std::uniform_int_distribution size(1, settings.max_size);

        std::vector<DlIRect> rects_in1;
        std::vector<DlIRect> rects_in2;

        for (size_t i = 0; i < iterations_1; ++i) {
          DlIRect rect =
              DlIRect::MakeXYWH(pos(rng), pos(rng), size(rng), size(rng));
          rects_in1.push_back(rect);
        }

        for (size_t i = 0; i < iterations_2; ++i) {
          DlIRect rect =
              DlIRect::MakeXYWH(pos(rng), pos(rng), size(rng), size(rng));
          rects_in2.push_back(rect);
        }

        DlRegion region1(rects_in1);
        sk_region1.setRects(ToSkIRects(rects_in1.data()), rects_in1.size());
        CheckEquality(region1, sk_region1);

        DlRegion region2(rects_in2);
        sk_region2.setRects(ToSkIRects(rects_in2.data()), rects_in2.size());
        CheckEquality(region2, sk_region2);

        auto intersects_1 = region1.intersects(region2);
        auto intersects_2 = region2.intersects(region1);
        auto sk_intesects = sk_region1.intersects(sk_region2);
        EXPECT_EQ(intersects_1, intersects_2);
        EXPECT_EQ(intersects_1, sk_intesects);

        {
          auto rects = region2.getRects(true);
          for (const auto& r : rects) {
            EXPECT_EQ(region1.intersects(r),
                      sk_region1.intersects(ToSkIRect(r)));
          }
        }

        DlRegion dl_union = DlRegion::MakeUnion(region1, region2);
        SkRegion sk_union(sk_region1);
        sk_union.op(sk_region2, SkRegion::kUnion_Op);
        CheckEquality(dl_union, sk_union);

        DlRegion dl_intersection = DlRegion::MakeIntersection(region1, region2);
        SkRegion sk_intersection(sk_region1);
        sk_intersection.op(sk_region2, SkRegion::kIntersect_Op);
        CheckEquality(dl_intersection, sk_intersection);
      }
    }
  }
}

}  // namespace testing
}  // namespace flutter
