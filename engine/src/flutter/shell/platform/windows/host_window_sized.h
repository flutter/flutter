// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SIZED_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SIZED_H_

#include <memory>

#include "host_window.h"
#include "shell/platform/windows/flutter_windows_view.h"

namespace flutter {

// Base class for the sized-to-content archetypes: HostWindowRegular,
// HostWindowDialog, HostWindowPopup, and HostWindowTooltip.
//
// Provides the shared sized-to-content implementation used by these
// archetypes: tracking the last rendered content size and reacting to it after
// each frame. The default reaction resizes the window in place and optionally
// disables content-size tracking once the user resizes the window.
// HostWindowPopup and HostWindowTooltip override ApplyContentSize() to instead
// reposition themselves relative to a parent window whenever their content
// size changes.
class HostWindowSized : public HostWindow,
                        private FlutterWindowsViewSizingDelegate {
 protected:
  HostWindowSized(WindowManager* window_manager,
                  FlutterWindowsEngine* engine,
                  bool resizable);

  // Pure virtual to make HostWindowSized abstract: only the concrete
  // archetypes (HostWindowRegular, HostWindowDialog, HostWindowPopup,
  // HostWindowTooltip) may be instantiated.
  //
  // Each derived class must reset |view_controller_| at the very start of its
  // own destructor, while the most-derived object is still fully alive.
  //
  // When sized to content, this object is the view's
  // FlutterWindowsViewSizingDelegate, and the view (owned by
  // |view_controller_|, a member of the HostWindow base class) drives sizing
  // from the raster thread via DidUpdateViewSize -> ApplyContentSize /
  // GetWorkArea. Several of these entry points are overridden by derived
  // classes. If the view were destroyed by the HostWindow base destructor
  // instead, it would run *after* the derived destructor: by then the derived
  // subobject (and its vtable overrides) is gone, so an in-flight raster-thread
  // sizing call could land in a destroyed object and crash. Resetting
  // |view_controller_| in the derived destructor triggers
  // FlutterWindowsEngine::RemoveView, which guarantees the raster thread no
  // longer presents to (or sizes) this view before any subobject is torn down.
  //
  // The base destructor asserts that |view_controller_| has already been reset.
  ~HostWindowSized() override = 0;

  // Returns a pointer to this as a FlutterWindowsViewSizingDelegate, for use
  // as HostWindowInitializationParams::sizing_delegate. This is necessary
  // because FlutterWindowsViewSizingDelegate is a private base of this class
  // and the conversion is therefore inaccessible to derived classes.
  FlutterWindowsViewSizingDelegate* AsSizingDelegate() { return this; }

  // Called on the platform thread after the rendered content size has changed
  // to |physical_width| x |physical_height| (in physical pixels). The base
  // implementation resizes the window in place to fit the content and, for
  // resizable windows, stops tracking content size after the initial frame.
  // Subclasses that position themselves relative to a parent override this.
  virtual void ApplyContentSize(int32_t physical_width,
                                int32_t physical_height);

  // Whether the user can manually resize this window.
  const bool resizable_;

  // Used to track whether the view is still alive in tasks posted from the
  // raster thread.
  std::shared_ptr<int> view_alive_;

  // The last physical-pixel size reported to DidUpdateViewSize.
  int physical_width_ = 0;
  int physical_height_ = 0;

 private:
  // FlutterWindowsViewSizingDelegate:
  void DidUpdateViewSize(int32_t width, int32_t height) override;
  WindowRect GetWorkArea() const override;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_SIZED_H_
