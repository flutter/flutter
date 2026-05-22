// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SIZED_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SIZED_H_

#include <memory>

#include "host_window.h"
#include "shell/platform/windows/flutter_windows_view.h"

namespace flutter {

// Base class for HostWindowRegular and HostWindowDialog.
//
// Provides the shared sized-to-content implementation used by both archetypes:
// tracking the last rendered content size, calling SetContentSize() after each
// frame, and optionally disabling content-size tracking once the user resizes
// the window. HostWindowPopup and HostWindowTooltip are not derived from this
// class because they position themselves relative to a parent window rather
// than sizing to their own content.
class HostWindowSized : public HostWindow,
                        private FlutterWindowsViewSizingDelegate {
 protected:
  HostWindowSized(WindowManager* window_manager,
                  FlutterWindowsEngine* engine,
                  bool resizable);

  // Returns a pointer to this as a FlutterWindowsViewSizingDelegate, for use
  // as HostWindowInitializationParams::sizing_delegate. This is necessary
  // because FlutterWindowsViewSizingDelegate is a private base of this class
  // and the conversion is therefore inaccessible to derived classes.
  FlutterWindowsViewSizingDelegate* AsSizingDelegate() { return this; }

  // Whether the user can manually resize this window.
  const bool resizable_;

  // Used to track whether the view is still alive in tasks posted from the
  // raster thread.
  std::shared_ptr<int> view_alive_;

  // The last physical-pixel size reported to DidUpdateViewSize.
  int width_ = 0;
  int height_ = 0;

 private:
  // FlutterWindowsViewSizingDelegate:
  void DidUpdateViewSize(int32_t width, int32_t height) override;
  WindowRect GetWorkArea() const override;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SIZED_H_
