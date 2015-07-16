// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/skia_utils_mac.h"

#import <AppKit/AppKit.h>

#include "base/mac/scoped_nsobject.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace {

class SkiaUtilsMacTest : public testing::Test {
 public:
  // Creates a red or blue bitmap.
  SkBitmap CreateSkBitmap(int width, int height, bool isred, bool tfbit);

  // Creates a red or blue image.
  NSImage* CreateNSImage(int width, int height, bool isred);

  // Checks that the given bitmap rep is actually red or blue.
  void TestImageRep(NSBitmapImageRep* imageRep, bool isred);

  // Checks that the given bitmap is actually red or blue.
  void TestSkBitmap(const SkBitmap& bitmap, bool isred);

  enum BitLockerTest {
    TestIdentity = 0,
    TestTranslate = 1,
    TestClip = 2,
    TestXClip = TestTranslate | TestClip,
    TestNoBits = 4,
    TestTranslateNoBits = TestTranslate | TestNoBits,
    TestClipNoBits = TestClip | TestNoBits,
    TestXClipNoBits = TestXClip | TestNoBits,
  };
  void RunBitLockerTest(BitLockerTest test);

  // If not red, is blue.
  // If not tfbit (twenty-four-bit), is 444.
  void ShapeHelper(int width, int height, bool isred, bool tfbit);
};

SkBitmap SkiaUtilsMacTest::CreateSkBitmap(int width, int height,
                                          bool isred, bool tfbit) {
  SkColorType ct = tfbit ? kN32_SkColorType : kARGB_4444_SkColorType;
  SkImageInfo info = SkImageInfo::Make(width, height, ct, kPremul_SkAlphaType);

  SkBitmap bitmap;
  bitmap.allocPixels(info);

  if (isred)
    bitmap.eraseARGB(0xff, 0xff, 0, 0);
  else
    bitmap.eraseARGB(0xff, 0, 0, 0xff);

  return bitmap;
}

NSImage* SkiaUtilsMacTest::CreateNSImage(int width, int height, bool isred) {
  base::scoped_nsobject<NSImage> image(
      [[NSImage alloc] initWithSize:NSMakeSize(width, height)]);
  [image lockFocus];
  if (isred)
    [[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0] set];
  else
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:1.0] set];
  NSRectFill(NSMakeRect(0, 0, width, height));
  [image unlockFocus];
  return [image.release() autorelease];
}

void SkiaUtilsMacTest::TestImageRep(NSBitmapImageRep* imageRep, bool isred) {
  // Get the color of a pixel and make sure it looks fine
  int x = [imageRep size].width > 17 ? 17 : 0;
  int y = [imageRep size].height > 17 ? 17 : 0;
  NSColor* color = [imageRep colorAtX:x y:y];
  CGFloat red = 0, green = 0, blue = 0, alpha = 0;

  // SkBitmapToNSImage returns a bitmap in the calibrated color space (sRGB),
  // while NSReadPixel returns a color in the device color space. Convert back
  // to the calibrated color space before testing.
  color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

  [color getRed:&red green:&green blue:&blue alpha:&alpha];

  // Be tolerant of floating point rounding and lossy color space conversions.
  if (isred) {
    EXPECT_GT(red, 0.95);
    EXPECT_LT(blue, 0.05);
  } else {
    EXPECT_LT(red, 0.05);
    EXPECT_GT(blue, 0.95);
  }
  EXPECT_LT(green, 0.05);
  EXPECT_GT(alpha, 0.95);
}

void SkiaUtilsMacTest::TestSkBitmap(const SkBitmap& bitmap, bool isred) {
  int x = bitmap.width() > 17 ? 17 : 0;
  int y = bitmap.height() > 17 ? 17 : 0;
  SkColor color = bitmap.getColor(x, y);

  if (isred) {
    EXPECT_EQ(255u, SkColorGetR(color));
    EXPECT_EQ(0u, SkColorGetB(color));
  } else {
    EXPECT_EQ(0u, SkColorGetR(color));
    EXPECT_EQ(255u, SkColorGetB(color));
  }
  EXPECT_EQ(0u, SkColorGetG(color));
  EXPECT_EQ(255u, SkColorGetA(color));
}

