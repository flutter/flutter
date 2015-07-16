// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(awalker): clean up the const/non-const reference handling in this test

#include "skia/ext/platform_canvas.h"

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "build/build_config.h"
#include "skia/ext/platform_device.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkColorPriv.h"
#include "third_party/skia/include/core/SkPixelRef.h"

#if defined(OS_MACOSX)
#import <ApplicationServices/ApplicationServices.h>
#endif

#if !defined(OS_WIN)
#include <unistd.h>
#endif

namespace skia {

namespace {

bool IsOfColor(const SkBitmap& bitmap, int x, int y, uint32_t color) {
  // For masking out the alpha values.
  static uint32_t alpha_mask =
      static_cast<uint32_t>(SK_A32_MASK) << SK_A32_SHIFT;
  return (*bitmap.getAddr32(x, y) | alpha_mask) == (color | alpha_mask);
}

// Return true if the canvas is filled to canvas_color, and contains a single
// rectangle filled to rect_color. This function ignores the alpha channel,
// since Windows will sometimes clear the alpha channel when drawing, and we
// will fix that up later in cases it's necessary.
bool VerifyRect(const PlatformCanvas& canvas,
                uint32_t canvas_color, uint32_t rect_color,
                int x, int y, int w, int h) {
  SkBaseDevice* device = skia::GetTopDevice(canvas);
  const SkBitmap& bitmap = device->accessBitmap(false);
  SkAutoLockPixels lock(bitmap);

  for (int cur_y = 0; cur_y < bitmap.height(); cur_y++) {
    for (int cur_x = 0; cur_x < bitmap.width(); cur_x++) {
      if (cur_x >= x && cur_x < x + w &&
          cur_y >= y && cur_y < y + h) {
        // Inside the square should be rect_color
        if (!IsOfColor(bitmap, cur_x, cur_y, rect_color))
          return false;
      } else {
        // Outside the square should be canvas_color
        if (!IsOfColor(bitmap, cur_x, cur_y, canvas_color))
          return false;
      }
    }
  }
  return true;
}

#if !defined(OS_MACOSX)
// Return true if canvas has something that passes for a rounded-corner
// rectangle. Basically, we're just checking to make sure that the pixels in the
// middle are of rect_color and pixels in the corners are of canvas_color.
bool VerifyRoundedRect(const PlatformCanvas& canvas,
                       uint32_t canvas_color,
                       uint32_t rect_color,
                       int x,
                       int y,
                       int w,
                       int h) {
  SkBaseDevice* device = skia::GetTopDevice(canvas);
  const SkBitmap& bitmap = device->accessBitmap(false);
  SkAutoLockPixels lock(bitmap);

  // Check corner points first. They should be of canvas_color.
  if (!IsOfColor(bitmap, x, y, canvas_color)) return false;
  if (!IsOfColor(bitmap, x + w, y, canvas_color)) return false;
  if (!IsOfColor(bitmap, x, y + h, canvas_color)) return false;
  if (!IsOfColor(bitmap, x + w, y, canvas_color)) return false;

  // Check middle points. They should be of rect_color.
  if (!IsOfColor(bitmap, (x + w / 2), y, rect_color)) return false;
  if (!IsOfColor(bitmap, x, (y + h / 2), rect_color)) return false;
  if (!IsOfColor(bitmap, x + w, (y + h / 2), rect_color)) return false;
  if (!IsOfColor(bitmap, (x + w / 2), y + h, rect_color)) return false;

  return true;
}
#endif

// Checks whether there is a white canvas with a black square at the given
// location in pixels (not in the canvas coordinate system).
bool VerifyBlackRect(const PlatformCanvas& canvas, int x, int y, int w, int h) {
  return VerifyRect(canvas, SK_ColorWHITE, SK_ColorBLACK, x, y, w, h);
}

// Check that every pixel in the canvas is a single color.
bool VerifyCanvasColor(const PlatformCanvas& canvas, uint32_t canvas_color) {
  return VerifyRect(canvas, canvas_color, 0, 0, 0, 0, 0);
}

#if defined(OS_WIN)
void DrawNativeRect(PlatformCanvas& canvas, int x, int y, int w, int h) {
  skia::ScopedPlatformPaint scoped_platform_paint(&canvas);
  HDC dc = scoped_platform_paint.GetPlatformSurface();

  RECT inner_rc;
  inner_rc.left = x;
  inner_rc.top = y;
  inner_rc.right = x + w;
  inner_rc.bottom = y + h;
  FillRect(dc, &inner_rc, reinterpret_cast<HBRUSH>(GetStockObject(BLACK_BRUSH)));
}
#elif defined(OS_MACOSX)
void DrawNativeRect(PlatformCanvas& canvas, int x, int y, int w, int h) {
  skia::ScopedPlatformPaint scoped_platform_paint(&canvas);
  CGContextRef context = scoped_platform_paint.GetPlatformSurface();

  CGRect inner_rc = CGRectMake(x, y, w, h);
  // RGBA opaque black
  CGColorRef black = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
  CGContextSetFillColorWithColor(context, black);
  CGColorRelease(black);
  CGContextFillRect(context, inner_rc);
}
#else
void DrawNativeRect(PlatformCanvas& canvas, int x, int y, int w, int h) {
  NOTIMPLEMENTED();
}
#endif

// Clips the contents of the canvas to the given rectangle. This will be
// intersected with any existing clip.
void AddClip(PlatformCanvas& canvas, int x, int y, int w, int h) {
  SkRect rect;
  rect.set(SkIntToScalar(x), SkIntToScalar(y),
           SkIntToScalar(x + w), SkIntToScalar(y + h));
  canvas.clipRect(rect);
}

class LayerSaver {
 public:
  LayerSaver(PlatformCanvas& canvas, int x, int y, int w, int h)
      : canvas_(canvas),
        x_(x),
        y_(y),
        w_(w),
        h_(h) {
    SkRect bounds;
    bounds.set(SkIntToScalar(x_), SkIntToScalar(y_),
               SkIntToScalar(right()), SkIntToScalar(bottom()));
    canvas_.saveLayer(&bounds, NULL);
    canvas.clear(SkColorSetARGB(0, 0, 0, 0));
  }

