// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_BITMAP_PLATFORM_DEVICE_MAC_H_
#define SKIA_EXT_BITMAP_PLATFORM_DEVICE_MAC_H_

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "skia/ext/platform_device.h"
#include "skia/ext/refptr.h"

namespace skia {

// A device is basically a wrapper around SkBitmap that provides a surface for
// SkCanvas to draw into. Our device provides a surface CoreGraphics can also
// write to. BitmapPlatformDevice creates a bitmap using
// CGCreateBitmapContext() in a format that Skia supports and can then use this
// to draw text into, etc. This pixel data is provided to the bitmap that the
// device contains so that it can be shared.
//
// The device owns the pixel data, when the device goes away, the pixel data
// also becomes invalid. THIS IS DIFFERENT THAN NORMAL SKIA which uses
// reference counting for the pixel data. In normal Skia, you could assign
// another bitmap to this device's bitmap and everything will work properly.
// For us, that other bitmap will become invalid as soon as the device becomes
// invalid, which may lead to subtle bugs. Therefore, DO NOT ASSIGN THE
// DEVICE'S PIXEL DATA TO ANOTHER BITMAP, make sure you copy instead.
class SK_API BitmapPlatformDevice : public SkBitmapDevice, public PlatformDevice {
 public:
  // Creates a BitmapPlatformDevice instance. |is_opaque| should be set if the
  // caller knows the bitmap will be completely opaque and allows some
  // optimizations.
  // |context| may be NULL. If |context| is NULL, then the bitmap backing store
  // is not initialized.
  static BitmapPlatformDevice* Create(CGContextRef context,
                                      int width, int height,
                                      bool is_opaque, bool do_clear = false);

  // Creates a context for |data| and calls Create.
  // If |data| is NULL, then the bitmap backing store is not initialized.
  static BitmapPlatformDevice* CreateWithData(uint8_t* data,
                                              int width, int height,
                                              bool is_opaque);

  ~BitmapPlatformDevice() override;

  // PlatformDevice overrides
  CGContextRef GetBitmapContext() override;

  // SkBaseDevice overrides
  void setMatrixClip(const SkMatrix& transform,
                     const SkRegion& region,
                     const SkClipStack&) override;

 protected:
  BitmapPlatformDevice(CGContextRef context,
                       const SkBitmap& bitmap);

  SkBaseDevice* onCreateDevice(const CreateInfo&, const SkPaint*) override;

 private:
  void ReleaseBitmapContext();

  // Sets the transform and clip operations. This will not update the CGContext,
  // but will mark the config as dirty. The next call of LoadConfig will
  // pick up these changes.
  void SetMatrixClip(const SkMatrix& transform, const SkRegion& region);

  // Loads the current transform and clip into the context. Can be called even
  // when |bitmap_context_| is NULL (will be a NOP).
  void LoadConfig();

  // Lazily-created graphics context used to draw into the bitmap.
  CGContextRef bitmap_context_;

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

#endif  // SKIA_EXT_BITMAP_PLATFORM_DEVICE_MAC_H_
