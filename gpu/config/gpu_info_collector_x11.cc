// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <X11/Xlib.h>

#include "base/logging.h"
#include "gpu/config/gpu_info_collector_linux.h"
#include "third_party/libXNVCtrl/NVCtrl.h"
#include "third_party/libXNVCtrl/NVCtrlLib.h"
#include "ui/gfx/x/x11_types.h"

namespace gpu {

// Use NVCtrl extention to query NV driver version.
// Return empty string on failing.
std::string CollectDriverVersionNVidia() {
  Display* display = gfx::GetXDisplay();
  if (!display) {
    LOG(ERROR) << "XOpenDisplay failed.";
    return std::string();
  }
  int event_base = 0, error_base = 0;
  if (!XNVCTRLQueryExtension(display, &event_base, &error_base)) {
    VLOG(1) << "NVCtrl extension does not exist.";
    return std::string();
  }
  int screen_count = ScreenCount(display);
  for (int screen = 0; screen < screen_count; ++screen) {
    char* buffer = NULL;
    if (XNVCTRLIsNvScreen(display, screen) &&
        XNVCTRLQueryStringAttribute(display, screen, 0,
                                    NV_CTRL_STRING_NVIDIA_DRIVER_VERSION,
                                    &buffer)) {
      std::string driver_version(buffer);
      XFree(buffer);
      return driver_version;
    }
  }
  return std::string();
}

}  // namespace gpu
