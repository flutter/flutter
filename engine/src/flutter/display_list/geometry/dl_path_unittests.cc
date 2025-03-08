// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path.h"
#include "gtest/gtest.h"

#include "flutter/third_party/skia/include/core/SkRRect.h"

namespace flutter {
namespace testing {

TEST(DisplayListPath, DefaultConstruction) {
  DlPath path;

  EXPECT_FALSE(path.IsConverted());
  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetSkPath(), SkPath());
  EXPECT_TRUE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());

  EXPECT_FALSE(path.IsVolatile());

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_FALSE(path.IsSkRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_EQ(path.GetSkBounds(), SkRect());
}

TEST(DisplayListPath, ConstructFromEmptySkiaPath) {
  SkPath sk_path;
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetSkPath(), SkPath());
  EXPECT_FALSE(path.IsConverted());

  EXPECT_TRUE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());
  EXPECT_FALSE(path.IsVolatile());

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_FALSE(path.IsSkRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_EQ(path.GetSkBounds(), SkRect());
}

TEST(DisplayListPath, ConstructFromEmptyImpellerPath) {
  impeller::Path imp_path;
  DlPath path(imp_path);

  EXPECT_TRUE(path.GetPath().IsEmpty());
  EXPECT_FALSE(path.IsConverted());

  EXPECT_EQ(path.GetSkPath(), SkPath());
  EXPECT_TRUE(path.IsConverted());
  EXPECT_FALSE(path.IsVolatile());

  EXPECT_EQ(path, DlPath());

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_FALSE(path.IsSkRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_EQ(path.GetSkBounds(), SkRect());
}

TEST(DisplayListPath, CopyConstruct) {
  SkPath sk_path = SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path1(sk_path);
  DlPath path2 = DlPath(path1);

  EXPECT_EQ(path2, path1);
  EXPECT_EQ(path2, DlPath(SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20))));
  EXPECT_EQ(path2.GetSkPath(), SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20)));

  EXPECT_FALSE(path2.IsConverted());
  EXPECT_FALSE(path2.IsVolatile());

  bool is_closed = false;
  EXPECT_FALSE(path2.IsRect(nullptr));
  EXPECT_FALSE(path2.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_TRUE(path2.IsOval(nullptr));
  EXPECT_FALSE(path2.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path2.IsSkRect(nullptr));
  EXPECT_FALSE(path2.IsSkRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_TRUE(path2.IsSkOval(nullptr));
  EXPECT_FALSE(path2.IsSkRRect(nullptr));

  EXPECT_EQ(path2.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path2.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromVolatile) {
  SkPath sk_path;
  sk_path.setIsVolatile(true);
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetSkPath(), SkPath());

  EXPECT_FALSE(path.IsConverted());
  EXPECT_TRUE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());
  EXPECT_TRUE(path.IsVolatile());

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_FALSE(path.IsSkRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_EQ(path.GetSkBounds(), SkRect());
}

TEST(DisplayListPath, VolatileBecomesNonVolatile) {
  SkPath sk_path;
  sk_path.setIsVolatile(true);
  DlPath path(sk_path);

  EXPECT_TRUE(path.IsVolatile());

  for (int i = 0; i < 1000; i++) {
    // grabbing the Impeller version of the path does not make it non-volatile
    path.GetPath();
  }
  EXPECT_TRUE(path.IsVolatile());

  for (int i = 0; i < 1000; i++) {
    // not specifying intent to render does not make it non-volatile
    path.GetSkPath();
  }
  EXPECT_TRUE(path.IsVolatile());

  for (uint32_t i = 0; i < DlPath::kMaxVolatileUses; i++) {
    // Expressing intent to render will only be volatile the first few times
    path.WillRenderSkPath();
    path.GetSkPath();
    EXPECT_TRUE(path.IsVolatile());
  }

  for (int i = 0; i < 1000; i++) {
    // further uses without expressing intent to render do not make it
    // non-volatile
    path.GetSkPath();
  }
  EXPECT_TRUE(path.IsVolatile());

  // One last time makes the path non-volatile
  path.WillRenderSkPath();
  path.GetSkPath();
  EXPECT_FALSE(path.IsVolatile());
}

TEST(DisplayListPath, MultipleVolatileCopiesBecomeNonVolatileTogether) {
  SkPath sk_path;
  sk_path.setIsVolatile(true);
  DlPath path(sk_path);
  const DlPath paths[4] = {
      path,
      path,
      path,
      path,
  };

  EXPECT_TRUE(path.IsVolatile());

  for (uint32_t i = 0; i < DlPath::kMaxVolatileUses; i++) {
    // Expressing intent to render will only be volatile the first few times
    paths[i].WillRenderSkPath();
    EXPECT_TRUE(path.IsVolatile());
    for (const auto& p : paths) {
      EXPECT_TRUE(p.IsVolatile());
    }
  }

  // One last time makes the path non-volatile
  paths[3].WillRenderSkPath();
  EXPECT_FALSE(path.IsVolatile());
  for (const auto& p : paths) {
    EXPECT_FALSE(p.IsVolatile());
  }
}

TEST(DisplayListPath, EmbeddingSharedReference) {
  SkPath sk_path = SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(sk_path);

  class ConversionSharingTester {
   public:
    explicit ConversionSharingTester(const DlPath& path) : path_(path) {}

    bool ConvertAndTestEmpty() { return path_.GetPath().IsEmpty(); }

    bool Test(const DlPath& reference_path, const std::string& label) {
      EXPECT_EQ(path_, reference_path) << label;
      EXPECT_EQ(path_, DlPath(SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20))))
          << label;
      EXPECT_EQ(path_.GetSkPath(),
                SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20)))
          << label;

      bool is_closed = false;
      EXPECT_FALSE(path_.IsRect(nullptr)) << label;
      EXPECT_FALSE(path_.IsRect(nullptr, &is_closed)) << label;
      EXPECT_FALSE(is_closed) << label;
      EXPECT_TRUE(path_.IsOval(nullptr)) << label;
      EXPECT_FALSE(path_.IsRoundRect(nullptr));

      is_closed = false;
      EXPECT_FALSE(path_.IsSkRect(nullptr)) << label;
      EXPECT_FALSE(path_.IsSkRect(nullptr, &is_closed)) << label;
      EXPECT_FALSE(is_closed) << label;
      EXPECT_TRUE(path_.IsSkOval(nullptr)) << label;
      EXPECT_FALSE(path_.IsSkRRect(nullptr)) << label;

      EXPECT_EQ(path_.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20)) << label;
      EXPECT_EQ(path_.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20)) << label;
      return path_.IsConverted();
    };

   private:
    const DlPath path_;
  };

  EXPECT_FALSE(path.IsConverted());
  ConversionSharingTester before_tester(path);
  EXPECT_FALSE(before_tester.Test(path, "Before triggering conversion"));
  EXPECT_FALSE(path.GetPath().IsEmpty());
  EXPECT_TRUE(before_tester.Test(path, "After conversion of source object"));
  EXPECT_FALSE(before_tester.ConvertAndTestEmpty());
  EXPECT_TRUE(before_tester.Test(path, "After conversion of captured object"));

  EXPECT_TRUE(path.IsConverted());
  ConversionSharingTester after_tester(path);
  EXPECT_TRUE(after_tester.Test(path, "Constructed after conversion"));
}

