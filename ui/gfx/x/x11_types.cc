// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/x/x11_types.h"

#include <X11/Xlib.h>

#include "base/command_line.h"
#include "base/message_loop/message_loop.h"
#include "ui/gfx/x/x11_switches.h"

namespace gfx {

XDisplay* GetXDisplay() {
  static XDisplay* display = NULL;
  if (!display)
    display = OpenNewXDisplay();
  return display;
}

XDisplay* OpenNewXDisplay() {
#if defined(OS_CHROMEOS)
  return XOpenDisplay(NULL);
#else
  std::string display_str = base::CommandLine::ForCurrentProcess()->
                            GetSwitchValueASCII(switches::kX11Display);
  return XOpenDisplay(display_str.empty() ? NULL : display_str.c_str());
#endif
}

void PutARGBImage(XDisplay* display,
                  void* visual, int depth,
                  XID pixmap, void* pixmap_gc,
                  const uint8* data,
                  int width, int height) {
  PutARGBImage(display,
               visual, depth,
               pixmap, pixmap_gc,
               data, width, height,
               0, 0, // src_x, src_y
               0, 0, // dst_x, dst_y
               width, height);
}

int BitsPerPixelForPixmapDepth(XDisplay* dpy, int depth) {
  int count;
  XPixmapFormatValues* formats = XListPixmapFormats(dpy, &count);
  if (!formats)
    return -1;

  int bits_per_pixel = -1;
  for (int i = 0; i < count; ++i) {
    if (formats[i].depth == depth) {
      bits_per_pixel = formats[i].bits_per_pixel;
      break;
    }
  }

  XFree(formats);
  return bits_per_pixel;
}

void PutARGBImage(XDisplay* display,
                  void* visual, int depth,
                  XID pixmap, void* pixmap_gc,
                  const uint8* data,
                  int data_width, int data_height,
                  int src_x, int src_y,
                  int dst_x, int dst_y,
                  int copy_width, int copy_height) {
  // TODO(scherkus): potential performance impact... consider passing in as a
  // parameter.
  int pixmap_bpp = BitsPerPixelForPixmapDepth(display, depth);

  XImage image;
  memset(&image, 0, sizeof(image));

  image.width = data_width;
  image.height = data_height;
  image.format = ZPixmap;
  image.byte_order = LSBFirst;
  image.bitmap_unit = 8;
  image.bitmap_bit_order = LSBFirst;
  image.depth = depth;
  image.bits_per_pixel = pixmap_bpp;
  image.bytes_per_line = data_width * pixmap_bpp / 8;

  if (pixmap_bpp == 32) {
    image.red_mask = 0xff0000;
    image.green_mask = 0xff00;
    image.blue_mask = 0xff;

    // If the X server depth is already 32-bits and the color masks match,
    // then our job is easy.
    Visual* vis = static_cast<Visual*>(visual);
    if (image.red_mask == vis->red_mask &&
        image.green_mask == vis->green_mask &&
        image.blue_mask == vis->blue_mask) {
      image.data = const_cast<char*>(reinterpret_cast<const char*>(data));
      XPutImage(display, pixmap, static_cast<GC>(pixmap_gc), &image,
                src_x, src_y, dst_x, dst_y,
                copy_width, copy_height);
    } else {
      // Otherwise, we need to shuffle the colors around. Assume red and blue
      // need to be swapped.
      //
      // It's possible to use some fancy SSE tricks here, but since this is the
      // slow path anyway, we do it slowly.

      uint8_t* bitmap32 =
          static_cast<uint8_t*>(malloc(4 * data_width * data_height));
      if (!bitmap32)
        return;
      uint8_t* const orig_bitmap32 = bitmap32;
      const uint32_t* bitmap_in = reinterpret_cast<const uint32_t*>(data);
      for (int y = 0; y < data_height; ++y) {
        for (int x = 0; x < data_width; ++x) {
          const uint32_t pixel = *(bitmap_in++);
          bitmap32[0] = (pixel >> 16) & 0xff;  // Red
          bitmap32[1] = (pixel >> 8) & 0xff;   // Green
          bitmap32[2] = pixel & 0xff;          // Blue
          bitmap32[3] = (pixel >> 24) & 0xff;  // Alpha
          bitmap32 += 4;
        }
      }
      image.data = reinterpret_cast<char*>(orig_bitmap32);
      XPutImage(display, pixmap, static_cast<GC>(pixmap_gc), &image,
                src_x, src_y, dst_x, dst_y,
                copy_width, copy_height);
      free(orig_bitmap32);
    }
  } else if (pixmap_bpp == 16) {
    // Some folks have VNC setups which still use 16-bit visuals and VNC
    // doesn't include Xrender.

    uint16_t* bitmap16 =
        static_cast<uint16_t*>(malloc(2 * data_width * data_height));
    if (!bitmap16)
      return;
    uint16_t* const orig_bitmap16 = bitmap16;
    const uint32_t* bitmap_in = reinterpret_cast<const uint32_t*>(data);
    for (int y = 0; y < data_height; ++y) {
      for (int x = 0; x < data_width; ++x) {
        const uint32_t pixel = *(bitmap_in++);
        uint16_t out_pixel = ((pixel >> 8) & 0xf800) |
                             ((pixel >> 5) & 0x07e0) |
                             ((pixel >> 3) & 0x001f);
        *(bitmap16++) = out_pixel;
      }
    }

    image.data = reinterpret_cast<char*>(orig_bitmap16);
    image.red_mask = 0xf800;
    image.green_mask = 0x07e0;
    image.blue_mask = 0x001f;

    XPutImage(display, pixmap, static_cast<GC>(pixmap_gc), &image,
              src_x, src_y, dst_x, dst_y,
              copy_width, copy_height);
    free(orig_bitmap16);
  } else {
    LOG(FATAL) << "Sorry, we don't support your visual depth without "
                  "Xrender support (depth:" << depth
               << " bpp:" << pixmap_bpp << ")";
  }
}

}  // namespace gfx

