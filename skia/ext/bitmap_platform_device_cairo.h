// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_BITMAP_PLATFORM_DEVICE_CAIRO_H_
#define SKIA_EXT_BITMAP_PLATFORM_DEVICE_CAIRO_H_

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/memory/ref_counted.h"
#include "skia/ext/platform_device.h"

typedef struct _cairo_surface cairo_surface_t;

// -----------------------------------------------------------------------------
// Image byte ordering on Linux:
//
// Pixels are packed into 32-bit words these days. Even for 24-bit images,
// often 8-bits will be left unused for alignment reasons. Thus, when you see
// ARGB as the byte order you have to wonder if that's in memory order or
// little-endian order. Here I'll write A.R.G.B to specifiy the memory order.
//
// GdkPixbuf's provide a nice backing store and defaults to R.G.B.A order.
// They'll do the needed byte swapping to match the X server when drawn.
//
// Skia can be controled in skia/include/corecg/SkUserConfig.h (see bits about
// SK_R32_SHIFT). For Linux we define it to be ARGB in registers. For little
// endian machines that means B.G.R.A in memory.
//
// The image loaders are controlled in
// webkit/port/platform/image-decoders/ImageDecoder.h (see setRGBA). These are
// also configured for ARGB in registers.
//
// Cairo's only 32-bit mode is ARGB in registers.
//
// X servers commonly have a 32-bit visual with xRGB in registers (since they
// typically don't do alpha blending of drawables at the user level. Composite
// extensions aside.)
//
// We don't use GdkPixbuf because its byte order differs from the rest. Most
// importantly, it differs from Cairo which, being a system library, is
// something that we can't easily change.
// -----------------------------------------------------------------------------

namespace skia {

// -----------------------------------------------------------------------------
// This is the Linux bitmap backing for Skia. We create a Cairo image surface
// to store the backing buffer. This buffer is BGRA in memory (on little-endian
// machines).
//
// For now we are also using Cairo to paint to the Drawables so we provide an
// accessor for getting the surface.
//
// This is all quite ok for test_shell. In the future we will want to use
// shared memory between the renderer and the main process at least. In this
// case we'll probably create the buffer from a precreated region of memory.
// -----------------------------------------------------------------------------
class BitmapPlatformDevice : public SkBitmapDevice, public PlatformDevice {
 public:
  // Create a BitmapPlatformDeviceLinux from an already constructed bitmap;
  // you should probably be using Create(). This may become private later if
  // we ever have to share state between some native drawing UI and Skia, like
  // the Windows and Mac versions of this class do.
  //
  // This object takes ownership of @cairo.
  BitmapPlatformDevice(const SkBitmap& other, cairo_t* cairo);
  ~BitmapPlatformDevice() override;

  // Constructs a device with size |width| * |height| with contents initialized
  // to zero. |is_opaque| should be set if the caller knows the bitmap will be
  // completely opaque and allows some optimizations.
  static BitmapPlatformDevice* Create(int width, int height, bool is_opaque);

  // Performs the same construction as Create.
  // Other ports require a separate construction routine because Create does not
  // initialize the bitmap to 0.
  static BitmapPlatformDevice* CreateAndClear(int width, int height,
                                              bool is_opaque);

  // This doesn't take ownership of |data|. If |data| is NULL, the contents
  // of the device are initialized to 0.
  static BitmapPlatformDevice* Create(int width, int height, bool is_opaque,
                                      uint8_t* data);

  // Overridden from SkBaseDevice:
  void setMatrixClip(const SkMatrix& transform,
                     const SkRegion& region,
                     const SkClipStack&) override;

  // Overridden from PlatformDevice:
  cairo_t* BeginPlatformPaint() override;

 protected:
  SkBaseDevice* onCreateDevice(const CreateInfo&, const SkPaint*) override;

 private:
  static BitmapPlatformDevice* Create(int width, int height, bool is_opaque,
                                      cairo_surface_t* surface);

  // Sets the transform and clip operations. This will not update the Cairo
  // context, but will mark the config as dirty. The next call of LoadConfig
  // will pick up these changes.
  void SetMatrixClip(const SkMatrix& transform, const SkRegion& region);

  // Loads the current transform and clip into the context.
  void LoadConfig();

  // Graphics context used to draw into the surface.
  cairo_t* cairo_;

  // True when there is a transform or clip that has not been set to the
  // context.  The context is retrieved for every text operation, and the
  // transform and clip do not change as much. We can save time by not loading
  // the clip and transform for every one.
  bool config_dirty_;

  // Translation assigned to the context: we need to keep track of this
  // separately so it can be updated even if the context isn't created yet.
  SkMatrix transform_;

  // The current clipping
  SkRegion clip_region_;

  DISALLOW_COPY_AND_ASSIGN(BitmapPlatformDevice);
};

}  // namespace skia

#endif  // SKIA_EXT_BITMAP_PLATFORM_DEVICE_CAIRO_H_
