// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path.h"

#include "gtest/gtest.h"

#include "flutter/display_list/testing/dl_test_mock_path_receiver.h"
#include "flutter/third_party/skia/include/core/SkPath.h"
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

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsVolatile());

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
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

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
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

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_FALSE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
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

  EXPECT_EQ(path2.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path2.IsConvex());
  EXPECT_EQ(path2.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_FALSE(path2.IsRect(nullptr));
  EXPECT_FALSE(path2.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_TRUE(path2.IsOval(nullptr));
  EXPECT_FALSE(path2.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path2.IsRect(nullptr));
  EXPECT_FALSE(path2.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_TRUE(path2.IsOval(nullptr));
  EXPECT_FALSE(path2.IsRoundRect(nullptr));

  EXPECT_EQ(path2.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
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
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
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
      EXPECT_FALSE(path_.IsRect(nullptr)) << label;
      EXPECT_FALSE(path_.IsRect(nullptr, &is_closed)) << label;
      EXPECT_FALSE(is_closed) << label;
      EXPECT_TRUE(path_.IsOval(nullptr)) << label;
      EXPECT_FALSE(path_.IsRoundRect(nullptr)) << label;

      EXPECT_EQ(path_.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20)) << label;
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

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_TRUE(path.IsRect(nullptr));
  DlRect dl_rect;
  EXPECT_TRUE(path.IsRect(&dl_rect, &is_closed));
  EXPECT_EQ(dl_rect, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
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

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_TRUE(path.IsRect(nullptr));
  DlRect dl_rect;
  EXPECT_TRUE(path.IsRect(&dl_rect, &is_closed));
  EXPECT_EQ(dl_rect, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromOval) {
  SkPath sk_path = SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath(SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20))));
  EXPECT_EQ(path.GetSkPath(), SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20)));

  EXPECT_FALSE(path.IsConverted());
  EXPECT_FALSE(path.GetPath().IsEmpty());
  EXPECT_TRUE(path.IsConverted());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_TRUE(path.IsOval(nullptr));
  DlRect dl_bounds;
  EXPECT_TRUE(path.IsOval(&dl_bounds));
  EXPECT_EQ(dl_bounds, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
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

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  // Skia path, used for these tests,  doesn't recognize ovals created
  // by PathBuilder
  EXPECT_FALSE(path.IsRect(nullptr));
  // EXPECT_TRUE(path.IsOval(nullptr));
  // DlRect dl_bounds;
  // EXPECT_TRUE(path.IsOval(&dl_bounds));
  // EXPECT_EQ(dl_bounds, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
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

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  DlRoundRect roundrect;
  EXPECT_TRUE(path.IsRoundRect(&roundrect));
  EXPECT_EQ(roundrect,
            DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
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

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  // Skia path, used for these tests,  doesn't recognize ovals created
  // by PathBuilder
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  // DlRoundRect roundrect;
  // EXPECT_TRUE(path.IsRoundRect(&roundrect));
  // EXPECT_EQ(roundrect,
  //           DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
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

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
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

TEST(DisplayListPath, SkiaToImpellerFillTypeOddAndConvexityTrue) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.setFillType(SkPathFillType::kEvenOdd);

  ASSERT_TRUE(sk_path.isConvex());
  ASSERT_EQ(sk_path.getFillType(), SkPathFillType::kEvenOdd);

  DlPath path(sk_path);
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kOdd);
  EXPECT_TRUE(path.GetPath().IsConvex());
  EXPECT_EQ(path.GetPath().GetFillType(), DlPathFillType::kOdd);
}

TEST(DisplayListPath, SkiaToImpellerFillTypeWindingAndConvexityFalse) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.lineTo(20, 20);
  sk_path.setFillType(SkPathFillType::kWinding);

  ASSERT_FALSE(sk_path.isConvex());
  ASSERT_EQ(sk_path.getFillType(), SkPathFillType::kWinding);

  DlPath path(sk_path);
  EXPECT_FALSE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);
  EXPECT_FALSE(path.GetPath().IsConvex());
  EXPECT_EQ(path.GetPath().GetFillType(), DlPathFillType::kNonZero);
}

