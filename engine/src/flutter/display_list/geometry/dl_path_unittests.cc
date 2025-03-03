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
