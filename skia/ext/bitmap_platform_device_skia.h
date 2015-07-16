// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_BITMAP_PLATFORM_DEVICE_SKIA_H_
#define SKIA_EXT_BITMAP_PLATFORM_DEVICE_SKIA_H_

#include "base/compiler_specific.h"
#include "base/memory/ref_counted.h"
#include "skia/ext/platform_device.h"

namespace skia {

// -----------------------------------------------------------------------------
// For now we just use SkBitmap for SkBitmapDevice
//
// This is all quite ok for test_shell. In the future we will want to use
// shared memory between the renderer and the main process at least. In this
// case we'll probably create the buffer from a precreated region of memory.
// -----------------------------------------------------------------------------
class BitmapPlatformDevice : public SkBitmapDevice, public PlatformDevice {
 public:
  // Construct a BitmapPlatformDevice. |is_opaque| should be set if the caller
  // knows the bitmap will be completely opaque and allows some optimizations.
  // The bitmap is not initialized.
  static BitmapPlatformDevice* Create(int width, int height, bool is_opaque);

  // This doesn't take ownership of |data|. If |data| is null, the bitmap
  // is not initialized to 0.
  static BitmapPlatformDevice* Create(int width, int height, bool is_opaque,
                                      uint8_t* data);

  // Create a BitmapPlatformDevice from an already constructed bitmap;
  // you should probably be using Create(). This may become private later if
  // we ever have to share state between some native drawing UI and Skia, like
  // the Windows and Mac versions of this class do.
  explicit BitmapPlatformDevice(const SkBitmap& other);
  ~BitmapPlatformDevice() override;

  PlatformSurface BeginPlatformPaint() override;

 protected:
  SkBaseDevice* onCreateDevice(const CreateInfo&, const SkPaint*) override;

 private:
  DISALLOW_COPY_AND_ASSIGN(BitmapPlatformDevice);
};

}  // namespace skia

#endif  // SKIA_EXT_BITMAP_PLATFORM_DEVICE_SKIA_H_