  ~LayerSaver() {
    canvas_.restore();
  }

  int x() const { return x_; }
  int y() const { return y_; }
  int w() const { return w_; }
  int h() const { return h_; }

  // Returns the EXCLUSIVE far bounds of the layer.
  int right() const { return x_ + w_; }
  int bottom() const { return y_ + h_; }

 private:
  PlatformCanvas& canvas_;
  int x_, y_, w_, h_;
};

// Size used for making layers in many of the below tests.
const int kLayerX = 2;
const int kLayerY = 3;
const int kLayerW = 9;
const int kLayerH = 7;

// Size used by some tests to draw a rectangle inside the layer.
const int kInnerX = 4;
const int kInnerY = 5;
const int kInnerW = 2;
const int kInnerH = 3;

}

// This just checks that our checking code is working properly, it just uses
// regular skia primitives.
TEST(PlatformCanvas, SkLayer) {
  // Create the canvas initialized to opaque white.
  RefPtr<SkCanvas> canvas = AdoptRef(CreatePlatformCanvas(16, 16, true));
  canvas->drawColor(SK_ColorWHITE);

  // Make a layer and fill it completely to make sure that the bounds are
  // correct.
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    canvas->drawColor(SK_ColorBLACK);
  }
  EXPECT_TRUE(VerifyBlackRect(*canvas, kLayerX, kLayerY, kLayerW, kLayerH));
}

#if !defined(USE_AURA)  // http://crbug.com/154358

// Test native clipping.
TEST(PlatformCanvas, ClipRegion) {
  // Initialize a white canvas
  RefPtr<SkCanvas> canvas = AdoptRef(CreatePlatformCanvas(16, 16, true));
  canvas->drawColor(SK_ColorWHITE);
  EXPECT_TRUE(VerifyCanvasColor(*canvas, SK_ColorWHITE));

  // Test that initially the canvas has no clip region, by filling it
  // with a black rectangle.
  // Note: Don't use LayerSaver, since internally it sets a clip region.
  DrawNativeRect(*canvas, 0, 0, 16, 16);
  EXPECT_TRUE(VerifyCanvasColor(*canvas, SK_ColorBLACK));

  // Test that intersecting disjoint clip rectangles sets an empty clip region
  canvas->drawColor(SK_ColorWHITE);
  EXPECT_TRUE(VerifyCanvasColor(*canvas, SK_ColorWHITE));
  {
    LayerSaver layer(*canvas, 0, 0, 16, 16);
    AddClip(*canvas, 2, 3, 4, 5);
    AddClip(*canvas, 4, 9, 10, 10);
    DrawNativeRect(*canvas, 0, 0, 16, 16);
  }
  EXPECT_TRUE(VerifyCanvasColor(*canvas, SK_ColorWHITE));
}

#endif  // !defined(USE_AURA)

