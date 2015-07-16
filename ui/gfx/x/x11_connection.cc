// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/x/x11_connection.h"

#include <X11/Xlib.h>

#include "ui/gfx/x/x11_types.h"

namespace gfx {

bool InitializeThreadedX11() {
  return XInitThreads() && gfx::GetXDisplay();
}

}  // namespace gfx