TEST(DisplayListPath, ImpellerToSkiaFillTypeOddAndConvexityTrue) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.SetConvexity(impeller::Convexity::kConvex);
  auto impeller_path = path_builder.TakePath(DlPathFillType::kOdd);

  ASSERT_TRUE(impeller_path.IsConvex());
  ASSERT_EQ(impeller_path.GetFillType(), DlPathFillType::kOdd);

  DlPath path(impeller_path);
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kOdd);
  EXPECT_TRUE(path.GetSkPath().isConvex());
  EXPECT_EQ(path.GetSkPath().getFillType(), SkPathFillType::kEvenOdd);
}

TEST(DisplayListPath, ImpellerToSkiaFillTypeWindingAndConvexityFalse) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.LineTo({20, 20});
  path_builder.SetConvexity(impeller::Convexity::kUnknown);
  auto impeller_path = path_builder.TakePath(DlPathFillType::kNonZero);

  ASSERT_FALSE(impeller_path.IsConvex());
  ASSERT_EQ(impeller_path.GetFillType(), DlPathFillType::kNonZero);

  DlPath path(impeller_path);
  EXPECT_FALSE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);
  EXPECT_FALSE(path.GetSkPath().isConvex());
  EXPECT_EQ(path.GetSkPath().getFillType(), SkPathFillType::kWinding);
}

TEST(DisplayListPath, IsLineFromSkPath) {
  SkPath sk_path;
  sk_path.moveTo(SkPoint::Make(0, 0));
  sk_path.lineTo(SkPoint::Make(100, 100));

  DlPath path = DlPath(sk_path);

  DlPoint start;
  DlPoint end;
  EXPECT_TRUE(path.IsLine(&start, &end));
  EXPECT_EQ(start, DlPoint::MakeXY(0, 0));
  EXPECT_EQ(end, DlPoint::MakeXY(100, 100));

  EXPECT_FALSE(DlPath(SkPath::Rect(SkRect::MakeLTRB(0, 0, 100, 100))).IsLine());
}

TEST(DisplayListPath, IsLineFromImpellerPath) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({0, 0});
  path_builder.LineTo({100, 0});
  DlPath path = DlPath(path_builder, DlPathFillType::kNonZero);

  DlPoint start;
  DlPoint end;
  EXPECT_TRUE(path.IsLine(&start, &end));
  EXPECT_EQ(start, DlPoint::MakeXY(0, 0));
  EXPECT_EQ(end, DlPoint::MakeXY(100, 0));

  {
    DlPathBuilder path_builder;
    path_builder.MoveTo({0, 0});
    path_builder.LineTo({100, 0});
    path_builder.LineTo({100, 100});

    DlPath path = DlPath(path_builder, DlPathFillType::kNonZero);
    EXPECT_FALSE(path.IsLine());
  }
}

namespace {
using ::testing::AtMost;
using ::testing::Return;
}  // namespace

static void TestPathDispatchOneOfEachVerb(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(100, 200), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(101, 201)));
    EXPECT_CALL(mock_receiver, QuadTo(DlPoint(110, 202), DlPoint(102, 210)));
    EXPECT_CALL(mock_receiver,
                ConicTo(DlPoint(150, 240), DlPoint(250, 140), 0.5f))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(DlPoint(300, 300), DlPoint(350, 300),
                                       DlPoint(300, 350)));
    // Closing LineTo added implicitly to return to first point
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(100, 200)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchSkiaPathOneOfEachVerb) {
  SkPath path;

  path.moveTo(100, 200);
  path.lineTo(101, 201);
  path.quadTo(110, 202, 102, 210);
  path.conicTo(150, 240, 250, 140, 0.5);
  path.cubicTo(300, 300, 350, 300, 300, 350);
  path.close();

  TestPathDispatchOneOfEachVerb(DlPath(path));
}

TEST(DisplayListPath, DispatchImpellerPathOneOfEachVerb) {
  DlPathBuilder path_builder;

  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.LineTo(DlPoint(101, 201));
  path_builder.QuadraticCurveTo(DlPoint(110, 202), DlPoint(102, 210));
  path_builder.ConicCurveTo(DlPoint(150, 240), DlPoint(250, 140), 0.5);
  path_builder.CubicCurveTo(DlPoint(300, 300), DlPoint(350, 300),
                            DlPoint(300, 350));
  path_builder.Close();

  TestPathDispatchOneOfEachVerb(DlPath(path_builder));
}

