// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/display_list/testing/dl_test_snippets.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

using ::testing::NiceMock;
using ::testing::Return;

class MockDlImageSkia : public DlImageSkia {
 public:
  MockDlImageSkia() : DlImageSkia(nullptr) {}

  MOCK_METHOD(sk_sp<SkImage>, skia_image, (), (const, override));
  MOCK_METHOD(DlImage::OwningContext, owning_context, (), (const, override));
};

sk_sp<NiceMock<MockDlImageSkia>> MakeRasterOwnedImage() {
  auto image = sk_make_sp<NiceMock<MockDlImageSkia>>();
  ON_CALL(*image, owning_context())
      .WillByDefault(Return(DlImage::OwningContext::kRaster));
  return image;
}

}  // namespace

TEST(DisplayListImage, EqualsComparesTheSkiaImagesOfImagesNotOwnedByRaster) {
  sk_sp<DlImage> image = MakeTestImage(10, 10, DlColor::kGreen());
  sk_sp<DlImage> same_skia_image =
      DlImageSkia::Make(image->asSkiaImage()->skia_image());
  sk_sp<DlImage> other_image = MakeTestImage(10, 10, DlColor::kGreen());

  ASSERT_NE(image.get(), same_skia_image.get());
  EXPECT_TRUE(image->Equals(image));
  EXPECT_TRUE(image->Equals(same_skia_image));
  EXPECT_TRUE(same_skia_image->Equals(image));
  EXPECT_FALSE(image->Equals(other_image));
  EXPECT_FALSE(image->Equals(nullptr));
}

// Regression test for https://github.com/flutter/flutter/issues/195888.
TEST(DisplayListImage, EqualsDoesNotAccessTheSkiaImageOfRasterOwnedImages) {
  auto image1 = MakeRasterOwnedImage();
  auto image2 = MakeRasterOwnedImage();
  sk_sp<DlImage> plain_image = MakeTestImage(10, 10, DlColor::kGreen());
  EXPECT_CALL(*image1, skia_image()).Times(0);
  EXPECT_CALL(*image2, skia_image()).Times(0);

  // Raster owned images have pointer equality.
  EXPECT_TRUE(image1->Equals(image1));
  EXPECT_FALSE(image1->Equals(image2));
  EXPECT_FALSE(image2->Equals(image1));

  // The raster owned image may be on either side of the comparison.
  EXPECT_FALSE(image1->Equals(plain_image));
  EXPECT_FALSE(plain_image->Equals(image1));
}

// Regression test for https://github.com/flutter/flutter/issues/195888.
//
// The builder compares the color source of each draw against the previous
// one, on the UI thread. For image color sources that compares the images.
// This test ensures that the builder does not access the SkImage of a raster
// owned image.
TEST(DisplayListImage, BuilderDoesNotAccessTheSkiaImageOfRasterOwnedImages) {
  auto image1 = MakeRasterOwnedImage();
  auto image2 = MakeRasterOwnedImage();
  EXPECT_CALL(*image1, skia_image()).Times(0);
  EXPECT_CALL(*image2, skia_image()).Times(0);
  DlPaint paint1;
  paint1.setColorSource(DlColorSource::MakeImage(image1, DlTileMode::kRepeat,
                                                 DlTileMode::kRepeat));
  DlPaint paint2;
  paint2.setColorSource(DlColorSource::MakeImage(image2, DlTileMode::kRepeat,
                                                 DlTileMode::kRepeat));
  DlPath path = DlPath::MakeOval(DlRect::MakeLTRB(0, 0, 90, 60));

  DisplayListBuilder builder;
  builder.DrawPath(path, paint1);
  builder.DrawPath(path, paint2);
  builder.DrawPath(path, paint1);
  sk_sp<DisplayList> display_list = builder.Build();

  EXPECT_NE(display_list, nullptr);
}

}  // namespace testing
}  // namespace flutter
