// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_PLATFORM_CANVAS_H_
#define SKIA_EXT_PLATFORM_CANVAS_H_

// The platform-specific device will include the necessary platform headers
// to get the surface type.
#include "base/basictypes.h"
#include "skia/ext/platform_device.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPixelRef.h"

namespace skia {

typedef SkCanvas PlatformCanvas;

//
//  Note about error handling.
//
//  Creating a canvas can fail at times, most often because we fail to allocate
//  the backing-store (pixels). This can be from out-of-memory, or something
//  more opaque, like GDI or cairo reported a failure.
//
//  To allow the caller to handle the failure, every Create... factory takes an
//  enum as its last parameter. The default value is kCrashOnFailure. If the
//  caller passes kReturnNullOnFailure, then the caller is responsible to check
//  the return result.
//
enum OnFailureType {
  CRASH_ON_FAILURE,
  RETURN_NULL_ON_FAILURE
};

#if defined(WIN32)
  // The shared_section parameter is passed to gfx::PlatformDevice::create.
  // See it for details.
  SK_API SkCanvas* CreatePlatformCanvas(int width,
                                        int height,
                                        bool is_opaque,
                                        HANDLE shared_section,
                                        OnFailureType failure_type);

  // Draws the top layer of the canvas into the specified HDC. Only works
  // with a PlatformCanvas with a BitmapPlatformDevice.
  SK_API void DrawToNativeContext(SkCanvas* canvas,
                                  HDC hdc,
                                  int x,
                                  int y,
                                  const RECT* src_rect);
#elif defined(__APPLE__)
  SK_API SkCanvas* CreatePlatformCanvas(CGContextRef context,
                                        int width,
                                        int height,
                                        bool is_opaque,
                                        OnFailureType failure_type);

  SK_API SkCanvas* CreatePlatformCanvas(int width,
                                        int height,
                                        bool is_opaque,
                                        uint8_t* context,
                                        OnFailureType failure_type);
#elif defined(__linux__) || defined(__FreeBSD__) || defined(__OpenBSD__) || \
      defined(__sun) || defined(ANDROID)
  // Linux ---------------------------------------------------------------------

  // Construct a canvas from the given memory region. The memory is not cleared
  // first. @data must be, at least, @height * StrideForWidth(@width) bytes.
  SK_API SkCanvas* CreatePlatformCanvas(int width,
                                        int height,
                                        bool is_opaque,
                                        uint8_t* data,
                                        OnFailureType failure_type);
#endif

static inline SkCanvas* CreatePlatformCanvas(int width,
                                             int height,
                                             bool is_opaque) {
  return CreatePlatformCanvas(width, height, is_opaque, 0, CRASH_ON_FAILURE);
}

SK_API SkCanvas* CreateCanvas(const skia::RefPtr<SkBaseDevice>& device,
                              OnFailureType failure_type);

static inline SkCanvas* CreateBitmapCanvas(int width,
                                           int height,
                                           bool is_opaque) {
  return CreatePlatformCanvas(width, height, is_opaque, 0, CRASH_ON_FAILURE);
}

static inline SkCanvas* TryCreateBitmapCanvas(int width,
                                              int height,
                                              bool is_opaque) {
  return CreatePlatformCanvas(width, height, is_opaque, 0,
                              RETURN_NULL_ON_FAILURE);
}

// Return the stride (length of a line in bytes) for the given width. Because
// we use 32-bits per pixel, this will be roughly 4*width. However, for
// alignment reasons we may wish to increase that.
SK_API size_t PlatformCanvasStrideForWidth(unsigned width);

// Returns the SkBaseDevice pointer of the topmost rect with a non-empty
// clip. In practice, this is usually either the top layer or nothing, since
// we usually set the clip to new layers when we make them.
//
// This may return NULL, so callers need to check.
//
// This is different than SkCanvas' getDevice, because that returns the
// bottommost device.
//
// Danger: the resulting device should not be saved. It will be invalidated
// by the next call to save() or restore().
SK_API SkBaseDevice* GetTopDevice(const SkCanvas& canvas);

// Returns true if native platform routines can be used to draw on the
// given canvas. If this function returns false, BeginPlatformPaint will
// return NULL PlatformSurface.
SK_API bool SupportsPlatformPaint(const SkCanvas* canvas);

// Sets the opacity of each pixel in the specified region to be opaque.
SK_API void MakeOpaque(SkCanvas* canvas, int x, int y, int width, int height);

// These calls should surround calls to platform drawing routines, the
// surface returned here can be used with the native platform routines.
//
// Call EndPlatformPaint when you are done and want to use skia operations
// after calling the platform-specific BeginPlatformPaint; this will
// synchronize the bitmap to OS if necessary.
SK_API PlatformSurface BeginPlatformPaint(SkCanvas* canvas);
SK_API void EndPlatformPaint(SkCanvas* canvas);

// Helper class for pairing calls to BeginPlatformPaint and EndPlatformPaint.
// Upon construction invokes BeginPlatformPaint, and upon destruction invokes
// EndPlatformPaint.
class SK_API ScopedPlatformPaint {
 public:
  explicit ScopedPlatformPaint(SkCanvas* canvas) : canvas_(canvas) {
    platform_surface_ = BeginPlatformPaint(canvas);
  }
  ~ScopedPlatformPaint() { EndPlatformPaint(canvas_); }

  // Returns the PlatformSurface to use for native platform drawing calls.
  PlatformSurface GetPlatformSurface() { return platform_surface_; }
 private:
  SkCanvas* canvas_;
  PlatformSurface platform_surface_;

  // Disallow copy and assign
  ScopedPlatformPaint(const ScopedPlatformPaint&);
  ScopedPlatformPaint& operator=(const ScopedPlatformPaint&);
};

// PlatformBitmap holds a PlatformSurface that can also be used as an SkBitmap.
class SK_API PlatformBitmap {
 public:
  PlatformBitmap();
  ~PlatformBitmap();

  // Returns true if the bitmap was able to allocate its surface.
  bool Allocate(int width, int height, bool is_opaque);

  // Returns the platform surface, or 0 if Allocate() did not return true.
  PlatformSurface GetSurface() { return surface_; }

  // Return the skia bitmap, which will be empty if Allocate() did not
  // return true.
  //
  // The resulting SkBitmap holds a refcount on the underlying platform surface,
  // so the surface will remain allocated so long as the SkBitmap or its copies
  // stay around.
  const SkBitmap& GetBitmap() { return bitmap_; }

 private:
  SkBitmap bitmap_;
  PlatformSurface surface_;  // initialized to 0
  intptr_t platform_extra_;  // platform specific, initialized to 0

  DISALLOW_COPY_AND_ASSIGN(PlatformBitmap);
};

}  // namespace skia

#endif  // SKIA_EXT_PLATFORM_CANVAS_H_