static void TestPathDispatchConicToQuads(const DlPath& path, DlScalar weight) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    std::array<DlPoint, 5> i_points;
    impeller::ConicPathComponent i_conic(DlPoint(10, 10), DlPoint(20, 10),
                                         DlPoint(20, 20), weight);
    i_conic.SubdivideToQuadraticPoints(i_points);

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver,
                ConicTo(DlPoint(20, 10), DlPoint(20, 20), weight))
        .WillOnce(Return(false));
    EXPECT_CALL(mock_receiver, QuadTo(i_points[1], i_points[2]));
    EXPECT_CALL(mock_receiver, QuadTo(i_points[3], i_points[4]));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

static void TestSkiaPathDispatchConicToQuads(DlScalar weight) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.conicTo(20, 10, 20, 20, weight);

  TestPathDispatchConicToQuads(DlPath(sk_path), weight);
}

static void TestImpellerPathDispatchConicToQuads(DlScalar weight) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(10, 10));
  path_builder.ConicCurveTo(DlPoint(20, 10), DlPoint(20, 20), weight);

  TestPathDispatchConicToQuads(DlPath(path_builder), weight);
}

TEST(DisplayListPath, DispatchSkiaPathConicToQuadsNearlyZero) {
  TestSkiaPathDispatchConicToQuads(kEhCloseEnough);
}
TEST(DisplayListPath, DispatchSkiaPathConicToQuadsHalf) {
  TestSkiaPathDispatchConicToQuads(0.5f);
}
TEST(DisplayListPath, DispatchSkiaPathConicToQuadsCircular) {
  TestSkiaPathDispatchConicToQuads(impeller::kSqrt2Over2);
}
TEST(DisplayListPath, DispatchSkiaPathConicToQuadsNearlyOne) {
  TestSkiaPathDispatchConicToQuads(1.0f - kEhCloseEnough);
}

TEST(DisplayListPath, DispatchImpellerPathConicToQuadsNearlyZero) {
  TestImpellerPathDispatchConicToQuads(kEhCloseEnough);
}
TEST(DisplayListPath, DispatchImpellerPathConicToQuadsHalf) {
  TestImpellerPathDispatchConicToQuads(0.5f);
}
TEST(DisplayListPath, DispatchImpellerPathConicToQuadsCircular) {
  TestImpellerPathDispatchConicToQuads(impeller::kSqrt2Over2);
}
TEST(DisplayListPath, DispatchImpellerPathConicToQuadsNearlyOne) {
  TestImpellerPathDispatchConicToQuads(1.0f - kEhCloseEnough);
}

static void TestPathDispatchUnclosedTriangle(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchUnclosedSkiaTriangle) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);

  TestPathDispatchUnclosedTriangle(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchUnclosedImpellerTriangle) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});

  TestPathDispatchUnclosedTriangle(DlPath(path_builder));
}

static void TestPathDispatchClosedTriangle(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 10)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchClosedSkiaTriangle) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.close();

  TestPathDispatchClosedTriangle(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchClosedImpellerTriangle) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.Close();
  path_builder.SetConvexity(impeller::Convexity::kConvex);

  TestPathDispatchClosedTriangle(DlPath(path_builder));
}

static void TestPathDispatchMixedCloseTriangles(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(110, 10), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(120, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(110, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(110, 10)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(210, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(220, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(210, 20)));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchMixedCloseSkiaPath) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.moveTo(110, 10);
  sk_path.lineTo(120, 10);
  sk_path.lineTo(110, 20);
  sk_path.close();
  sk_path.moveTo(210, 10);
  sk_path.lineTo(220, 10);
  sk_path.lineTo(210, 20);

  TestPathDispatchMixedCloseTriangles(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchMixedCloseImpellerPath) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.MoveTo({110, 10});
  path_builder.LineTo({120, 10});
  path_builder.LineTo({110, 20});
  path_builder.Close();
  path_builder.MoveTo({210, 10});
  path_builder.LineTo({220, 10});
  path_builder.LineTo({210, 20});

  TestPathDispatchMixedCloseTriangles(DlPath(path_builder));
}

static void TestPathDispatchImplicitMoveAfterClose(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 10)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(-20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, -20)));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchImplicitMoveAfterCloseSkiaPath) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.close();
  sk_path.lineTo(-20, 10);
  sk_path.lineTo(10, -20);

  TestPathDispatchImplicitMoveAfterClose(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchImplicitMoveAfterCloseImpellerPath) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.Close();
  path_builder.LineTo({-20, 10});
  path_builder.LineTo({10, -20});
  path_builder.SetConvexity(impeller::Convexity::kUnknown);

  TestPathDispatchImplicitMoveAfterClose(DlPath(path_builder));
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