// Test the layers get filled properly by native rendering.
TEST(PlatformCanvas, FillLayer) {
  // Create the canvas initialized to opaque white.
  RefPtr<SkCanvas> canvas = AdoptRef(CreatePlatformCanvas(16, 16, true));

  // Make a layer and fill it completely to make sure that the bounds are
  // correct.
  canvas->drawColor(SK_ColorWHITE);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    DrawNativeRect(*canvas, 0, 0, 100, 100);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), 0, 0, 100, 100);
#endif
  }
  EXPECT_TRUE(VerifyBlackRect(*canvas, kLayerX, kLayerY, kLayerW, kLayerH));

  // Make a layer and fill it partially to make sure the translation is correct.
  canvas->drawColor(SK_ColorWHITE);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    DrawNativeRect(*canvas, kInnerX, kInnerY, kInnerW, kInnerH);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), kInnerX, kInnerY, kInnerW, kInnerH);
#endif
  }
  EXPECT_TRUE(VerifyBlackRect(*canvas, kInnerX, kInnerY, kInnerW, kInnerH));

  // Add a clip on the layer and fill to make sure clip is correct.
  canvas->drawColor(SK_ColorWHITE);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    canvas->save();
    AddClip(*canvas, kInnerX, kInnerY, kInnerW, kInnerH);
    DrawNativeRect(*canvas, 0, 0, 100, 100);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), kInnerX, kInnerY, kInnerW, kInnerH);
#endif
    canvas->restore();
  }
  EXPECT_TRUE(VerifyBlackRect(*canvas, kInnerX, kInnerY, kInnerW, kInnerH));

  // Add a clip and then make the layer to make sure the clip is correct.
  canvas->drawColor(SK_ColorWHITE);
  canvas->save();
  AddClip(*canvas, kInnerX, kInnerY, kInnerW, kInnerH);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    DrawNativeRect(*canvas, 0, 0, 100, 100);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), 0, 0, 100, 100);
#endif
  }
  canvas->restore();
  EXPECT_TRUE(VerifyBlackRect(*canvas, kInnerX, kInnerY, kInnerW, kInnerH));
}

#if !defined(USE_AURA)  // http://crbug.com/154358

// Test that translation + make layer works properly.
TEST(PlatformCanvas, TranslateLayer) {
  // Create the canvas initialized to opaque white.
  RefPtr<SkCanvas> canvas = AdoptRef(CreatePlatformCanvas(16, 16, true));

  // Make a layer and fill it completely to make sure that the bounds are
  // correct.
  canvas->drawColor(SK_ColorWHITE);
  canvas->save();
  canvas->translate(1, 1);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    DrawNativeRect(*canvas, 0, 0, 100, 100);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), 0, 0, 100, 100);
#endif
  }
  canvas->restore();
  EXPECT_TRUE(VerifyBlackRect(*canvas, kLayerX + 1, kLayerY + 1,
                              kLayerW, kLayerH));

  // Translate then make the layer.
  canvas->drawColor(SK_ColorWHITE);
  canvas->save();
  canvas->translate(1, 1);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    DrawNativeRect(*canvas, kInnerX, kInnerY, kInnerW, kInnerH);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), kInnerX, kInnerY, kInnerW, kInnerH);
#endif
  }
  canvas->restore();
  EXPECT_TRUE(VerifyBlackRect(*canvas, kInnerX + 1, kInnerY + 1,
                              kInnerW, kInnerH));

  // Make the layer then translate.
  canvas->drawColor(SK_ColorWHITE);
  canvas->save();
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    canvas->translate(1, 1);
    DrawNativeRect(*canvas, kInnerX, kInnerY, kInnerW, kInnerH);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), kInnerX, kInnerY, kInnerW, kInnerH);
#endif
  }
  canvas->restore();
  EXPECT_TRUE(VerifyBlackRect(*canvas, kInnerX + 1, kInnerY + 1,
                              kInnerW, kInnerH));

  // Translate both before and after, and have a clip.
  canvas->drawColor(SK_ColorWHITE);
  canvas->save();
  canvas->translate(1, 1);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    canvas->drawColor(SK_ColorWHITE);
    canvas->translate(1, 1);
    AddClip(*canvas, kInnerX + 1, kInnerY + 1, kInnerW - 1, kInnerH - 1);
    DrawNativeRect(*canvas, 0, 0, 100, 100);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), kLayerX, kLayerY, kLayerW, kLayerH);
#endif
  }
  canvas->restore();
  EXPECT_TRUE(VerifyBlackRect(*canvas, kInnerX + 3, kInnerY + 3,
                              kInnerW - 1, kInnerH - 1));

