// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_X_X11_UTIL_H_
#define UI_GFX_X_X11_UTIL_H_

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "ui/gfx/gfx_export.h"

typedef unsigned long XAtom;
typedef unsigned long XID;
typedef struct _XImage XImage;
typedef struct _XGC *GC;
typedef struct _XDisplay XDisplay;

extern "C" {
int XFree(void*);
}

namespace gfx {

template <class T, class R, R (*F)(T*)>
struct XObjectDeleter {
  inline void operator()(void* ptr) const { F(static_cast<T*>(ptr)); }
};

template <class T, class D = XObjectDeleter<void, int, XFree>>
using XScopedPtr = scoped_ptr<T, D>;

// TODO(oshima|evan): This assume there is one display and doesn't work
// undef multiple displays/monitor environment. Remove this and change the
// chrome codebase to get the display from window.
GFX_EXPORT XDisplay* GetXDisplay();

// This opens a new X11 XDisplay*, taking command line arguments into account.
GFX_EXPORT XDisplay* OpenNewXDisplay();

// Return the number of bits-per-pixel for a pixmap of the given depth
GFX_EXPORT int BitsPerPixelForPixmapDepth(XDisplay* display, int depth);

// Draws ARGB data on the given pixmap using the given GC, converting to the
// server side visual depth as needed.  Destination is assumed to be the same
// dimensions as |data| or larger.  |data| is also assumed to be in row order
// with each line being exactly |width| * 4 bytes long.
GFX_EXPORT void PutARGBImage(XDisplay* display,
                             void* visual, int depth,
                             XID pixmap, void* pixmap_gc,
                             const uint8* data,
                             int width, int height);

// Same as above only more general:
// - |data_width| and |data_height| refer to the data image
// - |src_x|, |src_y|, |copy_width| and |copy_height| define source region
// - |dst_x|, |dst_y|, |copy_width| and |copy_height| define destination region
GFX_EXPORT void PutARGBImage(XDisplay* display,
                             void* visual, int depth,
                             XID pixmap, void* pixmap_gc,
                             const uint8* data,
                             int data_width, int data_height,
                             int src_x, int src_y,
                             int dst_x, int dst_y,
                             int copy_width, int copy_height);

}  // namespace gfx

#endif  // UI_GFX_X_X11_UTIL_H_