TEST(DisplayListPath, ConstructFromRect) {
  SkPath sk_path = SkPath::Rect(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath(SkPath::Rect(SkRect::MakeLTRB(10, 10, 20, 20))));
  EXPECT_EQ(path.GetSkPath(), SkPath::Rect(SkRect::MakeLTRB(10, 10, 20, 20)));

  EXPECT_FALSE(path.IsConverted());
  EXPECT_FALSE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());

  bool is_closed = false;
  EXPECT_TRUE(path.IsRect(nullptr));
  DlRect dl_rect;
  EXPECT_TRUE(path.IsRect(&dl_rect, &is_closed));
  EXPECT_EQ(dl_rect, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_TRUE(path.IsSkRect(nullptr));
  SkRect sk_rect;
  EXPECT_TRUE(path.IsSkRect(&sk_rect, &is_closed));
  EXPECT_EQ(sk_rect, SkRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromDlPathBuilderRect) {
  DlPathBuilder builder;
  builder.AddRect(DlRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(builder);
  EXPECT_FALSE(path.IsConverted());

  // Paths constructed from PathBuilder don't match paths built from similar
  // SkRect and SkPath and DlPath factory methods exactly, only paths built
  // from similar PathBuilder calls match exactly for == comparison
  {
    DlPathBuilder builder2;
    builder2.AddRect(DlRect::MakeLTRB(10, 10, 20, 20));
    EXPECT_EQ(path, DlPath(builder2));
  }
  EXPECT_TRUE(path.IsConverted());

  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.GetPath().IsEmpty());

  bool is_closed = false;
  EXPECT_TRUE(path.IsRect(nullptr));
  DlRect dl_rect;
  EXPECT_TRUE(path.IsRect(&dl_rect, &is_closed));
  EXPECT_EQ(dl_rect, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_TRUE(path.IsSkRect(nullptr));
  SkRect sk_rect;
  EXPECT_TRUE(path.IsSkRect(&sk_rect, &is_closed));
  EXPECT_EQ(sk_rect, SkRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromOval) {
  SkPath sk_path = SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath(SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20))));
  EXPECT_EQ(path.GetSkPath(), SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20)));

  EXPECT_FALSE(path.IsConverted());
  EXPECT_FALSE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_TRUE(path.IsOval(nullptr));
  DlRect dl_bounds;
  EXPECT_TRUE(path.IsOval(&dl_bounds));
  EXPECT_EQ(dl_bounds, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_TRUE(path.IsSkOval(nullptr));
  SkRect sk_bounds;
  EXPECT_TRUE(path.IsSkOval(&sk_bounds));
  EXPECT_EQ(sk_bounds, SkRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromDlPathBuilderOval) {
  DlPathBuilder builder;
  builder.AddOval(DlRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(builder);
  EXPECT_FALSE(path.IsConverted());

  // Paths constructed from PathBuilder don't match paths built from similar
  // SkRect and SkPath and DlPath factory methods exactly, only paths built
  // from similar PathBuilder calls match exactly for == comparison
  {
    DlPathBuilder builder2;
    builder2.AddOval(DlRect::MakeLTRB(10, 10, 20, 20));
    EXPECT_EQ(path, DlPath(builder2));
  }
  EXPECT_TRUE(path.IsConverted());

  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.GetPath().IsEmpty());

  // Skia path, used for these tests,  doesn't recognize ovals created
  // by PathBuilder
  EXPECT_FALSE(path.IsRect(nullptr));
  // EXPECT_TRUE(path.IsOval(nullptr));
  // DlRect dl_bounds;
  // EXPECT_TRUE(path.IsOval(&dl_bounds));
  // EXPECT_EQ(dl_bounds, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  // Skia path, used for these tests,  doesn't recognize ovals created
  // by PathBuilder
  EXPECT_FALSE(path.IsSkRect(nullptr));
  // EXPECT_TRUE(path.IsSkOval(nullptr));
  // SkRect sk_bounds;
  // EXPECT_TRUE(path.IsSkOval(&sk_bounds));
  // EXPECT_EQ(sk_bounds, SkRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromRRect) {
  SkPath sk_path = SkPath::RRect(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2);
  DlPath path(sk_path);

  EXPECT_EQ(path,
            DlPath(SkPath::RRect(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2)));
  EXPECT_EQ(path.GetSkPath(),
            SkPath::RRect(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_FALSE(path.IsConverted());
  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  DlRoundRect roundrect;
  EXPECT_TRUE(path.IsRoundRect(&roundrect));
  EXPECT_EQ(roundrect,
            DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_TRUE(path.IsSkRRect(nullptr));
  SkRRect rrect2;
  EXPECT_TRUE(path.IsSkRRect(&rrect2));
  EXPECT_EQ(rrect2,
            SkRRect::MakeRectXY(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromDlPathBuilderRoundRect) {
  DlPathBuilder builder;
  builder.AddRoundRect(
      DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));
  DlPath path(builder);
  EXPECT_FALSE(path.IsConverted());

  // Paths constructed from PathBuilder don't match paths built from similar
  // SkRRect and SkPath and DlPath factory methods exactly, only built from
  // similar PathBuilder calls match exactly for == comparison
  {
    DlPathBuilder builder2;
    builder2.AddRoundRect(
        DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));
    EXPECT_EQ(path, DlPath(builder2));
  }
  EXPECT_TRUE(path.IsConverted());

  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.GetPath().IsEmpty());

  // Skia path, used for these tests,  doesn't recognize ovals created
  // by PathBuilder
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  // DlRoundRect roundrect;
  // EXPECT_TRUE(path.IsRoundRect(&roundrect));
  // EXPECT_EQ(roundrect,
  //           DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  // Skia path, used for these tests,  doesn't recognize round rects created
  // by PathBuilder
  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_FALSE(path.IsSkOval(nullptr));
  // EXPECT_TRUE(path.IsSkRRect(nullptr));
  // SkRRect rrect2;
  // EXPECT_TRUE(path.IsSkRRect(&rrect2));
  // EXPECT_EQ(rrect2,
  //           SkRRect::MakeRectXY(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromPath) {
  SkPath sk_path1;
  sk_path1.moveTo(10, 10);
  sk_path1.lineTo(20, 20);
  sk_path1.lineTo(20, 10);
  SkPath sk_path2;
  sk_path2.moveTo(10, 10);
  sk_path2.lineTo(20, 20);
  sk_path2.lineTo(20, 10);
  DlPath path(sk_path1);

  ASSERT_EQ(sk_path1, sk_path2);

  EXPECT_EQ(path, DlPath(sk_path2));
  EXPECT_EQ(path.GetSkPath(), sk_path2);

  EXPECT_FALSE(path.IsConverted());
  EXPECT_FALSE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsSkRect(nullptr));
  EXPECT_FALSE(path.IsSkOval(nullptr));
  EXPECT_FALSE(path.IsSkRRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_EQ(path.GetSkBounds(), SkRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromImpellerEqualsConstructFromSkia) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({0, 0});
  path_builder.LineTo({100, 0});
  path_builder.LineTo({0, 100});
  path_builder.Close();

  SkPath sk_path;
  sk_path.setFillType(SkPathFillType::kWinding);
  sk_path.moveTo(0, 0);
  sk_path.lineTo(100, 0);
  sk_path.lineTo(0, 100);
  sk_path.lineTo(0, 0);  // Shouldn't be needed, but PathBuilder draws this
  sk_path.close();

  EXPECT_EQ(DlPath(path_builder, DlPathFillType::kNonZero), DlPath(sk_path));
}

namespace {
class TestPathElement {
 public:
  enum class Type {
    kMoveTo,
    kLineTo,
    kQuadTo,
    kConicTo,
    kCubicTo,
    kClose,
  };

  static TestPathElement MoveTo(const DlPoint& p) {
    return {
        .type = Type::kMoveTo,
        .p1 = p,
    };
  }
  static TestPathElement LineTo(const DlPoint& p) {
    return {
        .type = Type::kLineTo,
        .p1 = p,
    };
  }
  static TestPathElement QuadTo(const DlPoint& cp, const DlPoint& p2) {
    return {
        .type = Type::kQuadTo,
        .p1 = cp,
        .p2 = p2,
    };
  }
  static TestPathElement ConicTo(const DlPoint& cp,
                                 const DlPoint& p2,
                                 DlScalar w) {
    return {
        .type = Type::kConicTo,
        .p1 = cp,
        .p2 = p2,
        .weight = w,
    };
  }
  static TestPathElement CubicTo(const DlPoint& cp1,
                                 const DlPoint& cp2,
                                 const DlPoint& p2) {
    return {
        .type = Type::kCubicTo,
        .p1 = cp1,
        .p2 = cp2,
        .p3 = p2,
    };
  }
  static TestPathElement Close() { return {.type = Type::kClose}; }

  const Type type;
  const DlPoint p1;
  const DlPoint p2;
  const DlPoint p3;
  const DlScalar weight;
};

class TestPathReceiver : public DlPathReceiver {
 public:
  TestPathReceiver(DlPathFillType expected_fill_type,
                   size_t expected_verb_count,
                   size_t expected_point_count,
                   std::optional<DlRect> expected_bounds,
                   std::optional<bool> expected_is_convex,
                   std::vector<TestPathElement> expected_path_elements)
      : expected_bounds_(expected_bounds),
        expected_verb_count_(expected_verb_count),
        expected_point_count_(expected_point_count),
        expected_fill_type_(expected_fill_type),
        expected_is_convex_(expected_is_convex),
        expected_path_elements_(std::move(expected_path_elements)) {}

  void RecommendSizes(size_t verb_count, size_t point_count) override {
    EXPECT_EQ(path_index_, 0u);
    EXPECT_EQ(verb_count, expected_verb_count_);
    EXPECT_EQ(point_count, expected_point_count_);
  }
  void RecommendBounds(const DlRect& bounds) override {
    EXPECT_EQ(path_index_, 0u);
    if (expected_bounds_.has_value()) {
      EXPECT_NEAR(bounds.GetLeft(), expected_bounds_.value().GetLeft(),
                  kEhCloseEnough);
      EXPECT_NEAR(bounds.GetTop(), expected_bounds_.value().GetTop(),
                  kEhCloseEnough);
      EXPECT_NEAR(bounds.GetRight(), expected_bounds_.value().GetRight(),
                  kEhCloseEnough);
      EXPECT_NEAR(bounds.GetBottom(), expected_bounds_.value().GetBottom(),
                  kEhCloseEnough);
    }
  }
  void SetPathInfo(DlPathFillType type, bool is_convex) override {
    EXPECT_EQ(path_index_, 0u);
    EXPECT_FALSE(set_path_info_called_);
    EXPECT_EQ(type, expected_fill_type_);
    if (expected_is_convex_.has_value()) {
      EXPECT_EQ(is_convex, expected_is_convex_.value());
    }
    set_path_info_called_ = true;
  }
  void MoveTo(const DlPoint& p) override {
    if (const TestPathElement* element = GetElement()) {
      EXPECT_EQ(element->type, TestPathElement::Type::kMoveTo) << label();
      EXPECT_EQ(element->p1, p) << label();
      path_index_++;
    }
  }
  void LineTo(const DlPoint& p) override {
    if (const TestPathElement* element = GetElement()) {
      EXPECT_EQ(element->type, TestPathElement::Type::kLineTo) << label();
      EXPECT_EQ(element->p1, p) << label();
      path_index_++;
    }
  }
  void QuadTo(const DlPoint& cp, const DlPoint& p2) override {
    if (const TestPathElement* element = GetElement()) {
      EXPECT_EQ(element->type, TestPathElement::Type::kQuadTo) << label();
      EXPECT_EQ(element->p1, cp) << label();
      EXPECT_EQ(element->p2, p2) << label();
      path_index_++;
    }
  }
  bool ConicTo(const DlPoint& cp, const DlPoint& p2, DlScalar w) override {
    if (const TestPathElement* element = GetElement()) {
      EXPECT_EQ(element->type, TestPathElement::Type::kConicTo) << label();
      EXPECT_EQ(element->p1, cp) << label();
      EXPECT_EQ(element->p2, p2) << label();
      EXPECT_EQ(element->weight, w) << label();
      path_index_++;
    }
    return true;
  }
  void CubicTo(const DlPoint& cp1,
               const DlPoint& cp2,
               const DlPoint& p2) override {
    if (const TestPathElement* element = GetElement()) {
      EXPECT_EQ(element->type, TestPathElement::Type::kCubicTo) << label();
      EXPECT_EQ(element->p1, cp1) << label();
      EXPECT_EQ(element->p2, cp2) << label();
      EXPECT_EQ(element->p3, p2) << label();
      path_index_++;
    }
  }
  void Close() override {
    if (const TestPathElement* element = GetElement()) {
      EXPECT_EQ(element->type, TestPathElement::Type::kClose) << label();
      path_index_++;
    }
  }

  void CheckComplete() {
    EXPECT_TRUE(set_path_info_called_);
    EXPECT_EQ(path_index_, expected_path_elements_.size());
  }

 private:
  const std::optional<DlRect> expected_bounds_;
  const size_t expected_verb_count_;
  const size_t expected_point_count_;
  const DlPathFillType expected_fill_type_;
  const std::optional<bool> expected_is_convex_;
  const std::vector<TestPathElement> expected_path_elements_;

  size_t path_index_ = 0u;
  bool set_path_info_called_ = false;

  const TestPathElement* GetElement() {
    if (path_index_ < expected_path_elements_.size()) {
      return &expected_path_elements_[path_index_];
    } else {
      EXPECT_LT(path_index_, expected_path_elements_.size()) << label();
      return nullptr;
    }
  }

  std::string label() { return "at index " + std::to_string(path_index_); }
};
}  // namespace

TEST(DisplayListPath, DispatchSkiaPathEvenOdd) {
  SkPath path;

  path.setFillType(SkPathFillType::kEvenOdd);
  path.moveTo(100, 200);
  path.lineTo(101, 201);
  path.quadTo(110, 202, 102, 210);
  path.conicTo(150, 240, 250, 140, 0.5);
  path.cubicTo(300, 300, 350, 300, 300, 350);
  path.close();

  TestPathReceiver receiver(
      /* expected_fill_type   = */ DlPathFillType::kOdd,
      /* expected_verb_count  = */ 6u,
      /* expected_point_count = */ 9u,
      /* expected_bounds      = */ DlRect::MakeLTRB(100, 140, 350, 350),
      /* expected_is_convex   = */ false,
      std::vector<TestPathElement>{
          TestPathElement::MoveTo(DlPoint(100, 200)),
          TestPathElement::LineTo(DlPoint(101, 201)),
          TestPathElement::QuadTo(DlPoint(110, 202), DlPoint(102, 210)),
          TestPathElement::ConicTo(DlPoint(150, 240), DlPoint(250, 140), 0.5f),
          TestPathElement::CubicTo(DlPoint(300, 300), DlPoint(350, 300),
                                   DlPoint(300, 350)),
          // Closing LineTo added implicitly to return to first point
          TestPathElement::LineTo(DlPoint(100, 200)),
          TestPathElement::Close(),
      });

  DlPath(path).Dispatch(receiver);
  receiver.CheckComplete();
}

TEST(DisplayListPath, DispatchSkiaPathNonZero) {
  SkPath path;

  path.setFillType(SkPathFillType::kWinding);
  path.moveTo(100, 200);
  path.lineTo(101, 201);
  path.quadTo(110, 202, 102, 210);
  path.conicTo(150, 240, 250, 140, 0.5);
  path.cubicTo(300, 300, 350, 300, 300, 350);
  path.close();

  TestPathReceiver receiver(
      /* expected_fill_type   = */ DlPathFillType::kNonZero,
      /* expected_verb_count  = */ 6u,
      /* expected_point_count = */ 9u,
      /* expected_bounds      = */ DlRect::MakeLTRB(100, 140, 350, 350),
      /* expected_is_convex   = */ false,
      std::vector<TestPathElement>{
          TestPathElement::MoveTo(DlPoint(100, 200)),
          TestPathElement::LineTo(DlPoint(101, 201)),
          TestPathElement::QuadTo(DlPoint(110, 202), DlPoint(102, 210)),
          TestPathElement::ConicTo(DlPoint(150, 240), DlPoint(250, 140), 0.5f),
          TestPathElement::CubicTo(DlPoint(300, 300), DlPoint(350, 300),
                                   DlPoint(300, 350)),
          // Closing LineTo added implicitly to return to first point
          TestPathElement::LineTo(DlPoint(100, 200)),
          TestPathElement::Close(),
      });

  DlPath(path).Dispatch(receiver);
  receiver.CheckComplete();
}

TEST(DisplayListPath, DispatchSkiaPathConvex) {
  SkPath path;

  path.setFillType(SkPathFillType::kWinding);
  // Keep it simple - a triangle is obviously convex
  path.moveTo(100, 200);
  path.lineTo(200, 200);
  path.lineTo(100, 300);
  path.close();

  TestPathReceiver receiver(
      /* expected_fill_type   = */ DlPathFillType::kNonZero,
      /* expected_verb_count  = */ 4u,
      /* expected_point_count = */ 3u,
      /* expected_bounds      = */ DlRect::MakeLTRB(100, 200, 200, 300),
      /* expected_is_convex   = */ true,
      std::vector<TestPathElement>{
          TestPathElement::MoveTo(DlPoint(100, 200)),
          TestPathElement::LineTo(DlPoint(200, 200)),
          TestPathElement::LineTo(DlPoint(100, 300)),
          // Closing LineTo added implicitly to return to first point
          TestPathElement::LineTo(DlPoint(100, 200)),
          TestPathElement::Close(),
      });

  DlPath(path).Dispatch(receiver);
  receiver.CheckComplete();
}

TEST(DisplayListPath, DispatchImpellerPathEvenOdd) {
  DlPathBuilder path_builder;

  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.LineTo(DlPoint(101, 201));
  path_builder.QuadraticCurveTo(DlPoint(110, 202), DlPoint(102, 210));
  path_builder.ConicCurveTo(DlPoint(150, 240), DlPoint(250, 140), 0.5);
  path_builder.CubicCurveTo(DlPoint(300, 300), DlPoint(350, 300),
                            DlPoint(300, 350));
  path_builder.Close();

  TestPathReceiver receiver(
      /* expected_fill_type   = */ DlPathFillType::kOdd,
      /* expected_verb_count  = */ 7u,
      /* expected_point_count = */ 19u,
      /* expected_bounds      = */ DlRect::MakeLTRB(100, 140, 320.711, 350),
      /* expected_is_convex   = */ false,
      std::vector<TestPathElement>{
          TestPathElement::MoveTo(DlPoint(100, 200)),
          TestPathElement::LineTo(DlPoint(101, 201)),
          TestPathElement::QuadTo(DlPoint(110, 202), DlPoint(102, 210)),
          TestPathElement::ConicTo(DlPoint(150, 240), DlPoint(250, 140), 0.5f),
          TestPathElement::CubicTo(DlPoint(300, 300), DlPoint(350, 300),
                                   DlPoint(300, 350)),
          // Closing LineTo added implicitly to return to first point
          TestPathElement::LineTo(DlPoint(100, 200)),
          TestPathElement::Close(),
      });

  DlPath(path_builder, DlPathFillType::kOdd).Dispatch(receiver);
  receiver.CheckComplete();
}

TEST(DisplayListPath, DispatchImpellerPathNonZero) {
  DlPathBuilder path_builder;

  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.LineTo(DlPoint(101, 201));
  path_builder.QuadraticCurveTo(DlPoint(110, 202), DlPoint(102, 210));
  path_builder.ConicCurveTo(DlPoint(150, 240), DlPoint(250, 140), 0.5);
  path_builder.CubicCurveTo(DlPoint(300, 300), DlPoint(350, 300),
                            DlPoint(300, 350));
  path_builder.Close();

  TestPathReceiver receiver(
      /* expected_fill_type   = */ DlPathFillType::kNonZero,
      /* expected_verb_count  = */ 7u,
      /* expected_point_count = */ 19u,
      /* expected_bounds      = */ DlRect::MakeLTRB(100, 140, 320.711, 350),
      /* expected_is_convex   = */ false,
      std::vector<TestPathElement>{
          TestPathElement::MoveTo(DlPoint(100, 200)),
          TestPathElement::LineTo(DlPoint(101, 201)),
          TestPathElement::QuadTo(DlPoint(110, 202), DlPoint(102, 210)),
          TestPathElement::ConicTo(DlPoint(150, 240), DlPoint(250, 140), 0.5f),
          TestPathElement::CubicTo(DlPoint(300, 300), DlPoint(350, 300),
                                   DlPoint(300, 350)),
          // Closing LineTo added implicitly to return to first point
          TestPathElement::LineTo(DlPoint(100, 200)),
          TestPathElement::Close(),
      });

  DlPath(path_builder, DlPathFillType::kNonZero).Dispatch(receiver);
  receiver.CheckComplete();
}

TEST(DisplayListPath, DispatchImpellerPathConvexUnspecified) {
  DlPathBuilder path_builder;

  // Keep it simple - a triangle is obviously convex
  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.LineTo(DlPoint(200, 200));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.Close();

  TestPathReceiver receiver(
      /* expected_fill_type   = */ DlPathFillType::kNonZero,
      /* expected_verb_count  = */ 5u,
      /* expected_point_count = */ 10u,
      /* expected_bounds      = */ DlRect::MakeLTRB(100, 200, 200, 300),
      /* expected_is_convex   = */ false,  // Conservatively false by default
      std::vector<TestPathElement>{
          TestPathElement::MoveTo(DlPoint(100, 200)),
          TestPathElement::LineTo(DlPoint(200, 200)),
          TestPathElement::LineTo(DlPoint(100, 300)),
          // Closing LineTo added implicitly to return to first point
          TestPathElement::LineTo(DlPoint(100, 200)),
          TestPathElement::Close(),
      });

  DlPath(path_builder, DlPathFillType::kNonZero).Dispatch(receiver);
  receiver.CheckComplete();
}

TEST(DisplayListPath, DispatchImpellerPathConvexSpecified) {
  DlPathBuilder path_builder;

  // Keep it simple - a triangle is obviously convex
  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.LineTo(DlPoint(200, 200));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.Close();
  path_builder.SetConvexity(impeller::Convexity::kConvex);

  TestPathReceiver receiver(
      /* expected_fill_type   = */ DlPathFillType::kNonZero,
      /* expected_verb_count  = */ 5u,
      /* expected_point_count = */ 10u,
      /* expected_bounds      = */ DlRect::MakeLTRB(100, 200, 200, 300),
      /* expected_is_convex   = */ true,  // Set manually above
      std::vector<TestPathElement>{
          TestPathElement::MoveTo(DlPoint(100, 200)),
          TestPathElement::LineTo(DlPoint(200, 200)),
          TestPathElement::LineTo(DlPoint(100, 300)),
          // Closing LineTo added implicitly to return to first point
          TestPathElement::LineTo(DlPoint(100, 200)),
          TestPathElement::Close(),
      });

  DlPath(path_builder, DlPathFillType::kNonZero).Dispatch(receiver);
  receiver.CheckComplete();
}

#ifndef NDEBUG
// Tests that verify we don't try to use inverse path modes as they aren't
// supported by either Flutter public APIs or Impeller

TEST(DisplayListPath, CannotConstructFromSkiaInverseWinding) {
  SkPath sk_path;
  sk_path.setFillType(SkPathFillType::kInverseWinding);
  sk_path.moveTo(0, 0);
  sk_path.lineTo(100, 0);
  sk_path.lineTo(0, 100);
  sk_path.close();

  EXPECT_DEATH_IF_SUPPORTED(new DlPath(sk_path), "SkPathFillType_IsInverse");
}

TEST(DisplayListPath, CannotConstructFromSkiaInverseEvenOdd) {
  SkPath sk_path;
  sk_path.setFillType(SkPathFillType::kInverseEvenOdd);
  sk_path.moveTo(0, 0);
  sk_path.lineTo(100, 0);
  sk_path.lineTo(0, 100);
  sk_path.close();

  EXPECT_DEATH_IF_SUPPORTED(new DlPath(sk_path), "SkPathFillType_IsInverse");
}
#endif

}  // namespace testing
}  // namespace flutter