// setBitmapDevice has been deprecated/removed. Is this test still useful?
void SkiaUtilsMacTest::RunBitLockerTest(BitLockerTest test) {
  const unsigned width = 2;
  const unsigned height = 2;
  const unsigned storageSize = width * height;
  const unsigned original[] = {0xFF333333, 0xFF666666, 0xFF999999, 0xFFCCCCCC};
  EXPECT_EQ(storageSize, sizeof(original) / sizeof(original[0]));
  unsigned bits[storageSize];
  memcpy(bits, original, sizeof(original));
  SkImageInfo info = SkImageInfo::MakeN32Premul(width, height);
  SkBitmap bitmap;
  bitmap.installPixels(info, bits, info.minRowBytes());

  SkCanvas canvas(bitmap);
  if (test & TestTranslate)
    canvas.translate(width / 2, 0);
  if (test & TestClip) {
    SkRect clipRect = {0, height / 2, width, height};
    canvas.clipRect(clipRect);
  }
  {
    gfx::SkiaBitLocker bitLocker(&canvas);
    CGContextRef cgContext = bitLocker.cgContext();
    CGColorRef testColor = CGColorGetConstantColor(kCGColorWhite);
    CGContextSetFillColorWithColor(cgContext, testColor);
    CGRect cgRect = {{0, 0}, {width, height}};
    CGContextFillRect(cgContext, cgRect);
    if (test & TestNoBits) {
      if (test & TestClip) {
        SkRect clipRect = {0, height / 2, width, height};
        canvas.clipRect(clipRect);
      }
    }
  }
  const unsigned results[][storageSize] = {
    {0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF}, // identity
    {0xFF333333, 0xFFFFFFFF, 0xFF999999, 0xFFFFFFFF}, // translate
    {0xFF333333, 0xFF666666, 0xFFFFFFFF, 0xFFFFFFFF}, // clip
    {0xFF333333, 0xFF666666, 0xFF999999, 0xFFFFFFFF}  // translate | clip
  };
  for (unsigned index = 0; index < storageSize; index++)
    EXPECT_EQ(results[test & ~TestNoBits][index], bits[index]);
}

void SkiaUtilsMacTest::ShapeHelper(int width, int height,
                                   bool isred, bool tfbit) {
  SkBitmap thing(CreateSkBitmap(width, height, isred, tfbit));

  // Confirm size
  NSImage* image = gfx::SkBitmapToNSImage(thing);
  EXPECT_DOUBLE_EQ([image size].width, (double)width);
  EXPECT_DOUBLE_EQ([image size].height, (double)height);

  EXPECT_TRUE([[image representations] count] == 1);
  EXPECT_TRUE([[[image representations] lastObject]
      isKindOfClass:[NSBitmapImageRep class]]);
  TestImageRep([[image representations] lastObject], isred);
}

TEST_F(SkiaUtilsMacTest, BitmapToNSImage_RedSquare64x64) {
  ShapeHelper(64, 64, true, true);
}

TEST_F(SkiaUtilsMacTest, BitmapToNSImage_BlueRectangle199x19) {
  ShapeHelper(199, 19, false, true);
}

TEST_F(SkiaUtilsMacTest, BitmapToNSImage_BlueRectangle444) {
  ShapeHelper(200, 200, false, false);
}

TEST_F(SkiaUtilsMacTest, BitmapToNSBitmapImageRep_BlueRectangle20x30) {
  int width = 20;
  int height = 30;

  SkBitmap bitmap(CreateSkBitmap(width, height, false, true));
  NSBitmapImageRep* imageRep = gfx::SkBitmapToNSBitmapImageRep(bitmap);

  EXPECT_DOUBLE_EQ(width, [imageRep size].width);
  EXPECT_DOUBLE_EQ(height, [imageRep size].height);
  TestImageRep(imageRep, false);
}

TEST_F(SkiaUtilsMacTest, NSImageRepToSkBitmap) {
  int width = 10;
  int height = 15;
  bool isred = true;

  NSImage* image = CreateNSImage(width, height, isred);
  EXPECT_EQ(1u, [[image representations] count]);
  NSBitmapImageRep* imageRep = [[image representations] lastObject];
  NSColorSpace* colorSpace = [NSColorSpace deviceRGBColorSpace];
  SkBitmap bitmap(gfx::NSImageRepToSkBitmapWithColorSpace(
      imageRep, [image size], false, [colorSpace CGColorSpace]));
  TestSkBitmap(bitmap, isred);
}

TEST_F(SkiaUtilsMacTest, BitLocker_Identity) {
  RunBitLockerTest(SkiaUtilsMacTest::TestIdentity);
}

TEST_F(SkiaUtilsMacTest, BitLocker_Translate) {
  RunBitLockerTest(SkiaUtilsMacTest::TestTranslate);
}

TEST_F(SkiaUtilsMacTest, BitLocker_Clip) {
  RunBitLockerTest(SkiaUtilsMacTest::TestClip);
}

TEST_F(SkiaUtilsMacTest, BitLocker_XClip) {
  RunBitLockerTest(SkiaUtilsMacTest::TestXClip);
}

TEST_F(SkiaUtilsMacTest, BitLocker_NoBits) {
  RunBitLockerTest(SkiaUtilsMacTest::TestNoBits);
}

TEST_F(SkiaUtilsMacTest, BitLocker_TranslateNoBits) {
  RunBitLockerTest(SkiaUtilsMacTest::TestTranslateNoBits);
}

TEST_F(SkiaUtilsMacTest, BitLocker_ClipNoBits) {
  RunBitLockerTest(SkiaUtilsMacTest::TestClipNoBits);
}

TEST_F(SkiaUtilsMacTest, BitLocker_XClipNoBits) {
  RunBitLockerTest(SkiaUtilsMacTest::TestXClipNoBits);
}

}  // namespace

