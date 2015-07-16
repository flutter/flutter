// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_X_X11_CONNECTION_H_
#define UI_GFX_X_X11_CONNECTION_H_

#include "ui/gfx/gfx_export.h"

namespace gfx {

// Initializes thread support for X11, and opens a connection to the display.
// Return false if either fails, and true otherwise.
GFX_EXPORT bool InitializeThreadedX11();

}  // namespace gfx

#endif  // UI_GFX_X_X11_CONNECTION_H_