// TODO(dglazkov): Figure out why this fails on Mac (antialiased clipping?),
// modify test and remove this guard.
#if !defined(OS_MACOSX)
  // Translate both before and after, and have a path clip.
  canvas->drawColor(SK_ColorWHITE);
  canvas->save();
  canvas->translate(1, 1);
  {
    LayerSaver layer(*canvas, kLayerX, kLayerY, kLayerW, kLayerH);
    canvas->drawColor(SK_ColorWHITE);
    canvas->translate(1, 1);

    SkPath path;
    SkRect rect;
    rect.iset(kInnerX - 1, kInnerY - 1,
              kInnerX + kInnerW, kInnerY + kInnerH);
    const SkScalar kRadius = 2.0;
    path.addRoundRect(rect, kRadius, kRadius);
    canvas->clipPath(path);

    DrawNativeRect(*canvas, 0, 0, 100, 100);
#if defined(OS_WIN)
    MakeOpaque(canvas.get(), kLayerX, kLayerY, kLayerW, kLayerH);
#endif
  }
  canvas->restore();
  EXPECT_TRUE(VerifyRoundedRect(*canvas, SK_ColorWHITE, SK_ColorBLACK,
                                kInnerX + 1, kInnerY + 1, kInnerW, kInnerH));
#endif
}

#endif  // #if !defined(USE_AURA)

TEST(PlatformBitmapTest, PlatformBitmap) {
  const int kWidth = 400;
  const int kHeight = 300;
  scoped_ptr<PlatformBitmap> platform_bitmap(new PlatformBitmap);

  EXPECT_TRUE(0 == platform_bitmap->GetSurface());
  EXPECT_TRUE(platform_bitmap->GetBitmap().empty());
  EXPECT_TRUE(platform_bitmap->GetBitmap().isNull());

  EXPECT_TRUE(platform_bitmap->Allocate(kWidth, kHeight, /*is_opaque=*/false));

  EXPECT_TRUE(0 != platform_bitmap->GetSurface());
  EXPECT_FALSE(platform_bitmap->GetBitmap().empty());
  EXPECT_FALSE(platform_bitmap->GetBitmap().isNull());
  EXPECT_EQ(kWidth, platform_bitmap->GetBitmap().width());
  EXPECT_EQ(kHeight, platform_bitmap->GetBitmap().height());
  EXPECT_LE(static_cast<size_t>(platform_bitmap->GetBitmap().width()*4),
            platform_bitmap->GetBitmap().rowBytes());
  EXPECT_EQ(kN32_SkColorType,  // Same for all platforms.
            platform_bitmap->GetBitmap().colorType());
  EXPECT_TRUE(platform_bitmap->GetBitmap().lockPixelsAreWritable());
#if defined(SK_DEBUG)
  EXPECT_TRUE(platform_bitmap->GetBitmap().pixelRef()->isLocked());
#endif
  EXPECT_TRUE(platform_bitmap->GetBitmap().pixelRef()->unique());

  *(platform_bitmap->GetBitmap().getAddr32(10, 20)) = 0xDEED1020;
  *(platform_bitmap->GetBitmap().getAddr32(20, 30)) = 0xDEED2030;

  SkBitmap sk_bitmap = platform_bitmap->GetBitmap();
  sk_bitmap.lockPixels();

  EXPECT_FALSE(platform_bitmap->GetBitmap().pixelRef()->unique());
  EXPECT_FALSE(sk_bitmap.pixelRef()->unique());

  EXPECT_EQ(0xDEED1020, *sk_bitmap.getAddr32(10, 20));
  EXPECT_EQ(0xDEED2030, *sk_bitmap.getAddr32(20, 30));

  *(platform_bitmap->GetBitmap().getAddr32(30, 40)) = 0xDEED3040;

  // The SkBitmaps derived from a PlatformBitmap must be capable of outliving
  // the PlatformBitmap.
  platform_bitmap.reset();

  EXPECT_TRUE(sk_bitmap.pixelRef()->unique());

  EXPECT_EQ(0xDEED1020, *sk_bitmap.getAddr32(10, 20));
  EXPECT_EQ(0xDEED2030, *sk_bitmap.getAddr32(20, 30));
  EXPECT_EQ(0xDEED3040, *sk_bitmap.getAddr32(30, 40));
  sk_bitmap.unlockPixels();

  EXPECT_EQ(NULL, sk_bitmap.getPixels());

  sk_bitmap.lockPixels();
  EXPECT_EQ(0xDEED1020, *sk_bitmap.getAddr32(10, 20));
  EXPECT_EQ(0xDEED2030, *sk_bitmap.getAddr32(20, 30));
  EXPECT_EQ(0xDEED3040, *sk_bitmap.getAddr32(30, 40));
  sk_bitmap.unlockPixels();
}


}  // namespace skia
